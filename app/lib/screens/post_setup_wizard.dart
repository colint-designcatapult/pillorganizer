import 'package:app/provider/authentication_provider.dart';
import 'package:app/provider/medication_provider.dart';
import 'package:app/provider/new_medication_provider.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/provider/user_registration_provider.dart';
import 'package:app/screens/modals/add_new_pills_modal.dart';
import 'package:app/service/provisioning_service.dart';
import 'package:app/widgets/addNewPill/new_medications.dart';
import 'package:app/widgets/medication_card.dart';
import 'package:app/widgets/schedule_entry.dart';
import 'package:app/widgets/wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';

import '../api/api.dart';
import '../models/user.dart';
import '../platform/dialog.dart';
import '../widgets/basic_page.dart';

class PostSetupWizard extends StatelessWidget {
  const PostSetupWizard({super.key});

  @override
  Widget build(BuildContext context) {
    ProvisionningProgress provisionningProgress = ProvisionningProgress(2, 1);
    return Consumer2<ScheduleProvider, SelectedDeviceProvider>(
      builder: (context, scheduleProvider, selectedDeviceProvider, child) {
        bool isUpdatedTimeCalled = scheduleProvider.isUpdatedTimeCalled;
        bool isUpdatedTimeZoneCalled =
            selectedDeviceProvider.isUpdatedTimeZoneCalled;

        bool canGoNext = isUpdatedTimeCalled || isUpdatedTimeZoneCalled;

        return WizardStep(
            provisionningProgress: provisionningProgress,
            title: 'Welcome to CabiNET!',
            subtext:
                'Complete these final steps to set up your pill organizer.',
            onBackPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false),
            onNextPressed: () =>
                Navigator.of(context).push(NotificationStep.route(context)),
            onSkipPressed: () =>
                Navigator.of(context).push(CreateAccountStep.route(context)),
            canGoNext: canGoNext,
            child: const Expanded(
                child: Padding(
              padding: EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: ScheduleEntry()),
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
    ProvisionningProgress provisionningProgress = ProvisionningProgress(2, 2);
    return Consumer<SelectedDeviceProvider>(
      builder: (context, selectedDeviceProvider, child) {
        void toggleNotifications() {
          selectedDeviceProvider.updateNotifications(
              !(selectedDeviceProvider.device?.notifications ?? false));
        }

        return WizardStep(
            provisionningProgress: provisionningProgress,
            title: 'Reminders',
            subtext:
                'Set up reminders to ensure you stay on track with your medication schedule.',
            onBackPressed: () => Navigator.of(context).pop(),
            onNextPressed: () =>
                Navigator.of(context).push(MedicationEntryStep.route(context)),
            canGoNext: true,
            height: 550,
            child: Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Notification preferences:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 26),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Switch(
                                    value: Provider.of<SelectedDeviceProvider>(
                                                context)
                                            .device
                                            ?.notifications ??
                                        false,
                                    onChanged: (bool value) {
                                      toggleNotifications();
                                    },
                                    activeTrackColor: const Color(0xff708F72),
                                    thumbIcon: MaterialStateProperty
                                        .resolveWith<Icon?>(
                                      (Set<MaterialState> states) {
                                        if (states
                                            .contains(MaterialState.selected)) {
                                          return const Icon(Icons.check,
                                              color: Color(0xff708F72));
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Flexible(
                                    child: Text(
                                      'Send reminder notifications to your phone',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ])))));
      },
    );
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
    ProvisionningProgress provisionningProgress = ProvisionningProgress(2, 3);
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
      title: 'Add Medications',
      subtext:
          'Enter in the medications you take so your pill organizer can remind you.',
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
                          const Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Add Pill Manually",
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
                              "My Pills",
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
    final newMedicationProvider =
        NewMedicationProvider(device!.deviceID, () => prov.update(device));
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
        builder: (context) => NewMedicationModal(
            newMedicationProvider: newMedicationProvider,
            onBack: () => Navigator.of(context).pop(),
            onNext: true,
            child: const NewMedications())).whenComplete(() {
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
        builder: (context) => SizedBox(
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
                    Text('My pills',
                        style: Theme.of(context).textTheme.titleMedium),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        child: Text(
                            "Here's a quick overview of all the pills you've added.",
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
                                Text('Back',
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
            ])));
  }
}

class CreateAccountStep extends StatelessWidget {
  const CreateAccountStep({super.key});

  static Route<CreateAccountStep> route(context) => platformPageRoute(
      context: context, builder: (_) => const CreateAccountStep());

  @override
  Widget build(BuildContext context) {
    ProvisionningProgress provisionningProgress = ProvisionningProgress(3, 1);
    return ChangeNotifierProvider<UserRegistrationProvider>(
        create: (_) => UserRegistrationProvider(),
        builder: (context, up) {
          return WizardStep(
              height: 550,
              icon: SvgPicture.asset('lib/assets/SVG/User.svg'),
              subtext:
                  'Create an account in order to access your data anytime, anywhere.',
              provisionningProgress: provisionningProgress,
              onBackPressed: () => Navigator.of(context).pop(),
              canGoNext: false,
              onSkipPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil('/index', (route) => false),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: BasicForm(
                  onSubmit: () => _submit(context),
                  future: Provider.of<UserRegistrationProvider>(context).future,
                  buttonText: 'Create account',
                  children: [
                    BasicPageTextFormField(
                      labelText: 'Email',
                      validator: Validatorless.multiple([
                        Validatorless.email('Not a valid email'),
                        Validatorless.required('Enter an email')
                      ]),
                      onSaved: (val) {
                        context
                            .read<UserRegistrationProvider>()
                            .updateEmail(val);
                      },
                    ),
                    BasicPageTextFormField(
                      labelText: 'Password',
                      validator: Validatorless.multiple([
                        Validatorless.between(6, 48,
                            "Passwords must be between 6 and 32 characters")
                      ]),
                      obscureText: true,
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
      _handleError(context, err);
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

  void _handleError(context, err) {
    debugPrint(err.toString());
    if (err is ProblemJsonException) {
      showAlertDialog(context, 'There was a problem: ${err.problem}');
    } else {
      showAlertDialog(context, 'There was a problem: ${err.toString()}');
    }
  }
}
