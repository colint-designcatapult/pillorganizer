import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:app/apiv2/models/device_access_dto.dart';
import 'package:app/apiv2/models/physical_device_dto.dart';
import 'package:app/apiv2/models/logical_device_dto.dart';
import 'package:app/apiv2/models/assign_device_dto.dart';

part 'tenant.g.dart';

@RestApi()
abstract class TenantApiClient {
  factory TenantApiClient(Dio dio, {String baseUrl}) = _TenantApiClient;

  @GET("/api/v1/device/list")
  Future<List<DeviceAccessDto>> listDevices();

  @POST("/api/v1/device/check")
  @FormUrlEncoded()
  Future<PhysicalDeviceDto> checkDevice(@Field("claimToken") String claimToken);

  @POST("/api/v1/device/assign")
  Future<LogicalDeviceDto> assignDevice(@Body() AssignDeviceDto request);
}
