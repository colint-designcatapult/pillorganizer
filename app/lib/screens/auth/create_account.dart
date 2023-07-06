
import 'package:app/api/api.dart';
import 'package:app/api/user.dart';
import 'package:app/platform/dialog.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';

import '../../api/auth.dart';

class CreateAccountPage extends StatelessWidget {
  const CreateAccountPage({Key? key}) : super(key: key);

  static Route<CreateAccountPage> route(context) {
    return platformPageRoute(context: context, builder:
        (_) => const CreateAccountPage());
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserRegistrationProvider>(
        create: (_) => UserRegistrationProvider(),
        child: BasicPage(
          title: const Text('Create CabiNET Account'),
          child: Builder(
              builder: (context) {
                return BasicForm(
                  buttonText: 'Continue',
                  onSubmit: () => _submit(context),
                  future: Provider.of<UserRegistrationProvider>(context).future,
                  children: [
                    BasicPageTextFormField(
                      labelText: 'Email',
                      validator: Validatorless.multiple([
                        Validatorless.email('Not a valid email'),
                        Validatorless.required('Enter an email')
                      ]),
                      autofocus: true,
                      onSaved: (val) {
                        context.read<UserRegistrationProvider>()
                          .updateEmail(val);
                      },
                    ),
                    BasicPageTextFormField(
                      labelText: 'Password',
                      validator: Validatorless.multiple([
                        Validatorless.between(6, 48, "Passwords must be between 6 and 32 characters")
                      ]),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSaved: (val) {
                        context.read<UserRegistrationProvider>()
                          .updatePassword(val);
                      },
                      onFieldSubmitted: (val) {
                        context.read<UserRegistrationProvider>()
                            .updatePassword(val);
                      },
                    )
                  ],
                );
              }
          ),
        )
    );
  }

  void _submit(context) {
    var prov = Provider.of<UserRegistrationProvider>(context, listen: false);
    var authProv = Provider.of<AuthenticationProvider>(context, listen: false);
    _register(prov, authProv)
      .catchError((err) {
        _handleError(context, err);
        return false;
      })
      .then((value) {
        if(value) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pop(context);
          });
        }
      });
  }

  Future<bool> _register(UserRegistrationProvider prov, AuthenticationProvider authProv) async {
    await prov.register();
    await authProv.logIn(username: prov.model.email, password: prov.model.password);
    return true;
  }
  
  void _handleError(context, err) {
    debugPrint(err.toString());
    if(err is ProblemJsonException) {
      showAlertDialog(context, 'There was a problem: ${err.problem}');
    } else {
      showAlertDialog(context, 'There was a problem: ${err.toString()}');
    }
  }

}

