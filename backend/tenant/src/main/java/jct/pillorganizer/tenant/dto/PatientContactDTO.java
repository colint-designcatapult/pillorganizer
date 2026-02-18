package jct.pillorganizer.tenant.dto;

import java.util.List;
import java.util.Map;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Introspected
@Serdeable
public class PatientContactDTO {
    private String id;
    private String patient;
    private List<Object> relationship;
    private LocalAccountHumanDTO name;
    private List<LocalAccountTelecomDTO> telecom;
    private LocalAccountAddressDTO address;
    private PatientGeneralPractitionerReferenceDTO organization;
    private Map<String, Object> period;
    private String gender;
} 