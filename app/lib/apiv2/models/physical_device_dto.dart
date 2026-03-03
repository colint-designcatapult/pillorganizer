import 'package:freezed_annotation/freezed_annotation.dart';

part 'physical_device_dto.freezed.dart';
part 'physical_device_dto.g.dart';

@freezed
abstract class PhysicalDeviceDto with _$PhysicalDeviceDto {
  const PhysicalDeviceDto._();

  const factory PhysicalDeviceDto({
    required String deviceId,
    required String serialNo,
    required String claimToken,
    required String deviceClass,
    String? disabledAt,
  }) = _PhysicalDeviceDto;

  factory PhysicalDeviceDto.fromJson(Map<String, dynamic> json) =>
      _$PhysicalDeviceDtoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$PhysicalDeviceDtoToJson(this as _PhysicalDeviceDto);
}
