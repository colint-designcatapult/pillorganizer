import 'package:app/provider/authentication_provider.dart';
import 'package:app/screens/auth/create_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../models/user.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({Key? key}) : super(key: key);

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();

  static Route<MyAccountPage> route(context) {
    return platformPageRoute(
        context: context, builder: (_) => const MyAccountPage());
  }
}

class _MyAccountPageState extends State<MyAccountPage> {
  @override
  Widget build(BuildContext context) {
    var authProvider = Provider.of<AuthenticationProvider>(context);
    var user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.myAccount)),
      body: SettingsList(
        sections: [
          if (user is User) ...[
            SettingsSection(
              title: Text('${user.email}'),
              tiles: [
                SettingsTile(
                  title: Text(AppLocalizations.of(context)!.signOut),
                  leading: const Icon(Icons.logout_outlined),
                  onPressed: (context) {
                    authProvider.signOut(context);
                  },
                )
              ],
            ),
          ],
          if (user is AnonymousUser) ...[
            SettingsSection(
              title: Text(AppLocalizations.of(context)!.notSignedIn),
              tiles: [
                SettingsTile(
                  title: Text(AppLocalizations.of(context)!.createAccount),
                  leading: const Icon(Icons.person_add_alt),
                  onPressed: (context) {
                    Navigator.of(context)
                        .push(CreateAccountPage.route(context));
                  },
                )
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    /*WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      deviceFuture = Provider.of<DeviceUserProvider>(context, listen: false).fetchDevices();
    });*/
  }
}
