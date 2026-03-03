import 'package:freezed_annotation/freezed_annotation.dart';

part 'assign_device_dto.freezed.dart';
part 'assign_device_dto.g.dart';

@freezed
abstract class AssignDeviceDto with _$AssignDeviceDto {
  const AssignDeviceDto._();

  const factory AssignDeviceDto({
    required String deviceId,
    String? logicalId,
  }) = _AssignDeviceDto;

  factory AssignDeviceDto.fromJson(Map<String, dynamic> json) =>
      _$AssignDeviceDtoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AssignDeviceDtoToJson(this as _AssignDeviceDto);
}
