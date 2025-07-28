package jct.pillorganizer.dto;

import java.util.List;

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
public class LanguageDTO {
    private List<LanguageCodingDTO> coding;
} 