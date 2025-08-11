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
      onError: (err) {
        print('Error in deep link service: $err');
      },
    );
  }

  Future<Uri?> getInitialLink() async {
    try {
      return await _appLinks.getInitialAppLink();
    } catch (e) {
      return null;
    }
  }

  void _handleIncomingLink(Uri uri) {
    String? patientId = uri.queryParameters['patientId'];

    if (patientId != null && patientId.isNotEmpty) {
      if (_onPatientDeepLink != null) {
        _onPatientDeepLink!(patientId);
      }
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
