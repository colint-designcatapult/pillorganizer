import 'package:app/api/api.dart';
import 'package:flutter/foundation.dart';

class DeepLinkProvider extends ChangeNotifier {
  String? _patientId;
  bool _isValidating = false;
  String? _validationError;

  String? get patientId => _patientId;
  bool get hasPatientId => _patientId != null && _patientId!.isNotEmpty;
  bool get isValidating => _isValidating;
  String? get validationError => _validationError;

  void setPatientId(String? patientId) {
    if (_patientId != patientId) {
      _patientId = patientId;
      _validationError = null;
      notifyListeners();

      if (patientId != null && patientId.isNotEmpty) {
        linkTakecarePatient(patientId);
      }
    }
  }

  Future<void> linkTakecarePatient(String patientId) async {
    // deeplink: cabinet://patient?patientId=0679ac91-b803-4d1b-aafb-060dc505ab60
    _isValidating = true;
    _validationError = null;
    notifyListeners();

    try {
      await client.linkTakecarePatient(patientId);
    } catch (e) {
      _patientId = null;
      _validationError = e.toString();
    } finally {
      _isValidating = false;
      notifyListeners();
    }
  }

  void clearPatientId() {
    if (_patientId != null) {
      _patientId = null;
      _validationError = null;
      notifyListeners();
    }
  }

  void clearValidationError() {
    if (_validationError != null) {
      _validationError = null;
      notifyListeners();
    }
  }
}
