import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/api/intreceptors/auth-interceptors.dart';
import 'package:retrofit/retrofit.dart';
import 'package:app/apiv2/models/device_access_dto.dart';
import 'package:app/apiv2/models/provisioning_claim_dto.dart';

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


@RestApi()
abstract class ControlPlaneApiClient {
  factory ControlPlaneApiClient(Dio dio) = _ControlPlaneApiClient;

  @GET("/user/devices")
  Future<List<DeviceAccessDto>> getDevices();

  @GET("/device/claim/{serialNo}")
  Future<ProvisioningClaimDto> getProvisioningClaim(@Path("serialNo") String serialNo);
}