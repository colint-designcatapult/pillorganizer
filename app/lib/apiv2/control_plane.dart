
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/api/intreceptors/auth-interceptors.dart';
import 'package:retrofit/retrofit.dart';
import 'package:app/apiv2/models/dto.dart';

part 'control_plane.g.dart';

final controlPlaneDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://control-plane.app.healthesolutions.ca/',
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(JwtAuthInterceptor(dio: dio));

  return dio;
});


@RestApi(
  parser: Parser.DartMappable,
)
abstract class ControlPlaneApiClient {
  factory ControlPlaneApiClient(Dio dio) = _ControlPlaneApiClient;

  @GET("/user/devices")
  Future<UserAndDeviceAccessDto> getDevices();

  @POST("/device/claim")
  Future<ProvisioningClaimDto> getProvisioningClaim(
      @Body() ProvisioningClaimRequestDto request);

  /// Registers or refreshes the current user's FCM token as an SNS
  /// platform-application endpoint. Call on first launch and on token refresh.
  @POST("/user/fcm_token")
  Future<void> registerFcmToken(@Body() RegisterFcmTokenDto dto);

  /// Subscribes or unsubscribes the current user from push notifications
  /// for a given device. Returns the updated [DeviceAccessDto].
  @POST("/user/device/notifications")
  Future<DeviceAccessDto> updateDeviceNotifications(
      @Body() DeviceNotificationRequestDto dto);

  /// Invites a caregiver to a device by email.
  /// The control plane verifies the user exists and forwards to the tenant.
  @POST("/user/device/invite-caregiver")
  Future<void> inviteCaregiver(@Body() InviteCaregiverRequestDto dto);

  /// Returns the authenticated user's details.
  @GET("/user/me")
  Future<UserDetailsDto> getUserDetails();
}