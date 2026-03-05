import 'package:json_annotation/json_annotation.dart';

part 'device_access_dto.g.dart';

@JsonSerializable()
class DeviceAccessDto {
  final String id;
  final String deviceId;
  final String nickname;
  final String serialNo;
  final String modelId;
  final String tenantId;
  final String apiBase;
  final bool primaryUser;
  final String thingName;

  DeviceAccessDto({
    required this.id,
    required this.deviceId,
    required this.nickname,
    required this.serialNo,
    required this.modelId,
    required this.tenantId,
    required this.apiBase,
    required this.primaryUser,
    required this.thingName
  });

  factory DeviceAccessDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceAccessDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceAccessDtoToJson(this);
}
