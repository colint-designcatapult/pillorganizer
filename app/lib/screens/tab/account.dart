import 'package:app/api/device.dart';
import 'package:app/models/user.dart';
import 'package:app/navigation/provision_navigator.dart';
import 'package:app/screens/auth/register.dart';
import 'package:app/widgets/generic_yes_no_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:provider/provider.dart';
import 'package:app/screens/modals/device_selector_modal.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../provider/authentication_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var authProvider = Provider.of<AuthenticationProvider>(context);
    var user = authProvider.currentUser;
    var numberOfDevices =
        Provider.of<DeviceListProvider>(context, listen: false).value?.length;

    void register() {
      showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          builder: (context) => const RegisterPage());
    }

    void exitApplication(BuildContext context) {
      showDialog(
        context: context,
        builder: (_) => GenericYesNoModal(
          icon: PhosphorIcons.power_fill,
          title: AppLocalizations.of(context)!.exitApplication,
          subtitle: AppLocalizations.of(context)!.exitApplicationSubtitle,
          saveWidgetText: AppLocalizations.of(context)!.signOut,
          saveWidgetAction: () =>
              Provider.of<AuthenticationProvider>(context, listen: false)
                  .signOut(context),
        ),
      );
    }

    void signout(BuildContext context) {
      showDialog(
        context: context,
        builder: (_) => GenericYesNoModal(
          icon: PhosphorIcons.power_fill,
          title: AppLocalizations.of(context)!.signingOut,
          subtitle: AppLocalizations.of(context)!.signingOutSubtitle,
          saveWidgetText: AppLocalizations.of(context)!.signOut,
          saveWidgetAction: () =>
              Provider.of<AuthenticationProvider>(context, listen: false)
                  .signOut(context),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFBFD2DB),
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.only(top: 75),
              child: SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            AppLocalizations.of(context)!.accountSettings,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontSize: 32),
                          )),
                      const SizedBox(height: 8),
                      Padding(
                          padding: const EdgeInsets.all(24),
                          child: GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 1,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              SquareButton(
                                color: const Color(0xFF043C4D),
                                icon: PhosphorIcons.plus_circle_fill,
                                label:
                                    AppLocalizations.of(context)!.addNewDevice,
                                onPressed: () {
                                  startProvisioning(context);
                                },
                              ),
                              if (user is User)
                                SquareButton(
                                  color: const Color(0xFF7A2C2C),
                                  icon: PhosphorIcons.power_fill,
                                  label: AppLocalizations.of(context)!.signOut,
                                  onPressed: () {
                                    signout(context);
                                  },
                                ),
                              if (user is AnonymousUser)
                                SquareButton(
                                  color: const Color(0xFF043C4D),
                                  icon: PhosphorIcons.user_fill,
                                  label: AppLocalizations.of(context)!
                                      .createAccount,
                                  onPressed: () {
                                    register();
                                  },
                                ),
                              if (numberOfDevices != null &&
                                  numberOfDevices > 1)
                                SquareButton(
                                  color: const Color(0xFF043C4D),
                                  icon: PhosphorIcons.arrows_clockwise,
                                  label: AppLocalizations.of(context)!
                                      .switchDevice,
                                  onPressed: () {
                                    showDeviceSelectorModal(context);
                                  },
                                ),
                              if (user is AnonymousUser)
                                SquareButton(
                                  color: const Color(0xFF043C4D),
                                  icon: PhosphorIcons.sign_out,
                                  label: AppLocalizations.of(context)!
                                      .exitApplication,
                                  onPressed: () {
                                    exitApplication(context);
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
        width: 150,
        height: 150,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(4.0)),
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
            const SizedBox(height: 14),
            Icon(
              icon,
              size: 56.0,
              color: color,
            ),
            const SizedBox(height: 8),
            SizedBox(
                height: 48,
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
