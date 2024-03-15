import 'package:app/provider/authentication_provider.dart';
import 'package:app/provider/user_registration_provider.dart';
import 'package:app/service/error_handler.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    const navFooterHeight = 72.0;

    return ChangeNotifierProvider<UserRegistrationProvider>(
        create: (_) => UserRegistrationProvider(),
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
                                        AppLocalizations.of(context)!
                                            .createAccount,
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
                                          AppLocalizations.of(context)!
                                              .createAccountSubtitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      )),
                                  const SizedBox(
                                    height: 24,
                                  ),
                                  BasicPageTextFormField(
                                    labelText:
                                        AppLocalizations.of(context)!.email,
                                    validator: Validatorless.multiple([
                                      (value) {
                                        return Validatorless.email(
                                                AppLocalizations.of(context)!
                                                    .emailNotValid)(
                                            value?.toLowerCase());
                                      },
                                      Validatorless.required(
                                          AppLocalizations.of(context)!
                                              .emailRequired)
                                    ]),
                                    onSaved: (val) => context
                                        .read<UserRegistrationProvider>()
                                        .updateEmail(val?.toLowerCase()),
                                  ),
                                  BasicPageTextFormField(
                                    labelText:
                                        AppLocalizations.of(context)!.password,
                                    validator: Validatorless.multiple([
                                      Validatorless.between(
                                          6,
                                          48,
                                          AppLocalizations.of(context)!
                                              .passwordLengthValidation)
                                    ]),
                                    onRevealText: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                    obscureText: _obscureText,
                                    textInputAction: TextInputAction.done,
                                    onSaved: (val) => context
                                        .read<UserRegistrationProvider>()
                                        .updatePassword(val),
                                    onFieldSubmitted: (val) {
                                      _onSubmit(context);
                                    },
                                  )
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
                                  height: navFooterHeight,
                                  child: FutureBuilder(
                                      future: context
                                          .read<UserRegistrationProvider>()
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
                                                        .signUp,
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
    ;
  }

  void _submit(context) {
    var prov = Provider.of<UserRegistrationProvider>(context, listen: false);
    var authProv = Provider.of<AuthenticationProvider>(context, listen: false);
    _register(prov, authProv).catchError((err) {
      registerHandleError(context, err);
      return false;
    }).then((value) {
      if (value) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          Navigator.pop(context);
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
