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

}
