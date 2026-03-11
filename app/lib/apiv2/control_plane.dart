
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
}