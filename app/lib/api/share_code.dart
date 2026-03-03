import 'package:app/api/api.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'share_code.freezed.dart';

@freezed
abstract class ShareCode extends Equatable with _$ShareCode {
  const ShareCode._();

  const factory ShareCode({
    required int deviceId,
    required String code,
    required DateTime expiresAt,
  }) = _ShareCode;

  factory ShareCode.fromDTO(DeviceCaregiverCodeDTO dto) {
    return ShareCode(
      deviceId: dto.deviceID,
      code: dto.code.toString(),
      expiresAt:
          DateTime.fromMillisecondsSinceEpoch(dto.expiresAt, isUtc: true),
    );
  }

  bool get isValid {
    return DateTime.now().isBefore(expiresAt);
  }

  int get remainingSeconds {
    if (!isValid) return 0;
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  @override
  List<Object?> get props => [deviceId, code, expiresAt];
}
