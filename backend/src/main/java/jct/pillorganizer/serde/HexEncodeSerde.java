package jct.pillorganizer.serde;

import io.micronaut.core.annotation.Order;
import io.micronaut.core.type.Argument;
import io.micronaut.serde.Decoder;
import io.micronaut.serde.Encoder;
import io.micronaut.serde.Serde;
import jakarta.inject.Singleton;

import java.io.IOException;
import java.util.HexFormat;

/**
 * Serializes a byte array into a hex string.
 */
@Singleton
@Order(value = -100)
public class HexEncodeSerde implements Serde<byte[]> {
    @Override
    public byte[] deserialize(Decoder decoder, DecoderContext context, Argument<? super byte[]> type) throws IOException {
        return HexFormat.of().parseHex(decoder.decodeString());
    }

    @Override
    public void serialize(Encoder encoder, EncoderContext context, Argument<? extends byte[]> type, byte[] value) throws IOException {
        encoder.encodeString(HexFormat.of().formatHex(value));
    }
}
