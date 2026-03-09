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
  /// The app's only backend responsibility — everything else is firmware.
  Future<ClaimResult?> claimDevice(String serialNumber) async {
    try {
      debugPrint('BackendProvisioningService: Starting claim for $serialNumber');

      // 1. Get ID Token from Amplify (matches Python script's IdToken usage)
      final idToken = await _amplifyService.getIdToken();
      if (idToken == null) {
        debugPrint('BackendProvisioningService: Failed to get ID token');
        return null;
      }
      debugPrint('BackendProvisioningService: ID token obtained');

      // 2. Call /device/claim
      print('DEBUG: [BACKEND] Calling /device/claim for $serialNumber...');
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
    } catch (e) {
      if (e is DioException) {
        debugPrint('BackendProvisioningService: Dio error status: ${e.response?.statusCode}');
        debugPrint('BackendProvisioningService: Dio error data: ${e.response?.data}');
        print('DEBUG: [BACKEND] Error Response: ${e.response?.data}');
      }
      debugPrint('BackendProvisioningService: Error during claim: $e');
      return null;
    }
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
