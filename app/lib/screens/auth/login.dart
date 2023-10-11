import 'package:app/api/api.dart';
import 'package:app/provider/authentication_provider.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  Future<void>? _loginFuture;
  String? username;
  String? password;
  bool useAnon = false;

  @override
  Widget build(BuildContext context) {
    const navFooterHeight = 72.0;
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Form(
            key: _formKey,
            child: Stack(children: [
              CustomScrollView(slivers: [
                SliverAppBar(
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: const Color(0xFFFBFCFF),
                  leading: null,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                    child: SizedBox(
                        height: 690,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 36),
                            child: Column(children: [
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Sign In',
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                    textAlign: TextAlign.left,
                                  )),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 22, right: 0),
                                    child: Text(
                                      'Sign In to your account for better experience.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  )),
                              const SizedBox(
                                height: 24,
                              ),
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
                                onFieldSubmitted: (value) => _onSubmit(),
                                onSaved: (val) => password = val,
                                textInputAction: TextInputAction.done,
                                obscureText: true,
                              ),
                            ])))),
              ]),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: navFooterHeight,
                    color: const Color(0xFFFBFCFF),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: SizedBox(
                              height: navFooterHeight,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.arrow_back,
                                    size: 24,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Text('Back',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                              width: double.infinity,
                              height: navFooterHeight,
                              child: FutureBuilder(
                                  future: _loginFuture,
                                  builder: (context, snapshot) {
                                    return GestureDetector(
                                      onTap: _onPressed(snapshot),
                                      child: Container(
                                        height: navFooterHeight,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(32),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('Sign In',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                        color: Colors.white)),
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            const Icon(
                                              Icons.arrow_forward,
                                              size: 24,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  })),
                        ),
                      ],
                    ),
                  )),
            ])));
  }

  VoidCallback? _onPressed(AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return null;
    } else {
      return () => _onSubmit();
    }
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

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      _submitForm();
    }
    ;
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
