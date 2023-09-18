import 'package:app/api/medication.dart';
import 'package:app/widgets/medication_icon.dart';
import 'package:app/widgets/schedule_entry.dart';
import 'package:app/widgets/wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';

import '../api/api.dart';
import '../api/auth.dart';
import '../api/device.dart';
import '../api/user.dart';
import '../platform/dialog.dart';
import '../widgets/basic_page.dart';
import 'device_settings/medication/medication_entry_wizard.dart';

class PostSetupWizard extends StatelessWidget {
  const PostSetupWizard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WizardStep(
        fullscreen: true,
        stepTitle: 'Preferences',
        stepNumber: '2',
        title: 'Welcome to CabiNET!',
        subtext: 'Complete these final steps to set up your pill organizer.',
        footer: ElevatedButton(
            onPressed: () {
              Navigator.of(context)
                  .pushReplacement(MedicationEntryStep.route(context));
            },
            child: const Text('Continue')),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(child: ScheduleEntry()),
        ),
      ),
    );
  }
}

class MedicationEntryStep extends StatelessWidget {
  const MedicationEntryStep({super.key});

  static Route<MedicationEntryStep> route(context) => platformPageRoute(
      context: context, builder: (_) => const MedicationEntryStep());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WizardStep(
        fullscreen: true,
        stepTitle: 'Preferences',
        stepNumber: '2',
        title: 'Add Medications',
        subtext:
            'Enter in the medications you take so your pill organizer can remind you.',
        footer: ElevatedButton(
            onPressed: () {
              var currentUser =
                  Provider.of<AuthenticationProvider>(context, listen: false)
                      .currentUser;
              if (currentUser is AnonymousUser) {
                Navigator.of(context)
                    .pushReplacement(CreateAccountStep.route(context));
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Continue')),
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
                                  .deviceID))
                          .then((value) {
                        Provider.of<MedicationsProvider>(context, listen: false)
                            .refresh();
                      });
                    })
              ]);
            },
          ),
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
    return ChangeNotifierProvider<UserRegistrationProvider>(
        create: (_) => UserRegistrationProvider(),
        builder: (context, up) {
          return Scaffold(
            body: WizardStep(
              fullscreen: true,
              stepTitle: 'Create an account',
              stepNumber: '3',
              title: 'Create Account',
              subtext:
                  'Create a CabiNET account to unlock additional features.',
              child: Padding(
                  padding: const EdgeInsets.only(
                      left: 32.0, right: 32.0, bottom: 32.0),
                  child: Column(
                    children: [
                      BasicForm(
                        onSubmit: () => _submit(context),
                        future: Provider.of<UserRegistrationProvider>(context)
                            .future,
                        children: [
                          BasicPageTextFormField(
                            labelText: 'Email',
                            validator: Validatorless.multiple([
                              Validatorless.email('Not a valid email'),
                              Validatorless.required('Enter an email')
                            ]),
                            autofocus: true,
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
                          )
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Skip'),
                      )
                    ],
                  )),
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
