import 'package:app/main.dart';
import 'package:app/provider/authentication_provider.dart';
import 'package:app/screens/auth/recover_password.dart';
import 'package:app/screens/auth/register.dart';
import 'package:app/service/error_handler.dart';
import 'package:app/utils/takecare_link_util.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';

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
      body: KeyboardDismissWrapper(
          child: SingleChildScrollView(
              child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 24.w, top: 100.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.signInAction,
                              textAlign: TextAlign.left,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: 32.h),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.only(top: 36),
                          child: _formComponent()),
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            AppLocalizations.of(context)!
                                .dontHaveAccountAlready,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 8.h),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              _handleRegisterRedirect();
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0).r,
                              ),
                              backgroundColor: const Color(0xFFBFD2DB),
                              minimumSize: Size(double.infinity, 48.h),
                              // Make it full width
                              side: const BorderSide(
                                color: Color(0xff206B8B), // Change border color
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.createAnAccount,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Color(0xff445860))
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )))),
    );
  }

  Widget _formComponent() {
    return BasicFormContainer(
      subtitleText: AppLocalizations.of(context)!.signInBackSubtitle,
      buttonText: AppLocalizations.of(context)!.signInAction,
      onSubmit: _submitForm,
      future: _loginFuture,
      children: [
        BasicPageTextFormField(
          labelText: AppLocalizations.of(context)!.email,
          validator: Validatorless.multiple([
            Validatorless.email(AppLocalizations.of(context)!.emailNotValid),
            Validatorless.required(AppLocalizations.of(context)!.emailRequired)
          ]),
          onSaved: (val) => username = val,
        ),
        BasicPageTextFormField(
          labelText: AppLocalizations.of(context)!.password,
          validator: Validatorless.required(
              AppLocalizations.of(context)!.passwordRequired),
          onFieldSubmitted: (value) => (),
          //To trigger the form submit function
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
                child: Text(AppLocalizations.of(context)!.forgotPassword,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF2680A6),
                        decoration: TextDecoration.underline,
                        decorationColor: const Color(0xFF2680A6))))),
      ],
    );
  }

  Future<bool> _handleAuthSuccess(bool status) async {
    if (status) {
      _handleSuccessfulLogin();
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

  void _handleRegisterRedirect() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const RegisterPage(),
      ),
    );
  }

  void _submitForm() {
    var prov = Provider.of<AuthenticationProvider>(context, listen: false);

    _loginFuture =
        prov.logIn(username: username ?? '', password: password ?? '');

    _loginFuture!.then((_) {
      _handleSuccessfulLogin();
    }).catchError((err) {
      loginHandleError(context, err);
    });
  }

  void _handleSuccessfulLogin() async {
    final route = await TakecareLinkUtil.handlePostAuthNavigation(context);
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }
}
