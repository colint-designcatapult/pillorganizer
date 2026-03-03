import 'package:app/api/api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deep_link_provider.g.dart';

@riverpod
class DeepLinkNotifier extends _$DeepLinkNotifier {
  @override
  DeepLinkState build() {
    return const DeepLinkState();
  }

  void setPatientId(String? patientId) {
    state = state.copyWith(
      patientId: patientId,
      pendingNavigation: patientId != null && patientId.isNotEmpty,
    );
  }

  Future<void> validateAndLinkTakecarePatient({
    required String patientId,
    required String firstName,
    required String lastName,
    required String birthDate,
  }) async {
    state = state.copyWith(isValidating: true);

    try {
      final validationRequest = PatientValidationRequest(
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
      );

      await client.validateAndLinkTakecarePatient(patientId, validationRequest);

      state = state.copyWith(
        patientId: null,
        pendingNavigation: false,
      );
    } finally {
      state = state.copyWith(isValidating: false);
    }
  }

  void clearPatientId() {
    state = state.copyWith(
      patientId: null,
      pendingNavigation: false,
    );
  }

  void setPendingNavigation(bool pending) {
    state = state.copyWith(pendingNavigation: pending);
  }
}

class DeepLinkState {
  final String? patientId;
  final bool isValidating;
  final bool pendingNavigation;

  const DeepLinkState({
    this.patientId,
    this.isValidating = false,
    this.pendingNavigation = false,
  });

  DeepLinkState copyWith({
    String? patientId,
    bool? isValidating,
    bool? pendingNavigation,
  }) {
    return DeepLinkState(
      patientId: patientId ?? this.patientId,
      isValidating: isValidating ?? this.isValidating,
      pendingNavigation: pendingNavigation ?? this.pendingNavigation,
    );
  }
}
