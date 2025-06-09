import 'package:app/provider/selected_device_provider.dart';
import 'package:app/screens/auth/change_password.dart';
import 'package:app/screens/auth/change_email.dart';
import 'package:app/widgets/generic_yes_no_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../provider/authentication_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void signout(BuildContext context) {
      showDialog(
          context: context,
          builder: (_) => GenericYesNoModal(
                icon: PhosphorIcons.power_fill,
                title: AppLocalizations.of(context)!.signingOut,
                subtitle: AppLocalizations.of(context)!.signingOutSubtitle,
                saveWidgetText: AppLocalizations.of(context)!.signOut,
                saveWidgetAction: () {
                  Provider.of<SelectedDeviceProvider>(context, listen: false)
                      .updateNotificationsForAll(false)
                      .then((value) => Provider.of<AuthenticationProvider>(
                              context,
                              listen: false)
                          .signOut(context));
                },
              ));
    }

    void changePassword() {
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
          builder: (context) => const ChangePassword());
    }

    void changeEmail() {
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
          builder: (context) => const ChangeEmail());
    }

    void navigateToFaq() {
      // TODO: IMPLEMENT FAQ NAVIGATION
    }

    return Scaffold(
      backgroundColor: const Color(0xFFBFD2DB),
      body: SafeArea(
          child: Padding(
              padding: EdgeInsets.only(top: 75.h),
              child: SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Text(
                            AppLocalizations.of(context)!.accountSettings,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontSize: 32.h),
                          )),
                      SizedBox(height: 8.h),
                      Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24.w, vertical: 24.h),
                          child: GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 1,
                            crossAxisSpacing: 24.w,
                            mainAxisSpacing: 24.h,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              SquareButton(
                                color: const Color(0xFF043C4D),
                                icon: PhosphorIcons.envelope_simple_fill,
                                label: AppLocalizations.of(context)!
                                    .changeEmail,
                                onPressed: () {
                                  changeEmail();
                                },
                              ),
                              SquareButton(
                                color: const Color(0xFF043C4D),
                                icon: PhosphorIcons.key_fill,
                                label: AppLocalizations.of(context)!
                                    .changePassword,
                                onPressed: () {
                                  changePassword();
                                },
                              ),
                              SquareButton(
                                color: const Color(0xFF043C4D),
                                icon: PhosphorIcons.question_fill,
                                label: AppLocalizations.of(context)!
                                    .faq,
                                onPressed: () {
                                  navigateToFaq();
                                },
                              ),
                              SquareButton(
                                color: const Color(0xFF7A2C2C),
                                icon: PhosphorIcons.power_fill,
                                label: AppLocalizations.of(context)!.signOut,
                                onPressed: () {
                                  signout(context);
                                },
                              ),
                            ],
                          ))
                    ]),
              ))),
    );
  }
}

class SquareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const SquareButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.onPressed,
      this.color = const Color(0xFF043C4D)});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(const Radius.circular(4.0).r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            SizedBox(height: 14.h),
            Icon(
              icon,
              size: 50.h,
              color: color,
            ),
            SizedBox(height: 8.h),
            SizedBox(
                height: 60.h,
                child: Align(
                    alignment: Alignment.center,
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: color,
                                )))),
          ],
        ),
      ),
    );
  }
}
