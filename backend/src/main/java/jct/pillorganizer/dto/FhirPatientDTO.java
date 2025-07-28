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
public class FhirPatientDTO {
    private String id;
    private FhirMetaDTO meta;
    private String resourceType;
    private List<LocalAccountIdentifierDTO> identifier;
    private List<LocalAccountHumanDTO> name;
    private List<LocalAccountTelecomDTO> telecom;
    private List<LocalAccountAddressDTO> address;
    private Boolean active;
    private List<PatientCommunicationDTO> communication;
    private FhirPatientGender gender;
    private String birthDate;
    private List<LocalAccountExtensionDTO> extension;
    private List<PatientGeneralPractitionerReferenceDTO> generalPractitioner;
    private List<PatientContactDTO> contact;
} 