import 'package:app/api/api.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';

import '../../provider/auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Future<void>? _loginFuture;
  String? username;
  String? password;
  bool useAnon = false;

  @override
  Widget build(BuildContext context) {
    return BasicPage(
        title: const Text('Sign in to CabiNET'),
        bgColor: const Color(0xFFBFD2DB),
        child: Padding(
            padding: const EdgeInsets.only(top: 35),
            child: BasicForm(
              titleText: 'Sign In',
              subtitleText: 'Sign In to your account for better experience.',
              buttonText: 'Continue',
              onSubmit: _submitForm,
              future: _loginFuture,
              children: [
                BasicPageTextFormField(
                  labelText: 'Email',
                  validator: Validatorless.multiple([
                    if (!useAnon) Validatorless.email('Not a valid email'),
                    Validatorless.required('Enter an email')
                  ]),
                  autofocus: true,
                  onSaved: (val) => username = val,
                ),
                BasicPageTextFormField(
                  labelText: 'Password',
                  validator: Validatorless.required('Enter your password'),
                  onFieldSubmitted: (value) => _submitForm(),
                  onSaved: (val) => password = val,
                  textInputAction: TextInputAction.done,
                  obscureText: true,
                ),
              ],
            )));
  }

  void _showErrorDialog(String message) {
    showPlatformDialog(
        context: context,
        builder: (context) {
          return PlatformAlertDialog(
              content: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              actions: [
                PlatformDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ]);
        });
  }

  void _submitForm() {
    var prov = Provider.of<AuthenticationProvider>(context, listen: false);

    if (!useAnon) {
      _loginFuture =
          prov.logIn(username: username ?? '', password: password ?? '');
    } else {
      _loginFuture =
          prov.logInAnonymous(id: int.parse(username!), secret: password!);
    }

    setState(() {
      _loginFuture!
          .then((_) => Navigator.of(context).pop(true))
          .catchError((err) {
        if (err is ProblemJsonException) {
          _showErrorDialog(
              'There was a problem signing you in: ${err.problem}');
        } else {
          _showErrorDialog(
              'There was a problem signing you in: ${err.toString()}');
        }
      });
    });
  }
}
