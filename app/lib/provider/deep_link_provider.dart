import 'package:app/api/api.dart';
import 'package:flutter/foundation.dart';

class DeepLinkProvider extends ChangeNotifier {
  String? _patientId;
  bool _isValidating = false;
  bool _pendingNavigation = false;

  String? get patientId => _patientId;
  bool get hasPatientId => _patientId != null && _patientId!.isNotEmpty;
  bool get isValidating => _isValidating;
  bool get hasPendingNavigation => _pendingNavigation;

  void setPatientId(String? patientId, {bool shouldAutoValidate = false}) {
    if (_patientId != patientId) {
      _patientId = patientId;
      _pendingNavigation = patientId != null && patientId.isNotEmpty;
      notifyListeners();
    }
  }

  Future<void> validateAndLinkTakecarePatient({
    required String patientId,
    required String firstName,
    required String lastName,
    required String birthDate,
  }) async {
    _isValidating = true;
    notifyListeners();

    try {
      final validationRequest = PatientValidationRequest(
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
      );

      await client.validateAndLinkTakecarePatient(patientId, validationRequest);

      _patientId = null;
      _pendingNavigation = false;
    } catch (e) {
      rethrow;
    } finally {
      _isValidating = false;
      notifyListeners();
    }
  }

  void clearPatientId() {
    if (_patientId != null) {
      _patientId = null;
      _pendingNavigation = false;
      notifyListeners();
    }
  }

  void clearPendingNavigation() {
    if (_pendingNavigation) {
      _pendingNavigation = false;
      notifyListeners();
    }
  }

  void setPendingNavigation(bool pending) {
    if (_pendingNavigation != pending) {
      _pendingNavigation = pending;
      notifyListeners();
    }
  }
}
