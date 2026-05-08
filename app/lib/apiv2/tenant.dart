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

  @GET("/api/v1/device/default-schedule")
  Future<BaseScheduleDto> getDefaultSchedule();
}
