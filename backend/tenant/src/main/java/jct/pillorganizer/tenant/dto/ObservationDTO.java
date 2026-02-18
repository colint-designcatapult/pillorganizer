package jct.pillorganizer.tenant.dto;

import java.time.Instant;
import java.util.List;
import java.util.Map;

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
public class ObservationDTO {
    private String resourceType;
    private String id;
    private String status;
    private List<String> category;
    private ReferenceDTO subject;
    private String effectiveDateTime;
    private Instant issued;
    private String performer;
    private String device;
    private ValueQuantityDTO valueQuantity;
    private Map<String, Object> valueCodeableConcept;
    private String valueString;
    private Boolean valueBoolean;
    private Integer valueInteger;
    private String valueDateTime;
    private AttachmentDTO valueAttachment;
    private Map<String, Object> valuePeriod;
    private List<Map<String, Object>> component;
    private List<ReferenceDTO> hasMember;
    private List<ReferenceDTO> derivedFrom;
    private CodeDTO code;
    private String valueTime;
}
