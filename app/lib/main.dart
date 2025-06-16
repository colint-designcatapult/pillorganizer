import 'package:app/api/device.dart';
import 'package:app/navigation/provision_navigator.dart';
import 'package:app/navigation/tab_navigator.dart';
import 'package:app/provider/ble_provider.dart';
import 'package:app/provider/caregiver_provider.dart';
import 'package:app/provider/medication_provider.dart';
import 'package:app/provider/provision_provider.dart';
import 'package:app/provider/time_provider.dart';
import 'package:app/provider/user_registration_provider.dart';
import 'package:app/screens/ScreenUtilWrapper.dart';
import 'package:app/screens/first_launch.dart';
import 'package:app/screens/name_device_wizard.dart';
import 'package:app/screens/post_setup_wizard.dart';
import 'package:app/service/credential_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'firebase_options.dart';
import 'provider/authentication_provider.dart';
import 'provider/schedule_provider.dart';
import 'provider/selected_device_provider.dart';
import 'screens/auth/launch_page_login.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    name: 'Cabinet',
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp(
    name: 'Cabinet',
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = (errorDetails) {
    if (!errorDetails.toString().contains('A RenderFlex overflowed by')) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    }
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  tz.initializeTimeZones();
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilWrapper(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => AuthenticationProvider(),
          ),
          ChangeNotifierProvider<UserRegistrationProvider>(
              create: (_) => UserRegistrationProvider()),
          ChangeNotifierProvider<DeviceListProvider>.value(
              value: deviceRepo.deviceListProvider),
          ChangeNotifierProxyProvider<DeviceListProvider,
              SelectedDeviceProvider>(
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
          ChangeNotifierProvider<MinuteBasedTimeProvider>(
            create: (context) => MinuteBasedTimeProvider(),
          ),
          ChangeNotifierProxyProvider<SelectedDeviceProvider,
                  DeviceBluetoothProvider>(
              create: (context) => DeviceBluetoothProvider(),
              update: (context, dev, prov) {
                if (prov != null) {
                  prov.changeDevice(dev.device);
                  return prov;
                } else {
                  return DeviceBluetoothProvider(selectedDevice: dev.device);
                }
              }),
          ChangeNotifierProvider<CaregiverProvider>(
              create: (_) => CaregiverProvider()),
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
                onGenerateRoute: (settings) {
                  if (settings.name?.startsWith('/name_new_device') == true) {
                    final uri = Uri.parse(settings.name!);
                    final deviceId = uri.queryParameters['id'] != null
                        ? int.parse(uri.queryParameters['id']!)
                        : null;

                    return MaterialPageRoute(
                      builder: (context) =>
                          ChangeNotifierProvider<ProvisionProvider>(
                        create: (context) => ProvisionProvider(),
                        child: NameDeviceWizard(deviceId: deviceId),
                      ),
                    );
                  }

                  // Handle other routes that might need query parameters here
                  return null; // Let the routes table handle other routes
                },
                routes: {
                  '/': (context) {
                    return FutureBuilder<bool>(
                      future: _checkIfAccountExists(context),
                      builder:
                          (BuildContext context, AsyncSnapshot<bool> snapshot) {
                        if (snapshot.hasData && snapshot.data!) {
                          return const LaunchPageLogin();
                        } else {
                          return const FirstLaunchPage();
                        }
                      },
                    );
                  },
                  '/provision': (context) => const ProvisionNavigator(),
                  '/index': (context) => const TabNavigator(),
                  '/post_setup': (context) => const PostSetupWizard()
                },
                supportedLocales: const [Locale('en'), Locale('fr')],
                localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme:
                      ColorScheme.fromSeed(seedColor: const Color(0xff206b8b)),
                  primaryColor: const Color(0xff206b8b),
                  secondaryHeaderColor: const Color(0xFFBFD2DB),
                  fontFamily: 'Poppins',
                  textTheme: TextTheme(
                    titleSmall: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16.h,
                    ),
                    titleMedium: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 20.h,
                    ),
                    titleLarge: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 24.h,
                    ),
                    labelSmall: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16.h,
                        fontWeight: FontWeight.w600),
                    labelMedium: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18.h,
                        fontWeight: FontWeight.w600),
                    labelLarge: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20.h,
                        fontWeight: FontWeight.w600),
                    displaySmall: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16.h,
                        fontWeight: FontWeight.w500),
                    displayMedium: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20.h,
                        fontWeight: FontWeight.w500),
                    displayLarge: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32.h,
                        fontWeight: FontWeight.w500),
                    bodySmall: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.h,
                        fontWeight: FontWeight.w400),
                    bodyMedium: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16.h,
                        fontWeight: FontWeight.w400),
                    bodyLarge: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20.h,
                        fontWeight: FontWeight.w400),
                  ),
                ),
                navigatorObservers: [routeObserver],
              ),
            )),
      ),
    );
  }

  Future<bool> _checkIfAccountExists(BuildContext context) async {
    CredentialManager cred = CredentialManager();
    return await cred.hasAccount();
  }
}
