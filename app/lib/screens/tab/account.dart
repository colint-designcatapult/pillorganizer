import 'package:app/screens/auth/change_email.dart';
import 'package:app/screens/auth/change_password.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../provider/authentication_provider.dart';
import '../../provider/device_provider.dart';
import '../../provider/language_provider.dart';
import '../../widgets/generic_yes_no_modal.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _isSigningOut = false;

  Future<void> _performSignOut() async {
    setState(() => _isSigningOut = true);
    try {
      await ref.read(authenticationProvider.notifier).signOut();
    } catch (_) {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    void signout(BuildContext context) {
      showDialog(
          context: context,
          builder: (_) => GenericYesNoModal(
                icon: PhosphorIconsFill.power,
                title: AppLocalizations.of(context)!.signingOut,
                subtitle: AppLocalizations.of(context)!.signingOutSubtitle,
                saveWidgetText: AppLocalizations.of(context)!.signOut,
                saveWidgetAction: () {
                  Navigator.of(context).pop(); // close the confirmation dialog
                  _performSignOut();
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

    void changeLanguage() {
      final languageNotifier = ref.read(languageProvider.notifier);
      final currentLocale = ref.watch(languageProvider);

      showModalBottomSheet<void>(
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
        builder: (context) => Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.selectLanguage,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 24.h),
              ...languageNotifier.supportedLanguages.map(
                (lang) => ListTile(
                  title: Text(lang['name']!),
                  leading: Radio<String>(
                    value: lang['code']!,
                    groupValue: currentLocale.languageCode,
                    onChanged: (value) {
                      if (value != null) {
                        languageNotifier.setLanguage(value);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  onTap: () {
                    languageNotifier.setLanguage(lang['code']!);
                    Navigator.of(context).pop();
                  },
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
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
                                  // TODO: Re-enable in future
                                  // SquareButton(
                                  //   color: const Color(0xFF043C4D),
                                  //   icon: PhosphorIconsFill.envelopeSimple,
                                  //   label:
                                  //       AppLocalizations.of(context)!.changeEmail,
                                  //   onPressed: () {
                                  //     changeEmail();
                                  //   },
                                  // ),
                                  // SquareButton(
                                  //   color: const Color(0xFF043C4D),
                                  //   icon: PhosphorIconsFill.key,
                                  //   label: AppLocalizations.of(context)!
                                  //       .changePassword,
                                  //   onPressed: () {
                                  //     changePassword();
                                  //   },
                                  // ),
                                  // SquareButton(
                                  //   color: const Color(0xFF043C4D),
                                  //   icon: PhosphorIconsRegular.translate,
                                  //   label: AppLocalizations.of(context)!
                                  //       .changeLanguage,
                                  //   onPressed: () {
                                  //     changeLanguage();
                                  //   },
                                  // ),
                                  SquareButton(
                                    color: const Color(0xFF7A2C2C),
                                    icon: PhosphorIconsFill.power,
                                    label: AppLocalizations.of(context)!.signOut,
                                    onPressed: _isSigningOut
                                        ? () {}
                                        : () {
                                            signout(context);
                                          },
                                  ),
                                ],
                              ))
                        ]),
                  ))),
        ),
        // Full-screen loading overlay shown while sign-out is in progress
        if (_isSigningOut)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0x80000000),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16.h),
                    Text(
                      AppLocalizations.of(context)!.signingOut,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 12.h),
            Icon(
              icon,
              size: 50.h,
              color: color,
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: color,
                      ),
                ),
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}
