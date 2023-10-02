import 'package:app/api/medication.dart';
import 'package:app/provider/authentication_provider.dart';
import 'package:app/provider/medication_provider.dart';
import 'package:app/provider/schedule_provider.dart';
import 'package:app/provider/selected_device_provider.dart';
import 'package:app/provider/user_registration_provider.dart';
import 'package:app/service/provisioning_service.dart';
import 'package:app/widgets/medication_icon.dart';
import 'package:app/widgets/schedule_entry.dart';
import 'package:app/widgets/wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';

import '../api/api.dart';
import '../models/user.dart';
import '../platform/dialog.dart';
import '../widgets/basic_page.dart';
import 'device_settings/medication/medication_entry_wizard.dart';

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
              padding: EdgeInsets.all(16.0),
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
        bool canGoNext = selectedDeviceProvider.isUpdatedNotificationCalled;

        void toggleNotifications() {
          var sdp = Provider.of<SelectedDeviceProvider>(context, listen: false);
          sdp.updateNotifications(!(sdp.device?.notifications ?? false));
        }

        return WizardStep(
            provisionningProgress: provisionningProgress,
            title: 'Reminders',
            subtext:
                'Set up reminders to ensure you stay on track with your medication schedule.',
            onBackPressed: () => Navigator.of(context).pop(),
            onNextPressed: () =>
                Navigator.of(context).push(MedicationEntryStep.route(context)),
            onSkipPressed: () =>
                Navigator.of(context).push(CreateAccountStep.route(context)),
            canGoNext: canGoNext,
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
                                          .titleSmall,
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
  bool canGoNext = false;

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
        Navigator.of(context).pop();
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
      canGoNext: canGoNext,
      child: Padding(
        padding: const EdgeInsets.only(left: 32.0, right: 32.0, bottom: 32.0),
        child: Consumer<MedicationsProvider>(
          builder: (context, prov, _) {
            return Column(mainAxisSize: MainAxisSize.max, children: [
              if ((prov.value?.isNotEmpty ?? false)) ...[
                ...prov.value!
                    .map((e) => _buildMedCard(context, e))
                    .toList(growable: false),
              ] else ...[
                const Text('You don\'t have any medications entered yet.')
              ],
              TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Medication'),
                  onPressed: () {
                    Navigator.of(context)
                        .push(NewMedicationWizardPage.route(
                            context,
                            Provider.of<SelectedDeviceProvider>(context,
                                    listen: false)
                                .device!
                                .deviceID,
                            onComplete: () => setState(() {
                                  canGoNext = true;
                                })))
                        .then((value) {
                      Provider.of<MedicationsProvider>(context, listen: false)
                          .refresh();
                    });
                  })
            ]);
          },
        ),
      ),
    );
  }

  Widget _buildMedCard(context, ScheduledMedication med) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: MedicationIcon.fromMed(med, 32.0),
        title: Text(med.name),
        onTap: () {
          Navigator.of(context)
              .push(EditMedicationWizardPage.route(
                  context,
                  med,
                  Provider.of<SelectedDeviceProvider>(context, listen: false)
                      .device!
                      .deviceID))
              .then((value) {
            Provider.of<MedicationsProvider>(context, listen: false).refresh();
          });
        },
      ),
    );
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
            title: 'Create Account',
            subtext: 'Create a CabiNET account to unlock additional features.',
            provisionningProgress: provisionningProgress,
            onBackPressed: () => Navigator.of(context).pop(),
            canGoNext: false,
            onSkipPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/index', (route) => false),
            child: BasicForm(
              onSubmit: () => _submit(context),
              future: Provider.of<UserRegistrationProvider>(context).future,
              children: [
                BasicPageTextFormField(
                  labelText: 'Email',
                  validator: Validatorless.multiple([
                    Validatorless.email('Not a valid email'),
                    Validatorless.required('Enter an email')
                  ]),
                  onSaved: (val) {
                    context.read<UserRegistrationProvider>().updateEmail(val);
                  },
                ),
                BasicPageTextFormField(
                  labelText: 'Password',
                  validator: Validatorless.multiple([
                    Validatorless.between(
                        6, 48, "Passwords must be between 6 and 32 characters")
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
          );
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
          Navigator.pop(context);
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
