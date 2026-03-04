import 'package:freezed_annotation/freezed_annotation.dart';

part 'provisioning_claim_dto.freezed.dart';
part 'provisioning_claim_dto.g.dart';

@freezed
abstract class ProvisioningClaimDto with _$ProvisioningClaimDto {
  const ProvisioningClaimDto._();

  const factory ProvisioningClaimDto({
    required String claimId,
    required String tenantId,
    required String tenantApiBase,
  }) = _ProvisioningClaimDto;

  factory ProvisioningClaimDto.fromJson(Map<String, dynamic> json) =>
      _$ProvisioningClaimDtoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ProvisioningClaimDtoToJson(this as _ProvisioningClaimDto);
}
