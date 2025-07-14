package jct.pillorganizer.dto;

import java.util.List;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

enum FhirPatientGender
{
    male, female, other, unknown
}

@Data
@NoArgsConstructor
@AllArgsConstructor
@Introspected
@Serdeable
public class FhirPatientDto {
    private String id;
    private FhirMetaDto meta;
    private String resourceType;
    private List<LocalAccountIdentifierDto> identifier;
    private List<LocalAccountHumanDto> name;
    private List<LocalAccountTelecomDto> telecom;
    private List<LocalAccountAddressDto> address;
    private Boolean active;
    private List<PatientCommunicationDto> communication;
    private FhirPatientGender gender;
    private String birthDate;
    private List<LocalAccountExtensionDto> extension;
    private List<PatientGeneralPractitionerReferenceDto> generalPractitioner;
    private List<PatientContactDto> contact;
} 