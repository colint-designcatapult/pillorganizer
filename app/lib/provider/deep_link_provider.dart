import 'package:flutter/foundation.dart';

class DeepLinkProvider extends ChangeNotifier {
  String? _patientId;
  bool _hasInitialDeepLink = false;

  String? get patientId => _patientId;
  bool get hasInitialDeepLink => _hasInitialDeepLink;

  void setPatientId(String? patientId) {
    if (_patientId != patientId) {
      _patientId = patientId;
      _hasInitialDeepLink = patientId != null;
      notifyListeners();
    }
  }

  void clearPatientId() {
    if (_patientId != null) {
      _patientId = null;
      _hasInitialDeepLink = false;
      notifyListeners();
    }
  }

  bool get hasPatientId => _patientId != null && _patientId!.isNotEmpty;

  void markDeepLinkProcessed() {
    if (_hasInitialDeepLink) {
      _hasInitialDeepLink = false;
      notifyListeners();
    }
  }
}
