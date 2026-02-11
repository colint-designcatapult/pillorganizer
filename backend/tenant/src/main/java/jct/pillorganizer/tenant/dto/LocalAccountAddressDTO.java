package jct.pillorganizer.tenant.dto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonProperty;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

enum LocalAccountAddressUse
{
    home, work, temp, old, billing
}

enum LocalAccountAddressType
{
    postal, physical, both
}

@Data
@NoArgsConstructor
@AllArgsConstructor
@Introspected
@Serdeable
public class LocalAccountAddressDTO {
    private String id;
    private Map<String, Object> period;
    
    @JsonProperty("deleted_at")
    private LocalDateTime deletedAt;
    
    private LocalAccountAddressUse use;
    private LocalAccountAddressType type;
    private String text;
    private List<String> line;
    private String city;
    private String district;
    private String state;
    private String postalCode;
    private String country;
} 