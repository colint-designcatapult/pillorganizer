import 'dart:async';

import 'package:app_links/app_links.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  Function(String patientId)? _onPatientDeepLink;

  void initialize() {
    _appLinks = AppLinks();
    _initializeAppLinks();
  }

  void setPatientDeepLinkHandler(Function(String patientId) handler) {
    _onPatientDeepLink = handler;
  }

  void _initializeAppLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleIncomingLink(uri);
      },
      onError: (err, stackTrace) {
        print('Deep link error: $err');
        print('Stack trace: $stackTrace');
      },
    );
  }

  Future<Uri?> getInitialLink() async {
    try {
      return await _appLinks.getInitialAppLink();
    } catch (e) {
      print('Error getting initial app link: $e');
      return null;
    }
  }

  void _handleIncomingLink(Uri uri) {
    print('Received deep link: $uri');

    String? patientId = uri.queryParameters['patientId'];

    if (patientId != null && patientId.isNotEmpty) {
      print('Patient ID found in deep link: $patientId');

      if (_onPatientDeepLink != null) {
        _onPatientDeepLink!(patientId);
      }
    } else {
      print('No patientId found in deep link');
    }
  }

  bool isPatientDeepLink(Uri uri) {
    return uri.scheme == 'cabinet' &&
        uri.host == 'patient' &&
        uri.queryParameters.containsKey('patientId');
  }

  String? extractPatientId(Uri uri) {
    return uri.queryParameters['patientId'];
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
