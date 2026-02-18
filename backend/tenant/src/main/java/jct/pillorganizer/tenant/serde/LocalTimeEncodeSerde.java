package jct.pillorganizer.tenant.serde;

import io.micronaut.core.annotation.Order;
import io.micronaut.core.type.Argument;
import io.micronaut.serde.Decoder;
import io.micronaut.serde.Encoder;
import io.micronaut.serde.Serde;
import jakarta.inject.Singleton;

import java.io.IOException;
import java.time.LocalTime;

/**
 * Serializes a LocalTime into day-epoch format.
 */
@Singleton
@Order(value = -100)
public class LocalTimeEncodeSerde implements Serde<LocalTime> {
    @Override
    public LocalTime deserialize(Decoder decoder, DecoderContext context, Argument<? super LocalTime> type) throws IOException {
        return LocalTime.MIDNIGHT.plusSeconds(decoder.decodeInt());
    }

    @Override
    public void serialize(Encoder encoder, EncoderContext context, Argument<? extends LocalTime> type, LocalTime value) throws IOException {
        encoder.encodeInt(value.getSecond() + value.getMinute() * 60 + value.getHour() * 3600);
    }
}
