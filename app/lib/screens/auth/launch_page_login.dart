import 'package:app/api/api.dart';
import 'package:app/provider/authentication_provider.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';
import '../index.dart';
import '../provision.dart';

class LaunchPageLogin extends StatefulWidget {
  const LaunchPageLogin({Key? key}) : super(key: key);

  static Route<LaunchPageLogin> route(context) {
    return platformPageRoute(
        context: context,
        builder: (_) {
          return const LaunchPageLogin();
        });
  }

  @override
  State<LaunchPageLogin> createState() => _LaunchPageLoginState();
}

class _LaunchPageLoginState extends State<LaunchPageLogin> {
  Future<void>? _loginFuture;
  String? username;
  String? password;
  bool useAnon = false;

  @override
  Widget build(BuildContext context) {
    var topSize = MediaQuery.of(context).viewPadding.top + 55;

    return Scaffold(
      backgroundColor: const Color(0xFFBFD2DB),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: topSize),
        child: SizedBox(
            height: MediaQuery.of(context).size.height - topSize,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'CabiNET',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: BasicForm(
                    titleText: 'Sign In',
                    subtitleText:
                        'Welcome back! Please Sign In to your account.',
                    buttonText: 'Sign In',
                    onSubmit: _submitForm,
                    future: _loginFuture,
                    children: [
                      BasicPageTextFormField(
                        labelText: 'Email',
                        validator: Validatorless.multiple([
                          if (!useAnon)
                            Validatorless.email('Not a valid email'),
                          Validatorless.required('Enter an email')
                        ]),
                        onSaved: (val) => username = val,
                      ),
                      BasicPageTextFormField(
                        labelText: 'Password',
                        validator:
                            Validatorless.required('Enter your password'),
                        onFieldSubmitted: (value) => _submitForm(),
                        onSaved: (val) => password = val,
                        textInputAction: TextInputAction.done,
                        obscureText: true,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            "or",
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                _startOOBE();
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                side: const BorderSide(
                                    width: 1, color: Color(0xff03012C)),
                              ),
                              child: Text(
                                'Set up a new device',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: const Color(0xff03012C)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }

  void _startOOBE() {
    startProvisioning(context);
  }

  void _showErrorDialog(String message) {
    showPlatformDialog(
        context: context,
        builder: (context) {
          return PlatformAlertDialog(
              content: Text(
                message,
                style: Theme.of(context).textTheme.labelLarge,
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
      _loginFuture!.then((_) {
        Navigator.of(context).pushReplacement(IndexPage.route(context));
      }).catchError((err) {
        if (err is ProblemJsonException) {
          _showErrorDialog(
              'There was a problem signing you in: ${err.problem}');
        } else {
          _showErrorDialog(
              'There was a problem signing you in: ${err.toString()}');
        }
        return null;
      });
    });
  }
}
