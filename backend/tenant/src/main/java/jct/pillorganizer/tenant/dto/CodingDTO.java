package jct.pillorganizer.tenant.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Introspected
@Serdeable
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CodingDTO {
    private String system;
    private String code;
    private String display;
    private String version;
    private Boolean userSelected;
} 