import 'package:app/provider/authentication_provider.dart';
import 'package:app/service/error_handler.dart';
import 'package:app/screens/auth/recover_password.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';
import 'package:app/navigation/provision_navigator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  bool _obscureText = true;

  void forgotPassword() {
    showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16.r),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width,
        ),
        builder: (context) =>
            RecoverPassword(onBack: () => {Navigator.of(context).pop()}));
  }

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
                            AppLocalizations.of(context)!.appName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 36),
                            child: BasicFormContainer(
                              titleText:
                                  AppLocalizations.of(context)!.signInPrompt,
                              subtitleText: AppLocalizations.of(context)!
                                  .signInBackSubtitle,
                              buttonText:
                                  AppLocalizations.of(context)!.signInAction,
                              onSubmit: _submitForm,
                              future: _loginFuture,
                              children: [
                                BasicPageTextFormField(
                                  labelText:
                                      AppLocalizations.of(context)!.email,
                                  validator: Validatorless.multiple([
                                    Validatorless.email(
                                        AppLocalizations.of(context)!
                                            .emailNotValid),
                                    Validatorless.required(
                                        AppLocalizations.of(context)!
                                            .emailRequired)
                                  ]),
                                  onSaved: (val) => username = val,
                                ),
                                BasicPageTextFormField(
                                  labelText:
                                      AppLocalizations.of(context)!.password,
                                  validator: Validatorless.required(
                                      AppLocalizations.of(context)!
                                          .passwordRequired),
                                  onFieldSubmitted: (value) =>
                                      (), //To trigger the form submit function
                                  onSaved: (val) => password = val,
                                  textInputAction: TextInputAction.done,
                                  onRevealText: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                  obscureText: _obscureText,
                                  paddingBottom: 12,
                                ),
                                Align(
                                    alignment: Alignment.topRight,
                                    child: GestureDetector(
                                        onTap: () => forgotPassword(),
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .forgotPassword,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                    color:
                                                        const Color(0xFF206B8B),
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        const Color(
                                                            0xFF206B8B))))),
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
                                      AppLocalizations.of(context)!.or,
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
                                          AppLocalizations.of(context)!
                                              .deviceNewSetup,
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

  bool _handleAuthFailure(dynamic err) {
    if (err is Exception) {
      setState(() {
        _checkAuthFuture = Future.error(err);
      });
      return false;
    } else {
      print('Unhandled error type: $err');
      return false;
    }
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

  void _submitForm() {
    var prov = Provider.of<AuthenticationProvider>(context, listen: false);

    _loginFuture =
        prov.logIn(username: username ?? '', password: password ?? '');

    _loginFuture!.then((_) {
      Navigator.of(context).pushNamedAndRemoveUntil("/index", (route) => false);
    }).catchError((err) {
      loginHandleError(context, err);
    });
  }

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }
}
