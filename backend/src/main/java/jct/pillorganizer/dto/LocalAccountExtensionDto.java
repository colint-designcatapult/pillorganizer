package jct.pillorganizer.dto;

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
public class LocalAccountExtensionDto {
    private String id;
    
    @JsonProperty("polymorphic_ctype")
    private Integer polymorphicCtype;
    
    private String account;
} 