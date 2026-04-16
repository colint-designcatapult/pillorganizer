import 'package:app/provider/authentication_provider.dart';
import 'package:app/provider/device_provider.dart';
import 'package:app/provider/medication_provider.dart';
import 'package:app/provider/new_medication_provider.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/provider/user_registration_provider.dart';
import 'package:app/screens/modals/add_new_pills_modal.dart';
import 'package:app/service/error_handler.dart';
import 'package:app/service/provisioning_service.dart';
import 'package:app/apiv2/models/schedule.dart';
import 'package:app/widgets/addNewPill/medication_card_entry.dart';
import 'package:app/widgets/medication_card.dart';
import 'package:app/widgets/notifications_settings.dart';
import 'package:app/widgets/schedule_entry.dart';
import 'package:app/widgets/wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:validatorless/validatorless.dart';

import '../widgets/basic_page.dart';

class PostSetupWizard extends ConsumerStatefulWidget {
  final String? deviceId;

  const PostSetupWizard({super.key, this.deviceId});

  @override
  ConsumerState<PostSetupWizard> createState() => _PostSetupWizardState();
}

class _PostSetupWizardState extends ConsumerState<PostSetupWizard> {
  bool _deviceSelected = false;

  @override
  void initState() {
    super.initState();
    if (widget.deviceId != null) {
      // Select device immediately in initState, then rebuild
      Future.microtask(() => _selectAndLoadDevice());
    }
  }

  Future<void> _selectAndLoadDevice() async {
    if (widget.deviceId == null) return;
    if (_deviceSelected) return;
    
    try {
      await ref.read(activeDeviceProvider.notifier).selectDeviceByID(widget.deviceId!);
      if (mounted) {
        setState(() {
          _deviceSelected = true;
        });
      }
    } catch (e) {
      // Device selection failed, log but allow proceeding
      print('[PostSetup] Device selection failed: $e');
      if (mounted) {
        setState(() {
          _deviceSelected = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we have a deviceId to select and haven't selected it yet, show loading
    if (widget.deviceId != null && !_deviceSelected) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    ProvisionningProgress provisionningProgress = ProvisionningProgress(3, 1);

    final schedule = ref.watch(scheduleProvider);

    // Next is enabled once the user has saved a schedule with both AM and PM set.
    final scheduleState = schedule.asData?.value;
    final effective = scheduleState?.effectiveSchedule;
    final simple = effective is SimpleSchedule ? effective : null;
    bool canGoNext = simple?.amPeriod != null &&
        simple?.pmPeriod != null &&
        scheduleState?.effectiveTimezoneIana != null;
    
    return WizardStep(
        provisionningProgress: provisionningProgress,
        title: AppLocalizations.of(context)!.welcomeCabinet,
        subtext: AppLocalizations.of(context)!.postSetupSubtitle,
        onBackPressed: () => Navigator.of(context)
            .pushNamedAndRemoveUntil('/name_new_device', (route) => false),
        onNextPressed: canGoNext ? () =>
            Navigator.of(context).push(NotificationStep.route(context)) : null,
        onSkipPressed: null,
        canGoNext: canGoNext,
        child: const Expanded(
            child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const ScheduleEntry(
                    showRemovalSection: false,
                    showAddDeviceSection: false,
                    ignoreOffline: true,
                  ),
                  SizedBox(height: 72),
                ],
              )),
        )));
  }
}

class NotificationStep extends StatelessWidget {
  const NotificationStep({super.key});

  static Route<NotificationStep> route(context) => MaterialPageRoute(
      builder: (_) => const NotificationStep());

  @override
  Widget build(BuildContext context) {
    ProvisionningProgress provisionningProgress = ProvisionningProgress(3, 2);

    return WizardStep(
        provisionningProgress: provisionningProgress,
        title: AppLocalizations.of(context)!.reminders,
        subtext: AppLocalizations.of(context)!.remindersSubtitle,
        onBackPressed: () => Navigator.of(context).pop(),
        onNextPressed: () =>
            Navigator.of(context).push(MedicationEntryStep.route(context)),
        canGoNext: true,
        height: 550.h,
        child: Expanded(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: NotificationsSettings()))));
  }
}

class MedicationEntryStep extends ConsumerStatefulWidget {
  const MedicationEntryStep({super.key});

  @override
  ConsumerState<MedicationEntryStep> createState() => _MedicationEntryStepState();

  static Route<MedicationEntryStep> route(context) => MaterialPageRoute(
      builder: (_) => const MedicationEntryStep());
}

