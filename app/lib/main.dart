import 'package:app/navigation/tab_navigator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/screens/ScreenUtilWrapper.dart';
import 'package:app/screens/first_launch.dart';
import 'package:app/screens/name_device_wizard.dart';
import 'package:app/screens/post_setup_wizard.dart';
import 'package:app/service/amplify_service.dart';
import 'package:app/service/credential_manager.dart';
import 'package:app/service/deep_link_service.dart';
import 'package:app/service/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'provider/deep_link_provider.dart';
import 'provider/language_provider.dart';
import 'screens/auth/launch_page_login.dart';
import 'screens/auth/patient_confirmation.dart';
import 'firebase_options.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  DeepLinkService().initialize();
  await AmplifyService().configureAmplify();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initLocalNotifications();

  // Show foreground notifications on iOS (alert + sound + badge).
  // On Android this is handled by the high-importance channel.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Display a local notification whenever an FCM message arrives while the
  // app is open in the foreground (Android only — iOS uses the system UI).
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      showForegroundNotification(
        notification.title ?? 'Medication Reminder',
        notification.body ?? '',
      );
    }
  });

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilWrapper(
      child: DeepLinkWrapper(
        child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: Consumer(
              builder: (context, ref, child) {
                final languageLocale = ref.watch(languageProvider);
                
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    MaterialApp(
                      title: 'Cabinet Pills',
                      themeMode: ThemeMode.system,
                      locale: languageLocale,
                      onGenerateRoute: (RouteSettings settings) {
                        if (settings.name?.startsWith('/name_new_device') ?? false) {
                          final uri = Uri.parse(settings.name!);
                          final deviceId = uri.queryParameters['id'];

                          return MaterialPageRoute(
                            builder: (context) => NameDeviceWizard(deviceId: deviceId),
                          );
                        }

                        if (settings.name?.startsWith('/post_setup') ?? false) {
                          final uri = Uri.parse(settings.name!);
                          final deviceId = uri.queryParameters['id'];

                          return MaterialPageRoute(
                            builder: (context) => PostSetupWizard(deviceId: deviceId),
                          );
                        }

                        // Handle other routes that might need query parameters here
                        return null; // Let the routes table handle other routes
                      },
                      routes: {
                        '/': (context) {
                          return const AppInitializer();
                        },
                        '/index': (context) => const TabNavigator(),
                        '/post_setup': (context) => const PostSetupWizard(),
                        '/patient_confirmation': (context) =>
                            const PatientConfirmationPage()
                      },
                      supportedLocales: const [Locale('en')],
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
            )),
      ),
    );
  }
}

class DeepLinkWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const DeepLinkWrapper({super.key, required this.child});

  @override
  ConsumerState<DeepLinkWrapper> createState() => _DeepLinkWrapperState();
}

class _DeepLinkWrapperState extends ConsumerState<DeepLinkWrapper> {
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
    final notifier = ref.read(deepLinkProvider.notifier);
    notifier.setPatientId(patientId);
    notifier.setPendingNavigation(true);
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
