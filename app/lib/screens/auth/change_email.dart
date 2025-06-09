import 'package:app/provider/authentication_provider.dart';
import 'package:app/service/error_handler.dart';
import 'package:app/widgets/basic_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:validatorless/validatorless.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangeEmail extends StatefulWidget {
  const ChangeEmail({Key? key}) : super(key: key);

  @override
  State<ChangeEmail> createState() => _ChangeEmailState();
}

class _ChangeEmailState extends State<ChangeEmail> {
  @override
  Widget build(BuildContext context) {
    return ChangeEmailModal();
  }
}

class ChangeEmailModal extends StatefulWidget {
  const ChangeEmailModal({
    super.key,
  });
  @override
  State<ChangeEmailModal> createState() => _ChangeEmailModalState();
}

class _ChangeEmailModalState extends State<ChangeEmailModal> {
  static const navFooterHeight = 72.0;
  final _formKey = GlobalKey<FormState>();
  String? currentEmail;
  String? newEmail;

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
                      automaticallyImplyLeading: false,
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
                                            .changeEmail,
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
                                              .changeEmailSubtitle,
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
                                        .currentEmail,
                                    validator: Validatorless.multiple([
                                      Validatorless.regex(
                                          RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
                                          AppLocalizations.of(context)!.invalidEmailFormat),
                                    ]),
                                    onSaved: (val) => currentEmail = val,
                                  ),
                                  BasicPageTextFormField(
                                    labelText: AppLocalizations.of(context)!
                                        .newEmail,
                                    validator: Validatorless.multiple([
                                      Validatorless.regex(
                                          RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
                                          AppLocalizations.of(context)!.invalidEmailFormat),
                                    ]),
                                    textInputAction: TextInputAction.done,
                                    onSaved: (val) => newEmail = val,
                                    onFieldSubmitted: (val) {
                                      _onSubmit(context);
                                    },
                                    paddingBottom: 12,
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

    if (currentEmail == newEmail) {
      showErrorDialog(
          context, AppLocalizations.of(context)!.emailChangedIdentical);
    } else {
      _changeEmail(authProv, currentEmail!, newEmail!).then((value) {
        if (value) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            showErrorDialog(context,
                    AppLocalizations.of(context)!.emailChangedSuccess)
                .then((value) => Navigator.pop(context));
          });
        }
      }).catchError((err) {
        passwordHandleError(context, err);
      });
    }
  }

  Future<bool> _changeEmail(AuthenticationProvider authProv,
      String currentEmail, String newEmail) async {
    return true;
  }
}
