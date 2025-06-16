import 'package:app/provider/provision_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/provisioning/connecting_screen.dart';
import '../screens/provisioning/provision.dart';
import '../screens/provisioning/wifi_select_screen.dart';

class ProvisionNavigator extends StatefulWidget {
  const ProvisionNavigator({super.key});

  @override
  _ProvisionNavigatorState createState() => _ProvisionNavigatorState();
}

void startProvisioning(BuildContext context) {
  Navigator.push(context,
      MaterialPageRoute(builder: (context) => const ProvisionNavigator()));
}

class _ProvisionNavigatorState extends State<ProvisionNavigator> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProvisionProvider>(
      create: (context) => ProvisionProvider(),
      child: Navigator(
        key: _navigatorKey,
        initialRoute: 'bt',
        onGenerateRoute: (RouteSettings settings) {
          WidgetBuilder builder;
          switch (settings.name) {
            case 'bt':
              builder = (BuildContext _) => const ProvisionPage();
              break;
            case 'select_wifi':
              builder = (BuildContext _) => const ProvisionSelectWifiPage();
              break;
            case 'connecting':
              builder = (BuildContext _) => const ProvisionConnectingPage();
              break;
            default:
              throw Exception('Invalid route: ${settings.name}');
          }
          return MaterialPageRoute(builder: builder, settings: settings);
        },
      ),
    );
  }
}
