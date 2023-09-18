import 'package:app/api/device.dart';
import 'package:app/provider/time_provider.dart';
import 'package:app/screens/first_launch.dart';
import 'package:app/screens/index.dart';
import 'package:app/screens/post_setup_wizard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'api/auth.dart';
import 'api/medication.dart';
import 'api/schedule.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  tz.initializeTimeZones();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthenticationProvider(),
        ),
        ChangeNotifierProvider<DeviceListProvider>.value(
            value: deviceRepo.deviceListProvider),
        ChangeNotifierProxyProvider<DeviceListProvider, SelectedDeviceProvider>(
          create: (context) => SelectedDeviceProvider(),
          update: (context, list, prov) => prov!.update(list.value),
        ),
        ChangeNotifierProxyProvider<SelectedDeviceProvider,
                MedicationsProvider>(
            create: (context) => MedicationsProvider(
                Provider.of<SelectedDeviceProvider>(context, listen: false)
                    .device),
            update: (context, device, old) => old!.update(device.device)),
        ChangeNotifierProxyProvider<SelectedDeviceProvider, ScheduleProvider>(
            create: (context) => ScheduleProvider(),
            update: (context, dev, prov) => prov!.update(dev.device)),
        // Bluetooth disabled because it is horribly broken and needs rewrite
        /*ChangeNotifierProxyProvider<SelectedDeviceProvider, DeviceBluetoothProvider>(
            create: (context) => DeviceBluetoothProvider(),
            update: (context, dev, prov) {
              if(prov != null) {
                prov.changeDevice(dev.device);
                return prov;
              } else {
                return DeviceBluetoothProvider(selectedDevice: dev.device);
              }
            }
        ),*/
        ChangeNotifierProvider<MinuteBasedTimeProvider>(
          create: (context) => MinuteBasedTimeProvider(),
        ),
      ],
      child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 1.0,
          ),
          child: PlatformProvider(
            settings: PlatformSettingsData(iosUsesMaterialWidgets: true),
            builder: (context) => MaterialApp(
              title: 'Cabinet Pills',
              themeMode: ThemeMode.system,
              routes: {
                '/': (context) => const FirstLaunchPage(),
                '/index': (context) => const IndexPage(),
                '/post_setup': (context) => const PostSetupWizard()
              },
              supportedLocales: const [Locale('en')],
              localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                AppLocalizations.delegate,
                DefaultMaterialLocalizations.delegate,
                DefaultWidgetsLocalizations.delegate,
                DefaultCupertinoLocalizations.delegate,
              ],
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                colorScheme:
                    ColorScheme.fromSeed(seedColor: const Color(0xff206b8b)),
                appBarTheme: const AppBarTheme(
                    toolbarHeight: 70,
                    titleSpacing: 25,
                    color: Color(0xff206b8b),
                    iconTheme: IconThemeData(color: Colors.white),
                    titleTextStyle: TextStyle(
                        fontFamily: 'Roboto Slab',
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                        color: Colors.white),
                    toolbarTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.normal,
                    ),
                    systemOverlayStyle: SystemUiOverlayStyle(
                      systemNavigationBarColor: Colors.white,
                      statusBarColor: Colors.transparent,
                      systemNavigationBarIconBrightness: Brightness.light,
                      statusBarIconBrightness: Brightness.light,
                    )),
                primaryColor: const Color(0xff206b8b),
                fontFamily: 'Roboto',
                textTheme: const TextTheme(
                    titleLarge: TextStyle(
                      fontFamily: 'Roboto Slab',
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                    titleMedium: TextStyle(
                      fontFamily: 'Roboto Slab',
                      fontWeight: FontWeight.w400,
                      fontSize: 22,
                    ),
                    titleSmall: TextStyle(
                      fontFamily: 'Roboto Slab',
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                    labelLarge: TextStyle(fontFamily: 'Roboto', fontSize: 18),
                    bodySmall: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w400),
                    bodyMedium: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
              ),
              navigatorObservers: [routeObserver],
            ),
          )),
    );
  }
}
