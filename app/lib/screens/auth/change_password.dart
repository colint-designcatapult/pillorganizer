import 'package:app/provider/authentication_provider.dart';
import 'package:app/provider/user_registration_provider.dart';
import 'package:app/screens/auth/recover_password.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';

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
                        Padding(
                            padding: const EdgeInsets.all(8),
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black,
                                size: 32,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            )),
                      ],
                    ),
                    SliverToBoxAdapter(
                        child: SizedBox(
                            height: 690,
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 36),
                                child: Column(children: [
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Change Password',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                        textAlign: TextAlign.left,
                                      )),
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            top: 8, bottom: 22, right: 0),
                                        child: Text(
                                          'Please enter your current password in order to set up a new one.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      )),
                                  const SizedBox(
                                    height: 24,
                                  ),
                                  BasicPageTextFormField(
                                    labelText: 'Current Password',
                                    validator: Validatorless.multiple([
                                      Validatorless.between(6, 48,
                                          "Passwords must be between 6 and 32 characters")
                                    ]),
                                    onSaved: (val) => currentPassword = val,
                                  ),
                                  BasicPageTextFormField(
                                    labelText: 'New Password',
                                    validator: Validatorless.multiple([
                                      Validatorless.between(6, 48,
                                          "Passwords must be between 6 and 32 characters")
                                    ]),
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    onSaved: (val) => newPassword = val,
                                    onFieldSubmitted: (val) {
                                      _onSubmit(context);
                                    },
                                  ),
                                  Align(
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
                                                              0xFF206B8B))))),
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
                                      future: context
                                          .read<
                                              UserRegistrationProvider>() //j'imagine tu va creer une new provider? sinon ca peut etre delete>()
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
                                                Text('Save',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                            color:
                                                                Colors.white)),
                                                const SizedBox(
                                                  width: 8,
                                                ),
                                                const Icon(
                                                  Icons.check,
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
                ]))));
  }

  void _onSubmit(context) {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      _submit(context);
    }
  }

  void _submit(context) {
    //CHANGE PASSWORD
  }
}
