import 'package:app/api/api.dart';
import 'package:app/provider/authentication_provider.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';
import 'package:app/navigation/provision_navigator.dart';

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
  Future<bool>? _checkAuthFuture;
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
          child: FutureBuilder<bool>(
              future: _checkAuthFuture,
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                if (snapshot.hasData ||
                    snapshot.hasError ||
                    snapshot.connectionState == ConnectionState.done) {
                  return SizedBox(
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
                            child: BasicFormContainer(
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
                                  validator: Validatorless.required(
                                      'Enter your password'),
                                  onFieldSubmitted: (value) =>
                                      (), //To trigger the form submit function
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        24, 12, 24, 40),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          _startOOBE();
                                        },
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          side: const BorderSide(
                                              width: 1,
                                              color: Color(0xff03012C)),
                                        ),
                                        child: Text(
                                          'Set up a new device',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color:
                                                      const Color(0xff03012C)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ));
                } else {
                  return SizedBox(
                      height: MediaQuery.of(context).size.height - topSize,
                      child: const Align(
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ));
                }
              })),
    );
  }

  Future<bool> _handleAuthSuccess(bool status) async {
    if (status) {
      Navigator.of(context).pushNamedAndRemoveUntil("/index", (route) => false);
    }
    return status;
  }

  bool _handleAuthFailure(Exception err) {
    setState(() {
      _checkAuthFuture = Future.error(err);
    });
    return false;
  }

  void _checkAuthStatus() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      try {
        var future = Provider.of<AuthenticationProvider>(context, listen: false)
            .checkAuthStatus()
            .then((value) => _handleAuthSuccess(value))
            .catchError((err) => _handleAuthFailure(err));

        setState(() {
          _checkAuthFuture = future;
        });
      } on Exception catch (e) {
        _handleAuthFailure(e);
      }
    });
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

    _loginFuture!.then((_) {
      Navigator.of(context).pushNamedAndRemoveUntil("/index", (route) => false);
    }).catchError((err) {
      if (err is ProblemJsonException) {
        _showErrorDialog('There was a problem signing you in: ${err.problem}');
      } else {
        _showErrorDialog(
            'There was a problem signing you in: ${err.toString()}');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    print("YOO");
    _checkAuthStatus();
  }
}
