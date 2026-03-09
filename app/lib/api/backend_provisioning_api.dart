import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';

part 'backend_provisioning_api.g.dart';

@RestApi(baseUrl: "https://control-plane.app.healthesolutions.ca")
abstract class BackendProvisioningApi {
  factory BackendProvisioningApi(Dio dio, {String baseUrl}) = _BackendProvisioningApi;

  @POST("/device/claim")
  Future<ClaimResponse> claimDevice(
    @Body() ClaimRequest request,
    @Header("Authorization") String token,
  );
}

@JsonSerializable()
class ClaimRequest {
  final String serialNumber;

  ClaimRequest({required this.serialNumber});

  Map<String, dynamic> toJson() => _$ClaimRequestToJson(this);
}

@JsonSerializable()
class ClaimResponse {
  final String claimId;
  final String claimToken;
  final String deviceId;

  ClaimResponse({
    required this.claimId,
    required this.claimToken,
    required this.deviceId,
  });

  factory ClaimResponse.fromJson(Map<String, dynamic> json) => _$ClaimResponseFromJson(json);
}
