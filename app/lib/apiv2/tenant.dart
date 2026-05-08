import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:app/apiv2/models/dto.dart';

part 'tenant.g.dart';

@RestApi(
  parser: Parser.DartMappable,
)
abstract class TenantApiClient {
  factory TenantApiClient(Dio dio, {String baseUrl}) = _TenantApiClient;

  @GET("/api/v1/device/list")
  Future<List<DeviceAccessDto>> listDevices();

  @GET("/api/v1/device/{id}/schedule")
  Future<DeviceScheduleStateDto> getSchedule(@Path("id") String deviceId);

  @POST("/api/v1/device/{id}/schedule")
  Future<DeviceScheduleStateDto> setSchedule(
      @Path("id") String deviceId,
      @Body() SetScheduleRequestDto request);

  @POST("/api/v1/device/{id}/nickname")
  Future<DeviceAccessDto> updateDeviceNickname(
      @Path("id") String deviceId,
      @Body() UpdateDeviceSettingsDto request);

  @GET("/api/v1/device/{id}/adherencehistory")
  Future<List<DoseHistoryDto>> getAdherenceHistory(
      @Path("id") String deviceId,
      {@Query("year") required int year,
       @Query("month") required int month});

  @POST("/api/v1/device/{id}/command")
  Future<void> sendCommand(
      @Path("id") String deviceId,
      @Body() DeviceCommandDto command);

  @POST("/api/v1/caregiver/generate/{deviceId}")
  Future<DeviceCaregiverCodeDto> generateCaregiverCode(
      @Path("deviceId") String deviceId,
      @Body() GenerateCaregiverCodeDto dto);

  @GET("/api/v1/caregiver/codes")
  Future<List<DeviceCaregiverCodeDto>> getShareCodes(
      @Query("deviceIds") List<String> deviceIds);

  @POST("/api/v1/caregiver/validate/{code}")
  Future<CaregiverCodeValidationDto> validateCaregiverCode(
      @Path("code") String code);

  @POST("/api/v1/caregiver/revoke/{caregiverId}")
  Future<void> revokeCaregiverAccess(
      @Path("caregiverId") String caregiverId);

  @GET("/api/v1/caregiver/list/{deviceId}")
  Future<List<CaregiverListItemDto>> listCaregivers(
      @Path("deviceId") String deviceId);

  @POST("/api/v1/caregiver/transfer/{deviceId}")
  Future<void> transferPrimaryUser(
      @Path("deviceId") String deviceId,
      @Body() TransferPrimaryUserDto dto);

  @PUT("/api/v1/device/{id}/notification-preferences")
  Future<DeviceAccessDto> updateNotificationPreferences(
      @Path("id") String deviceId,
      @Body() NotificationPreferencesRequestDto dto);
}
