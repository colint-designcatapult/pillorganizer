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


enum LocalAccountHumanUse
{
    usual, official, temp, nickname, anonymous, old, maiden
}

@Data
@NoArgsConstructor
@AllArgsConstructor
@Introspected
@Serdeable
public class LocalAccountHumanDTO {
    private String id;
    private Map<String, Object> period;
    
    @JsonProperty("deleted_at")
    private LocalDateTime deletedAt;
    
    private LocalAccountHumanUse use;
    private String family;
    private List<String> given;
    private List<String> prefix;
    private List<String> suffix;
} 