class _MedicationEntryStepState extends ConsumerState<MedicationEntryStep> {
  @override
  Widget build(BuildContext context) {
    ProvisionningProgress provisionningProgress = ProvisionningProgress(3, 3);
    void onNext() {
      ref.read(medicationsProvider.notifier).refresh();

      Navigator.of(context).pushNamedAndRemoveUntil("/index", (route) => false);
    }

    return WizardStep(
      provisionningProgress: provisionningProgress,
      title: AppLocalizations.of(context)!.addMedications,
      subtext: AppLocalizations.of(context)!.addMedicationsSubtitle,
      onBackPressed: () => Navigator.of(context).pop(),
      onNextPressed: onNext,
      onSkipPressed: onNext,
      canGoNext: true,
      child: Padding(
        padding: const EdgeInsets.only(left: 32.0, right: 32.0, bottom: 32.0),
        child: Builder(
          builder: (context) {
            final prov = ref.watch(medicationsProvider);
            return Column(children: [
              GestureDetector(
                  onTap: () => _addNewPill(ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 18),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).primaryColor,
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 24.h),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.addPillManually,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(color: Colors.white),
                          )
                        ]),
                  )),
              const SizedBox(
                height: 16,
              ),
              if (prov.value?.isNotEmpty ?? false)
                GestureDetector(
                    onTap: () => _showMyPills(ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 18),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF206B8B), width: 1),
                        color: Colors.white,
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset('lib/assets/SVG/Pill.svg',
                                colorFilter: const ColorFilter.mode(
                                    Color(0xFF206B8B), BlendMode.srcIn)),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.myPills,
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(color: const Color(0xFF206B8B)),
                            )
                          ]),
                    )),
            ]);
          },
        ),
      ),
    );
  }

  void _addNewPill(WidgetRef ref) {
    final device = ref.read(activeDeviceProvider);
    if (device == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.addPillsError))
      );
      return;
    }

    ref.read(newMedicationProvider.notifier).initialize(
          device.id,
          onComplete: () => ref.read(medicationsProvider.notifier).refresh(),
        );

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFFFBFCFF),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width,
        ),
        builder: (context) => MedicationModal(
            onBack: () => Navigator.of(context).pop(),
            onNext: true,
            onComplete: () => ref.read(medicationsProvider.notifier).refresh(),
            child: const MedicationCardEntry())).whenComplete(() {
      ref.read(medicationsProvider.notifier).refresh();
    });
  }

  void _showMyPills(WidgetRef ref) {
    double navFootBarHeight = 72;
    showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width,
        ),
        builder: (context) {
          final prov = ref.watch(medicationsProvider);
          final activeDevice = ref.watch(activeDeviceProvider);
          return SizedBox(
                height: MediaQuery.of(context).size.height * 0.9,
                child: Stack(children: [
                  Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 32,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                        Text(AppLocalizations.of(context)!.myPills,
                            style: Theme.of(context).textTheme.titleMedium),
                        Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                            child: Text(
                                AppLocalizations.of(context)!.pillsOverview,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium)),
                        Expanded(
                            child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      ...prov.value!
                                          .map((e) => MedicationCard(
                                                med: e,
                                                backgroundColor:
                                                    const Color(0xFFF1F3F6),
                                              ))
                                          .toList(growable: false)
                                    ]))),
                        SizedBox(
                          height: navFootBarHeight,
                        ),
                        AddNewPillModal(
                            deviceID: activeDevice!.id,
                            onComplete: () => ref.read(medicationsProvider.notifier).refresh(),
                        )
                      ])),
                  Align(
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: navFootBarHeight,
                          color: const Color(0xFF206B8B),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.arrow_back,
                                      size: 24,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Text(AppLocalizations.of(context)!.back,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(color: Colors.white)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                );
        });
  }
}

class CreateAccountStep extends ConsumerStatefulWidget {
  const CreateAccountStep({super.key});

  static Route<CreateAccountStep> route(context) => MaterialPageRoute(
      builder: (_) => const CreateAccountStep());

  @override
  ConsumerState<CreateAccountStep> createState() => _CreateAccountStepState();
}

class _CreateAccountStepState extends ConsumerState<CreateAccountStep> {
  bool _obscureText = true;
  Future<void>? _registerFuture;

  @override
  Widget build(BuildContext context) {
    ProvisionningProgress provisionningProgress = ProvisionningProgress(3, 1);
    return WizardStep(
        height: 550,
        icon: SvgPicture.asset('lib/assets/SVG/User.svg'),
        subtext: AppLocalizations.of(context)!.createAccountSubtitle,
        provisionningProgress: provisionningProgress,
        onBackPressed: () => Navigator.of(context).pop(),
        canGoNext: false,
        onSkipPressed: () => Navigator.of(context)
            .pushNamedAndRemoveUntil('/index', (route) => false),
        canScroll: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: BasicForm(
            onSubmit: () => _submit(context),
            future: _registerFuture,
            buttonText: AppLocalizations.of(context)!.createAccount,
            children: [
              BasicPageTextFormField(
                labelText: AppLocalizations.of(context)!.email,
                validator: Validatorless.multiple([
                  (value) {
                    return Validatorless.email(
                            AppLocalizations.of(context)!.emailNotValid)(
                        value?.toLowerCase());
                  },
                  Validatorless.required(
                      AppLocalizations.of(context)!.emailRequired)
                ]),
                onSaved: (val) {
                  ref
                      .read(userRegistrationProvider.notifier)
                      .updateEmail(val?.toLowerCase());
                },
              ),
              BasicPageTextFormField(
                labelText: AppLocalizations.of(context)!.password,
                validator: Validatorless.multiple([
                  Validatorless.between(
                      6,
                      48,
                      AppLocalizations.of(context)!
                          .passwordLengthValidation)
                ]),
                onRevealText: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                obscureText: _obscureText,
                textInputAction: TextInputAction.done,
                onSaved: (val) {
                  ref
                      .read(userRegistrationProvider.notifier)
                      .updatePassword(val);
                },
                onFieldSubmitted: (val) {
                  ref
                      .read(userRegistrationProvider.notifier)
                      .updatePassword(val);
                },
              ),
            ],
          ),
        ));
  }

  void _submit(context) {
    var prov = ref.read(userRegistrationProvider.notifier);
    var authProv = ref.read(authenticationProvider.notifier);

    setState(() {
      _registerFuture = _register(prov, authProv).catchError((err) {
        registerHandleError(context, err);
        return false;
      }).then((value) {
        if (value) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/index', (route) => false);
          });
        }
      });
    });
  }

  Future<bool> _register(
      UserRegistrationNotifier prov, Authentication authProv) async {
    await prov.register();
    await authProv.logIn(
        username: ref.read(userRegistrationProvider).email, password: ref.read(userRegistrationProvider).password);
    return true;
  }
}
