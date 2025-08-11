import 'package:app/navigation/provision_navigator.dart';
import 'package:app/navigation/tab_navigator.dart';
import 'package:app/provider/ble_provider.dart';
import 'package:app/provider/caregiver_provider.dart';
import 'package:app/provider/device_provider.dart';
import 'package:app/provider/medication_provider.dart';
import 'package:app/provider/provision_provider.dart';
import 'package:app/provider/time_provider.dart';
import 'package:app/provider/user_registration_provider.dart';
import 'package:app/screens/ScreenUtilWrapper.dart';
import 'package:app/screens/auth/register.dart';
import 'package:app/screens/first_launch.dart';
import 'package:app/screens/name_device_wizard.dart';
import 'package:app/screens/post_setup_wizard.dart';
import 'package:app/service/credential_manager.dart';
import 'package:app/service/deep_link_service.dart';
import 'package:app/service/notification_service.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'firebase_options.dart';
import 'provider/authentication_provider.dart';
import 'provider/deep_link_provider.dart';
import 'provider/language_provider.dart';
import 'provider/schedule_provider.dart';
import 'provider/selected_device_provider.dart';
import 'screens/auth/launch_page_login.dart';
import 'screens/auth/patient_confirmation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    name: 'Cabinet',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Handle the background message with translation
  await BackgroundNotificationTranslator.handleBackgroundMessage(message);
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

  DeepLinkService().initialize();

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
          ChangeNotifierProvider(
            create: (context) => DeepLinkProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => LanguageProvider(),
          ),
          ChangeNotifierProvider<UserRegistrationProvider>(
              create: (_) => UserRegistrationProvider()),
          ChangeNotifierProvider<DeviceProvider>(
              create: (_) => DeviceProvider()),
          ChangeNotifierProxyProvider<DeviceProvider, SelectedDeviceProvider>(
            create: (context) => SelectedDeviceProvider(),
            update: (context, deviceProv, selectedProv) =>
                selectedProv!.update(deviceProv.devices),
          ),
          ChangeNotifierProxyProvider<SelectedDeviceProvider,
                  MedicationsProvider>(
              create: (context) => MedicationsProvider(
                  Provider.of<SelectedDeviceProvider>(context, listen: false)
                      .device),
              update: (context, device, old) => old!.update(device.device)),
          ChangeNotifierProxyProvider<SelectedDeviceProvider, ScheduleProvider>(
              create: (context) => ScheduleProvider(),
              update: (context, selectedDevice, prov) =>
                  prov!.update(selectedDevice.device)),
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
        child: DeepLinkWrapper(
          child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: 1.0,
              ),
              child: PlatformProvider(
                settings: PlatformSettingsData(iosUsesMaterialWidgets: true),
                builder: (context) =>
                    Consumer2<DeepLinkProvider, LanguageProvider>(
                  builder:
                      (context, deepLinkProvider, languageProvider, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        MaterialApp(
                          title: 'Cabinet Pills',
                          themeMode: ThemeMode.system,
                          locale: languageProvider.locale,
                          onGenerateRoute: (settings) {
                            if (settings.name?.startsWith('/name_new_device') ==
                                true) {
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
                              return const AppInitializer();
                            },
                            '/provision': (context) =>
                                const ProvisionNavigator(),
                            '/index': (context) => const TabNavigator(),
                            '/post_setup': (context) => const PostSetupWizard(),
                            '/register': (context) => const RegisterPage(),
                            '/patient_confirmation': (context) =>
                                const PatientConfirmationPage()
                          },
                          supportedLocales: const [Locale('en'), Locale('fr')],
                          localizationsDelegates: const <LocalizationsDelegate<
                              dynamic>>[
                            AppLocalizations.delegate,
                            GlobalMaterialLocalizations.delegate,
                            GlobalWidgetsLocalizations.delegate,
                            GlobalCupertinoLocalizations.delegate,
                          ],
                          debugShowCheckedModeBanner: false,
                          theme: ThemeData(
                            useMaterial3: true,
                            colorScheme: ColorScheme.fromSeed(
                                seedColor: const Color(0xff206b8b)),
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
                      ],
                    );
                  },
                ),
              )),
        ),
      ),
    );
  }
}

class DeepLinkWrapper extends StatefulWidget {
  final Widget child;

  const DeepLinkWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<DeepLinkWrapper> createState() => _DeepLinkWrapperState();
}

class _DeepLinkWrapperState extends State<DeepLinkWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
  }

  void _initializeDeepLinks() {
    final deepLinkService = DeepLinkService();

    deepLinkService.setPatientDeepLinkHandler((String patientId) {
      _handlePatientDeepLink(patientId);
    });

    _checkInitialDeepLink();
  }

  void _checkInitialDeepLink() async {
    final deepLinkService = DeepLinkService();
    final initialLink = await deepLinkService.getInitialLink();

    if (initialLink != null && deepLinkService.isPatientDeepLink(initialLink)) {
      final patientId = deepLinkService.extractPatientId(initialLink);
      if (patientId != null) {
        _handlePatientDeepLink(patientId);
      }
    }
  }

  void _handlePatientDeepLink(String patientId) {
    final deepLinkProvider =
        Provider.of<DeepLinkProvider>(context, listen: false);

    deepLinkProvider.setPatientId(patientId, shouldAutoValidate: false);
    deepLinkProvider.setPendingNavigation(true);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class KeyboardDismissWrapper extends StatelessWidget {
  final Widget child;

  const KeyboardDismissWrapper({Key? key, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // Close keyboard when tapping outside input fields
        FocusScope.of(context).unfocus();
      },
      child: child,
    );
  }
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkIfAccountExists(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!) {
            return const LaunchPageLogin();
          } else {
            return const FirstLaunchPage();
          }
        } else {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  Future<bool> _checkIfAccountExists() async {
    final prefs = await SharedPreferences.getInstance();
    CredentialManager cred = CredentialManager();

    if (prefs.getBool('first_run') ?? true) {
      await cred.cleanCredentials();
      prefs.setBool('first_run', false);
    }

    return await cred.hasAccount();
  }
}
