import 'package:app/api/backend_provisioning_api.dart';
import 'package:app/service/amplify_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class BackendProvisioningService {
  final AmplifyService _amplifyService;
  final BackendProvisioningApi _api;

  BackendProvisioningService(this._amplifyService, Dio dio)
      : _api = BackendProvisioningApi(dio);

  /// Calls /device/claim to get claimId and claimToken for the device.
  /// Retries up to 3 times on transient 5xx errors (e.g. Lambda cold starts).
  Future<ClaimResult?> claimDevice(String serialNumber) async {
    const maxAttempts = 3;
    const retryDelays = [Duration(seconds: 1), Duration(seconds: 2)];

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        debugPrint('BackendProvisioningService: Claim attempt $attempt/$maxAttempts for $serialNumber');

        // Get ID Token from Amplify (matches Python script's IdToken usage)
        final idToken = await _amplifyService.getIdToken();
        if (idToken == null) {
          debugPrint('BackendProvisioningService: Failed to get ID token');
          return null;
        }

        print('DEBUG: [BACKEND] Calling /device/claim for $serialNumber (attempt $attempt)...');
        final claimResponse = await _api.claimDevice(
          ClaimRequest(serialNumber: serialNumber),
          'Bearer $idToken',
        );

        print('DEBUG: [BACKEND] Claim successful!');
        print('DEBUG: [BACKEND]   DeviceId:   ${claimResponse.deviceId}');
        print('DEBUG: [BACKEND]   ClaimId:    ${claimResponse.claimId}');
        print('DEBUG: [BACKEND]   ClaimToken: ${claimResponse.claimToken}');

        return ClaimResult(
          deviceId: claimResponse.deviceId,
          claimId: claimResponse.claimId,
          claimToken: claimResponse.claimToken,
        );
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        debugPrint('BackendProvisioningService: Attempt $attempt failed. Status: $status, Data: ${e.response?.data}');
        print('DEBUG: [BACKEND] Error Response: ${e.response?.data}');

        // Only retry on 5xx (transient server errors), not 4xx (client errors)
        final isServerError = status != null && status >= 500;
        if (isServerError && attempt < maxAttempts) {
          final delay = retryDelays[attempt - 1];
          debugPrint('BackendProvisioningService: Retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
          continue;
        }

        debugPrint('BackendProvisioningService: Giving up after $attempt attempt(s).');
        return null;
      } catch (e) {
        debugPrint('BackendProvisioningService: Unexpected error during claim: $e');
        return null;
      }
    }
    return null;
  }
}

/// Result from /device/claim — only what the app needs.
/// The device firmware handles claim_cert and fleet provisioning on its own.
class ClaimResult {
  final String deviceId;
  final String claimId;
  final String claimToken;

  ClaimResult({
    required this.deviceId,
    required this.claimId,
    required this.claimToken,
  });
}
