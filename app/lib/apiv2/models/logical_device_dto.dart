import 'package:freezed_annotation/freezed_annotation.dart';
import 'physical_device_dto.dart';

part 'logical_device_dto.freezed.dart';
part 'logical_device_dto.g.dart';

@freezed
abstract class LogicalDeviceDto with _$LogicalDeviceDto {
  const LogicalDeviceDto._();

  const factory LogicalDeviceDto({
    required String id,
    PhysicalDeviceDto? physicalDevice,
    String? nickname,
  }) = _LogicalDeviceDto;

  factory LogicalDeviceDto.fromJson(Map<String, dynamic> json) =>
      _$LogicalDeviceDtoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$LogicalDeviceDtoToJson(this as _LogicalDeviceDto);
}
