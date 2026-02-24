import 'package:app/models/user.dart';
import 'package:app/provider/authentication_provider.dart';
import 'package:app/service/error_handler.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';

class RecoverPassword extends StatefulWidget {
  final VoidCallback onBack;
  const RecoverPassword({Key? key, required this.onBack}) : super(key: key);

  @override
  State<RecoverPassword> createState() => _RecoverPasswordState();
}

class _RecoverPasswordState extends State<RecoverPassword> {
  bool showRecoveryInput = false;
  String? usedEmail;

  Future<void> _sendRecoveryEmail(String email) async {
    try {
      await Provider.of<AuthenticationProvider>(context, listen: false)
          .sendRecoveryCode(email);
    } catch (e) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        showErrorDialog(context, AppLocalizations.of(context)!.genericTryAgain)
            .then((value) => Navigator.pop(context));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return showRecoveryInput
        ? RecoverPasswordInput(
            onBack: () {
              setState(() {
                showRecoveryInput = false;
              });
            },
            onSendAgain: () async {
              await _sendRecoveryEmail(usedEmail!);
            },
            usedEmail: usedEmail!)
        : RecoverPasswordPrompt(
            onBack: widget.onBack,
            gotoRecoveryInput: (email) async {
              await _sendRecoveryEmail(email);
              setState(() {
                usedEmail = email;
                showRecoveryInput = true;
              });
            },
          );
  }
}

class RecoverPasswordPrompt extends StatefulWidget {
  final Future<void> Function(String) gotoRecoveryInput;
  final VoidCallback onBack;
  static const navFooterHeight = 72.0;

  const RecoverPasswordPrompt({
    super.key,
    required this.gotoRecoveryInput,
    required this.onBack,
  });

  @override
  State<RecoverPasswordPrompt> createState() => _RecoverPasswordPromptState();
}

class _RecoverPasswordPromptState extends State<RecoverPasswordPrompt> {
  String? email;
  final _formKey = GlobalKey<FormState>();

  void submitForm(String mail) {
    print("submitForm $mail");
    widget.gotoRecoveryInput(mail);
  }

  @override
  Widget build(BuildContext context) {
    var authUser = Provider.of<AuthenticationProvider>(context, listen: false)
        .currentUser;

    Widget buildNoUserForm() {
      return Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 22, right: 0),
                child: Text(
                  AppLocalizations.of(context)!
                      .sendRecoveryLinkSubtitleWithEmail,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )),
          Padding(
            padding: const EdgeInsets.only(top: 36),
            child: BasicPageTextFormField(
              labelText: AppLocalizations.of(context)!.email,
              validator: Validatorless.multiple([
                Validatorless.email(
                    AppLocalizations.of(context)!.emailNotValid),
                Validatorless.required(
                    AppLocalizations.of(context)!.emailRequired)
              ]),
              onChanged: (val) {
                setState(() {
                  email = val;
                });
              },
              onSaved: (val) => email = val,
            ),
          ),
        ]),
      );
    }

    Widget buildLinkForm(String email) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 22, right: 0),
              child: Text(
                AppLocalizations.of(context)!.sendRecoveryLinkSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )),
        const SizedBox(
          height: 30,
        ),
        GestureDetector(
            onTap: () => submitForm(email),
            child: Text(AppLocalizations.of(context)!.sendRecoveryLink,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF206B8B),
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFF206B8B))))
      ]);
    }

    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Stack(children: [
          CustomScrollView(slivers: [
            SliverAppBar(
              floating: false,
              pinned: true,
              toolbarHeight: 60.h,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: const Color(0xFFFBFCFF),
              leading: null,
              automaticallyImplyLeading: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16).r,
                ),
              ),
              actions: [
                Padding(
                    padding: const EdgeInsets.all(8),
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
                    height: 690,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .passwordRecovery,
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                    textAlign: TextAlign.left,
                                  )),
                              const SizedBox(
                                height: 8,
                              ),
                              if (authUser != null && authUser.email != null)
                                buildLinkForm(authUser.email!)
                              else
                                buildNoUserForm()
                            ])))),
          ]),
          Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: RecoverPasswordPrompt.navFooterHeight,
                color: const Color(0xFFFBFCFF),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: SizedBox(
                          height: RecoverPasswordPrompt.navFooterHeight,
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
                                  style:
                                      Theme.of(context).textTheme.titleSmall),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                          width: double.infinity,
                          height: RecoverPasswordPrompt.navFooterHeight,
                          child: FutureBuilder(
                              future:
                                  context.read<AuthenticationProvider>().future,
                              builder: (context, snapshot) {
                                return GestureDetector(
                                  onTap: () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      _formKey.currentState?.save();
                                      if (email != null && email!.isNotEmpty) {
                                        submitForm(email!);
                                      }
                                    }
                                  },
                                  child: Container(
                                    height:
                                        RecoverPasswordPrompt.navFooterHeight,
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
                                        Text(AppLocalizations.of(context)!.save,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                    color: Colors.white)),
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
        ]));
  }
}

