package jct.pillorganizer.dto;

import java.time.LocalDateTime;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonProperty;

import io.micronaut.core.annotation.Introspected;
import io.micronaut.serde.annotation.Serdeable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;


enum LocalAccountTelecomSystem
{
    phone, email, fax, pager, url, sms, other
}

enum LocalAccountTelecomUse
{
    home, work, temp, old, mobile
}

@Data
@NoArgsConstructor
@AllArgsConstructor
@Introspected
@Serdeable
public class LocalAccountTelecomDto {
    private String id;
    private Map<String, Object> period;
    
    @JsonProperty("deleted_at")
    private LocalDateTime deletedAt;
    
    private LocalAccountTelecomSystem system;
    private String value;
    private LocalAccountTelecomUse use;
    private Integer rank;
} 