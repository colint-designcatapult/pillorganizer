import 'package:app/api/api.dart';
import 'package:app/platform/dialog.dart';
import 'package:app/provider/authentication_provider.dart';
import 'package:app/screens/auth/recover_password.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({Key? key}) : super(key: key);

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  bool showForgotPassword = false;

  @override
  Widget build(BuildContext context) {
    return showForgotPassword
        ? RecoverPassword(
            onBack: () => setState(() {
              showForgotPassword = false;
            }),
          )
        : ChangePasswordModal(
            gotoForgotPassword: () => setState(() {
              showForgotPassword = true;
            }),
          );
  }
}

class ChangePasswordModal extends StatefulWidget {
  final VoidCallback gotoForgotPassword;

  const ChangePasswordModal({
    super.key,
    required this.gotoForgotPassword,
  });
  @override
  State<ChangePasswordModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<ChangePasswordModal> {
  static const navFooterHeight = 72.0;
  final _formKey = GlobalKey<FormState>();
  String? currentPassword;
  String? newPassword;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthenticationProvider>(
        create: (_) => AuthenticationProvider(),
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
                                            .changePassword,
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
                                              .changePasswordSubtitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      )),
                                  SizedBox(
                                    height: 24.h,
                                  ),
                                  BasicPageTextFormField(
                                    labelText: AppLocalizations.of(context)!
                                        .currentPassword,
                                    validator: Validatorless.multiple([
                                      Validatorless.between(
                                          6,
                                          48,
                                          AppLocalizations.of(context)!
                                              .passwordLengthValidation)
                                    ]),
                                    onSaved: (val) => currentPassword = val,
                                  ),
                                  BasicPageTextFormField(
                                    labelText: AppLocalizations.of(context)!
                                        .newPassword,
                                    validator: Validatorless.multiple([
                                      Validatorless.between(
                                          6,
                                          48,
                                          AppLocalizations.of(context)!
                                              .passwordLengthValidation)
                                    ]),
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    onSaved: (val) => newPassword = val,
                                    onFieldSubmitted: (val) {
                                      _onSubmit(context);
                                    },
                                  ),
                                  /*Align(
                                      alignment: Alignment.bottomRight,
                                      child: GestureDetector(
                                          onTap: widget.gotoForgotPassword,
                                          child: Text('Forgot password?',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                      color: const Color(
                                                          0xFF206B8B),
                                                      decoration: TextDecoration
                                                          .underline,
                                                      decorationColor:
                                                          const Color(
                                                              0xFF206B8B))))),*/
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
                                      Icon(
                                        Icons.arrow_back,
                                        size: 24.h,
                                      ),
                                      SizedBox(
                                        width: 8.h,
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
                                  height: navFooterHeight,
                                  child: FutureBuilder(
                                      future: context
                                          .read<AuthenticationProvider>()
                                          .future,
                                      builder: (context, snapshot) {
                                        return GestureDetector(
                                          onTap: () => _onSubmit(context),
                                          child: Container(
                                            height: navFooterHeight,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .primaryColor,
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
                                                    AppLocalizations.of(
                                                            context)!
                                                        .save,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                            color:
                                                                Colors.white)),
                                                SizedBox(
                                                  width: 8.w,
                                                ),
                                                Icon(
                                                  Icons.check,
                                                  size: 24.h,
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
                ]))));
  }

  void _onSubmit(context) {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      _submit(context);
    }
  }

  void _submit(BuildContext context) {
    var authProv = Provider.of<AuthenticationProvider>(context, listen: false);
    _changePassword(authProv, currentPassword!, newPassword!).then((value) {
      if (value) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          showAlertDialog(
                  context, AppLocalizations.of(context)!.passwordChangedSuccess)
              .then((value) => Navigator.pop(context));
        });
      }
    }).catchError((err) {
      _handleError(context, err);
    });
  }

  Future<bool> _changePassword(AuthenticationProvider authProv,
      String currentPassword, String newPassword) async {
    await authProv.changePassword(
        currentPassword: currentPassword, newPassword: newPassword);
    return true;
  }

  void _handleError(context, err) {
    debugPrint(err.toString());
    if (err is ProblemJsonException) {
      showAlertDialog(
          context, AppLocalizations.of(context)!.genericProblem(err.problem));
    } else {
      showAlertDialog(context,
          AppLocalizations.of(context)!.genericProblem(err.toString()));
    }
  }
}
