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
import 'package:app/widgets/addNewPill/medication_card_entry.dart';
import 'package:app/widgets/medication_card.dart';
import 'package:app/widgets/notifications_settings.dart';
import 'package:app/widgets/schedule_entry.dart';
import 'package:app/widgets/wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';

import '../models/user.dart';
import '../widgets/basic_page.dart';

class PostSetupWizard extends StatelessWidget {
  const PostSetupWizard({super.key});

  @override
  Widget build(BuildContext context) {
    ProvisionningProgress provisionningProgress = ProvisionningProgress(3, 1);
    void onSkip() {
      var currentUser =
          Provider.of<AuthenticationProvider>(context, listen: false)
              .currentUser;
      if (currentUser is AnonymousUser) {
        Navigator.of(context).push(MedicationEntryStep.route(context));
      } else {
        Navigator.of(context)
            .pushNamedAndRemoveUntil("/index", (route) => false);
      }
    }

    return Consumer2<ScheduleProvider, DeviceProvider>(
      builder: (context, scheduleProvider, deviceProvider, child) {
        bool isUpdatingSchedule = scheduleProvider.isUpdatingSchedule;
        bool isUpdatingTimezone = deviceProvider.isUpdatingTimezone;

        bool canGoNext = !isUpdatingSchedule && !isUpdatingTimezone;

        return WizardStep(
            provisionningProgress: provisionningProgress,
            title: AppLocalizations.of(context)!.welcomeCabinet,
            subtext: AppLocalizations.of(context)!.postSetupSubtitle,
            onBackPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/name_new_device', (route) => false),
            onNextPressed: () =>
                Navigator.of(context).push(NotificationStep.route(context)),
            onSkipPressed: () =>
                Navigator.of(context).push(NotificationStep.route(context)),
            canGoNext: canGoNext,
            child: Expanded(
                child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      ScheduleEntry(
                        showRemovalSection: false,
                        showAddDeviceSection: false,
                        isOwner: true,
                      ),
                      SizedBox(height: 72),
                    ],
                  )),
            )));
      },
    );
  }
}

class NotificationStep extends StatelessWidget {
  const NotificationStep({super.key});

  static Route<NotificationStep> route(context) => platformPageRoute(
      context: context, builder: (_) => const NotificationStep());

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

class MedicationEntryStep extends StatefulWidget {
  const MedicationEntryStep({super.key});

  @override
  _MedicationEntryStepState createState() => _MedicationEntryStepState();

  static Route<MedicationEntryStep> route(context) => platformPageRoute(
      context: context, builder: (_) => const MedicationEntryStep());
}

class _MedicationEntryStepState extends State<MedicationEntryStep> {
  @override
  Widget build(BuildContext context) {
    ProvisionningProgress provisionningProgress = ProvisionningProgress(3, 3);
    void onNext() {
      var currentUser =
          Provider.of<AuthenticationProvider>(context, listen: false)
              .currentUser;
      if (currentUser is AnonymousUser) {
        Navigator.of(context).push(CreateAccountStep.route(context));
      } else {
        Navigator.of(context)
            .pushNamedAndRemoveUntil("/index", (route) => false);
      }
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
        child: Consumer<MedicationsProvider>(
          builder: (context, prov, _) {
            return Column(children: [
              GestureDetector(
                  onTap: () => _addNewPill(prov),
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
                    onTap: () => _showMyPills(prov),
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

  void _addNewPill(MedicationsProvider prov) {
    final device =
        Provider.of<SelectedDeviceProvider>(context, listen: false).device;
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
        builder: (context) => device == null
            ? ChangeNotifierProvider<NewMedicationProvider>(
                create: (context) => NewMedicationProvider(
                    device!.deviceID, () => prov.update(device)),
                builder: (context, _) => MedicationModal(
                    onBack: () => Navigator.of(context).pop(),
                    onNext: true,
                    child: const MedicationCardEntry()))
            : SingleChildScrollView(
                child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.h, horizontal: 32.w),
                    child: SizedBox(
                        height: 200.h,
                        width: 200.w,
                        child: Center(
                            child: Text(AppLocalizations.of(context)!
                                .addPillsError)))))).whenComplete(() {
      prov.refresh();
    });
  }

  void _showMyPills(MedicationsProvider prov) {
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
        builder: (context) => ValueListenableBuilder(
            valueListenable: prov,
            builder: (context, indicatorEnabled, child) => SizedBox(
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
                      )),
                ]))));
  }
}

class CreateAccountStep extends StatefulWidget {
  const CreateAccountStep({super.key});

  static Route<CreateAccountStep> route(context) => platformPageRoute(
      context: context, builder: (_) => const CreateAccountStep());

  @override
  State<CreateAccountStep> createState() => _CreateAccountStepState();
}

class _CreateAccountStepState extends State<CreateAccountStep> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    ProvisionningProgress provisionningProgress = ProvisionningProgress(3, 1);
    return ChangeNotifierProvider<UserRegistrationProvider>(
        create: (_) => UserRegistrationProvider(),
        builder: (context, up) {
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
                  future: Provider.of<UserRegistrationProvider>(context).future,
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
                        context
                            .read<UserRegistrationProvider>()
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
                        context
                            .read<UserRegistrationProvider>()
                            .updatePassword(val);
                      },
                      onFieldSubmitted: (val) {
                        context
                            .read<UserRegistrationProvider>()
                            .updatePassword(val);
                      },
                    ),
                  ],
                ),
              ));
        });
  }

  void _submit(context) {
    var prov = Provider.of<UserRegistrationProvider>(context, listen: false);
    var authProv = Provider.of<AuthenticationProvider>(context, listen: false);
    _register(prov, authProv).catchError((err) {
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
  }

  Future<bool> _register(
      UserRegistrationProvider prov, AuthenticationProvider authProv) async {
    await prov.register();
    await authProv.logIn(
        username: prov.model.email, password: prov.model.password);
    return true;
  }
}
