package jct.pillorganizer.tenant.dto;

import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonProperty;

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
public class PatientCommunicationDTO {
    private String id;
    private LanguageDTO language;
    
    @JsonProperty("deleted_at")
    private LocalDateTime deletedAt;
    
    private Boolean preferred;
} 