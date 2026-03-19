package jct.pillorganizer.tenant.model.schedule;

import com.fasterxml.jackson.annotation.JsonSubTypes;
import com.fasterxml.jackson.annotation.JsonTypeInfo;

/**
 * Polymorphic base for all schedule types.
 * The "type" field acts as the discriminator for future schedule variants.
 */
@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, property = "type", include = JsonTypeInfo.As.EXISTING_PROPERTY)
@JsonSubTypes({
    @JsonSubTypes.Type(value = SimpleSchedule.class, name = "SIMPLE")
})
public interface BaseSchedule {
    String getType();
}
