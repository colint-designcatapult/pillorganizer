package jct.pillorganizer.serde;

import io.micronaut.core.annotation.Order;
import io.micronaut.core.type.Argument;
import io.micronaut.serde.Decoder;
import io.micronaut.serde.Encoder;
import io.micronaut.serde.Serde;
import jakarta.inject.Singleton;

import java.io.IOException;

/**
 * Serializes a char into a simple string with a single character.
 */
@Singleton
@Order(value = -100)
public class CharEncodeSerde implements Serde<Character> {

    @Override
    public Character deserialize(Decoder decoder, DecoderContext context, Argument<? super Character> type) throws IOException {
        return decoder.decodeString().charAt(0);
    }

    @Override
    public void serialize(Encoder encoder, EncoderContext context, Argument<? extends Character> type, Character value) throws IOException {
        encoder.encodeString("" + value);
    }
}
