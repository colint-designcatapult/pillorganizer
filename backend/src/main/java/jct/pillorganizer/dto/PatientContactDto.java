package jct.pillorganizer.dto;

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
public class PatientContactDto {
    private String id;
    private String patient;
    private List<Object> relationship;
    private LocalAccountHumanDto name;
    private List<LocalAccountTelecomDto> telecom;
    private LocalAccountAddressDto address;
    private PatientGeneralPractitionerReferenceDto organization;
    private Map<String, Object> period;
    private String gender;
} 