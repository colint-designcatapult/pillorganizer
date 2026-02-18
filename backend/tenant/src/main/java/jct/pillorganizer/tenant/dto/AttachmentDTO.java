package jct.pillorganizer.tenant.dto;

import java.time.Instant;

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
public class AttachmentDTO {
    private String id;
    private String contentType;
    private String title;
    private String language;
    private Instant creation;
}
