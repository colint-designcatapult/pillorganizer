import 'package:app/api/api.dart';
import 'package:app/provider/authentication_provider.dart';
import 'package:app/screens/ScreenUtilWrapper.dart';
import 'package:app/service/authentication_service.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    const navFooterHeight = 72;
    return ScreenUtilWrapper(
      child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Form(
              key: _formKey,
              child: Stack(children: [
                CustomScrollView(slivers: [
                  SliverAppBar(
                    iconTheme: IconThemeData(size: 24.h),
                    floating: false,
                    toolbarHeight: 60.h,
                    pinned: true,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: const Color(0xFFFBFCFF),
                    leading: null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: const Radius.circular(16).r,
                      ),
                    ),
                    actions: [
                      Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 8.h),
                          child: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.black,
                              size: 32.h,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          )),
                    ],
                  ),
                  SliverToBoxAdapter(
                      child: SizedBox(
                          height: 690.h,
                          child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 36.w),
                              child: Column(children: [
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .signInPrompt,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                      textAlign: TextAlign.left,
                                    )),
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          top: 8.h, bottom: 22.h, right: 0),
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .signInSubtitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    )),
                                SizedBox(
                                  height: 24.h,
                                ),
                                BasicPageTextFormField(
                                  labelText:
                                      AppLocalizations.of(context)!.email,
                                  validator: Validatorless.multiple([
                                    if (!useAnon)
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
                      height: navFooterHeight.h,
                      color: const Color(0xFFFBFCFF),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: SizedBox(
                                height: navFooterHeight.h,
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
                                    Text(AppLocalizations.of(context)!.back,
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
                                height: navFooterHeight.h,
                                child: FutureBuilder(
                                    future: _loginFuture,
                                    builder: (context, snapshot) {
                                      return GestureDetector(
                                        onTap: _onPressed(snapshot),
                                        child: Container(
                                          height: navFooterHeight.h,
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context).primaryColor,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(32),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                  AppLocalizations.of(context)!
                                                      .signInConfirm,
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
              ]))),
    );
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
                  child: Text(AppLocalizations.of(context)!.genericOK),
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
              AppLocalizations.of(context)!.signInError('err.problem'));
        } else {
          _showErrorDialog(AppLocalizations.of(context)!
              .signInError(authErrorMessage(context, err.toString())));
        }
      });
    });
  }
}
