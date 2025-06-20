import 'package:app/provider/authentication_provider.dart';
import 'package:app/provider/user_registration_provider.dart';
import 'package:app/screens/auth/launch_page_login.dart';
import 'package:app/service/error_handler.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  Future<void>? _registerFuture;
  bool _obscureText = true;
  final navFooterHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserRegistrationProvider>(
        create: (_) => UserRegistrationProvider(),
        child: Scaffold(
            backgroundColor: const Color(0xFFBFD2DB),
            body: SingleChildScrollView(
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
                                  AppLocalizations.of(context)!.createAnAccount,
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
                                  child: Text(AppLocalizations.of(context)!
                                      .haveAccountAlready))),
                          Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24.w, vertical: 8.h),
                              child: OutlinedButton(
                                onPressed: () {
                                  _handleSignInRedirect();
                                },
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0).r,
                                  ),
                                  backgroundColor: const Color(0xFFBFD2DB),
                                  minimumSize: Size(double.infinity, 48.h),
                                  // Make it full width
                                  side: const BorderSide(
                                    color: Color(
                                        0xff206B8B), // Change border color
                                  ),
                                ),
                                child: Text(
                                    AppLocalizations.of(context)!.signInAction,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Color(0xff445860))
                                        .copyWith(fontWeight: FontWeight.w600)),
                              ))
                        ])))));
  }

  Widget _formComponent() {
    return BasicFormContainer(
        subtitleText: AppLocalizations.of(context)!.createAccountSubtitle,
        buttonText: AppLocalizations.of(context)!.createAccount,
        onSubmit: () => _onSubmit(context),
        future: _registerFuture,
        children: [
          BasicPageTextFormField(
            labelText: AppLocalizations.of(context)!.email,
            validator: Validatorless.multiple([
              (value) {
                return Validatorless.email(AppLocalizations.of(context)!
                    .emailNotValid)(value?.toLowerCase());
              },
              Validatorless.required(
                  AppLocalizations.of(context)!.emailRequired)
            ]),
            onSaved: (val) => context
                .read<UserRegistrationProvider>()
                .updateEmail(val?.toLowerCase()),
          ),
          BasicPageTextFormField(
            labelText: AppLocalizations.of(context)!.password,
            validator: Validatorless.multiple([
              Validatorless.between(
                  6, 48, AppLocalizations.of(context)!.passwordLengthValidation)
            ]),
            onRevealText: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
            obscureText: _obscureText,
            textInputAction: TextInputAction.done,
            onSaved: (val) =>
                context.read<UserRegistrationProvider>().updatePassword(val),
            onFieldSubmitted: (val) {
              _onSubmit(context);
            },
          )
        ]);
  }

  void _handleSignInRedirect() {
    Navigator.of(context).push(LaunchPageLogin.route(context));
  }

  void _onSubmit(context) {
    var prov = Provider.of<UserRegistrationProvider>(context, listen: false);
    var authProv = Provider.of<AuthenticationProvider>(context, listen: false);
    _registerFuture = _register(prov, authProv).catchError((err) {
      registerHandleError(context, err);
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
}
