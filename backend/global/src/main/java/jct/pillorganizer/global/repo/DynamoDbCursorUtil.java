package jct.pillorganizer.global.repo;

import io.micronaut.core.annotation.Nullable;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Base64;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Encodes and decodes DynamoDB {@code lastEvaluatedKey} maps as opaque, URL-safe cursor strings.
 * <p>
 * All key attributes in the DeviceControlPlane table are DynamoDB String (S) type, so this
 * utility only handles S-typed attribute values.
 */
public final class DynamoDbCursorUtil {

    private static final String FIELD_SEP = "\n";
    private static final String KV_SEP = "=";

    private DynamoDbCursorUtil() {}

    /**
     * Encodes a DynamoDB {@code lastEvaluatedKey} map into a URL-safe Base64 cursor string.
     * Returns {@code null} when {@code lastEvaluatedKey} is null or empty (end of results).
     */
    @Nullable
    public static String encode(@Nullable Map<String, AttributeValue> lastEvaluatedKey) {
        if (lastEvaluatedKey == null || lastEvaluatedKey.isEmpty()) {
            return null;
        }
        String raw = lastEvaluatedKey.entrySet().stream()
                .map(e -> e.getKey() + KV_SEP + e.getValue().s())
                .collect(Collectors.joining(FIELD_SEP));
        return Base64.getUrlEncoder().withoutPadding().encodeToString(raw.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * Decodes a cursor string back into a DynamoDB {@code exclusiveStartKey} map.
     * Returns {@code null} when the cursor is null or blank (first page).
     */
    @Nullable
    public static Map<String, AttributeValue> decode(@Nullable String cursor) {
        if (cursor == null || cursor.isBlank()) {
            return null;
        }
        String raw = new String(Base64.getUrlDecoder().decode(cursor), StandardCharsets.UTF_8);
        return Arrays.stream(raw.split(FIELD_SEP))
                .map(pair -> pair.split(KV_SEP, 2))
                .filter(parts -> parts.length == 2)
                .collect(Collectors.toMap(
                        parts -> parts[0],
                        parts -> AttributeValue.builder().s(parts[1]).build()
                ));
    }
}
