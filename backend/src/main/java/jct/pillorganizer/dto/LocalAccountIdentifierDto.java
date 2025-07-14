package jct.pillorganizer.dto;

import java.util.Map;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

enum LocalAccountIdentifierUse
{
    usual, official, temp, secondary, old
}

@Data
@NoArgsConstructor
@AllArgsConstructor
@Introspected
@Serdeable
public class LocalAccountIdentifierDto {
    private String id;
    private String value;
    private LocalAccountIdentifierUse use;
    private Object type;
    private String system;
    private Map<String, Object> period;
    private LocalAccountIdentifierAssignerReferenceDto assigner;
} 