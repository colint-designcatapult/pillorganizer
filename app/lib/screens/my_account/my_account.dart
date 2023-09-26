import 'package:app/provider/auth.dart';
import 'package:app/screens/auth/create_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

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
      appBar: AppBar(title: const Text('My Account')),
      body: SettingsList(
        sections: [
          if (user is User) ...[
            SettingsSection(
              title: Text('${user.email}'),
              tiles: [
                SettingsTile(
                  title: const Text('Sign out'),
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
              title: const Text('Not signed in'),
              tiles: [
                SettingsTile(
                  title: const Text('Create Account'),
                  leading: const Icon(Icons.person_add_alt),
                  onPressed: (context) {
                    Navigator.of(context)
                        .push(CreateAccountPage.route(context));
                  },
                )
              ],
            ),
          ],
          SettingsSection(
            title: const Text('Engineering'),
            tiles: [
              SettingsTile(
                title: const Text('Force sign out (engineering only)'),
                leading: const Icon(Icons.warning_amber),
                onPressed: (context) {
                  Provider.of<AuthenticationProvider>(context, listen: false)
                      .signOut(context);
                },
              )
            ],
          ),
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