class RecoverPasswordInput extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSendAgain;
  final String usedEmail;

  const RecoverPasswordInput({
    super.key,
    required this.onBack,
    required this.onSendAgain,
    required this.usedEmail,
  });
  @override
  State<RecoverPasswordInput> createState() => _RecoverPasswordInputState();
}

class _RecoverPasswordInputState extends State<RecoverPasswordInput> {
  static const navFooterHeight = 72.0;
  final _formKey = GlobalKey<FormState>();
  String? newPassword;
  String? confirmNewPassword;
  int? recoveryCode;
  final TextEditingController _newsPasswordcontroller = TextEditingController();
  bool showDigitCode = true;
  bool showOnSendAgain = false;
  bool resetInput = false;
  bool obscureTextNewPw = true;
  bool obscureTextConfirmPw = true;

  void showSendAgainAfterDelay() {
    Future.delayed(const Duration(seconds: 45), () {
      setState(() {
        showOnSendAgain = true;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    showSendAgainAfterDelay();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Form(
            key: _formKey,
            child: Stack(children: [
              CustomScrollView(slivers: [
                SliverAppBar(
                  floating: false,
                  pinned: true,
                  toolbarHeight: 60.h,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: const Color(0xFFFBFCFF),
                  automaticallyImplyLeading: false,
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
                            padding: const EdgeInsets.symmetric(horizontal: 36),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .passwordRecovery,
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
                                              .passwordRecoverySubtitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      )),
                                  const SizedBox(
                                    height: 24,
                                  ),
                                  showDigitCode
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                              Text(
                                                AppLocalizations.of(context)!
                                                    .enterRecoveryCode,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .displaySmall,
                                              ),
                                              SizedBox(height: 20.h),
                                              SixDigitCodeInput(
                                                  onSubmitted: (code) =>
                                                      onValidateDigitCode(
                                                          context,
                                                          code,
                                                          widget.usedEmail),
                                                  reset: resetInput),
                                              SizedBox(height: 50.h),
                                              if (showOnSendAgain)
                                                Text(AppLocalizations.of(
                                                        context)!
                                                    .recoveryLinkWaiting),
                                              if (showOnSendAgain)
                                                GestureDetector(
                                                    onTap: () {
                                                      widget.onSendAgain();
                                                      setState(() {
                                                        showOnSendAgain = false;
                                                      });
                                                      showSendAgainAfterDelay();
                                                    },
                                                    child: Text(
                                                        AppLocalizations.of(
                                                                context)!
                                                            .sendRecoveryLink,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                                color: const Color(
                                                                    0xFF206B8B),
                                                                decoration:
                                                                    TextDecoration
                                                                        .underline,
                                                                decorationColor:
                                                                    const Color(
                                                                        0xFF206B8B))))
                                            ])
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                              BasicPageTextFormField(
                                                labelText: AppLocalizations.of(
                                                        context)!
                                                    .newPassword,
                                                validator:
                                                    Validatorless.multiple([
                                                  Validatorless.required(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .passwordRequired),
                                                  Validatorless.between(
                                                      6,
                                                      48,
                                                      AppLocalizations.of(
                                                              context)!
                                                          .passwordLengthValidation)
                                                ]),
                                                onSaved: (val) =>
                                                    newPassword = val,
                                                onChanged: (val) =>
                                                    _newsPasswordcontroller
                                                        .text = val,
                                                onRevealText: () {
                                                  setState(() {
                                                    obscureTextNewPw =
                                                        !obscureTextNewPw;
                                                  });
                                                },
                                                obscureText: obscureTextNewPw,
                                              ),
                                              BasicPageTextFormField(
                                                labelText: AppLocalizations.of(
                                                        context)!
                                                    .confirmNewPassword,
                                                validator:
                                                    Validatorless.multiple([
                                                  Validatorless.required(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .passwordRequired),
                                                  Validatorless.between(
                                                      6,
                                                      48,
                                                      AppLocalizations.of(
                                                              context)!
                                                          .passwordLengthValidation),
                                                  Validatorless.compare(
                                                      _newsPasswordcontroller,
                                                      AppLocalizations.of(
                                                              context)!
                                                          .passwordNotMatching)
                                                ]),
                                                textInputAction:
                                                    TextInputAction.done,
                                                onSaved: (val) =>
                                                    confirmNewPassword = val,
                                                onRevealText: () {
                                                  setState(() {
                                                    obscureTextConfirmPw =
                                                        !obscureTextConfirmPw;
                                                  });
                                                },
                                                obscureText:
                                                    obscureTextConfirmPw,
                                              ),
                                            ])
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
                          onTap: widget.onBack,
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
                                    style:
                                        Theme.of(context).textTheme.titleSmall),
                              ],
                            ),
                          ),
                        )),
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
                                      onTap: () {
                                        if (_formKey.currentState?.validate() ??
                                            false) {
                                          _formKey.currentState?.save();
                                          if (newPassword != null &&
                                              newPassword!.isNotEmpty) {
                                            _changePassword(widget.usedEmail,
                                                    newPassword!)
                                                .then((value) {
                                              if (value) {
                                                SchedulerBinding.instance
                                                    .addPostFrameCallback((_) {
                                                  showErrorDialog(
                                                          context,
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .passwordChangedSuccess)
                                                      .then((value) =>
                                                          Navigator.pop(
                                                              context));
                                                });
                                              }
                                            }).catchError((err) {
                                              passwordHandleError(context, err)
                                                  .then((value) =>
                                                      Navigator.pop(context));
                                            });
                                          }
                                        }
                                      },
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
                                            Text(
                                                AppLocalizations.of(context)!
                                                    .save,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                        color: Colors.white)),
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
            ])));
  }

  Future<void> onValidateDigitCode(
      BuildContext context, String code, String email) async {
    try {
      bool isCodeValid =
          await Provider.of<AuthenticationProvider>(context, listen: false)
              .validateRecoveryCode(int.parse(code), email);
      if (isCodeValid) {
        setState(() {
          showDigitCode = false;
          recoveryCode = int.parse(code);
        });
      } else {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          showErrorDialog(
                  context, AppLocalizations.of(context)!.validationWrongCode)
              .then((value) => setState(() {
                    resetInput = true;
                  }));
        });
      }
    } catch (e) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        showErrorDialog(
                context, AppLocalizations.of(context)!.errorTriedToManyTimes)
            .then((value) => Navigator.pop(context));
      });
    }
  }

  Future<bool> _changePassword(String email, String password) async {
    await Provider.of<AuthenticationProvider>(context, listen: false)
        .newPassword(
            email: email, newPassword: password, recoveryCode: recoveryCode!);
    return true;
  }
}
