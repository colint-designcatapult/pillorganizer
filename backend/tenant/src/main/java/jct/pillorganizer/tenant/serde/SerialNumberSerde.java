package jct.pillorganizer.tenant.serde;

import io.micronaut.core.annotation.Order;
import io.micronaut.core.type.Argument;
import io.micronaut.serde.Decoder;
import io.micronaut.serde.Encoder;
import io.micronaut.serde.Serde;
import jakarta.inject.Singleton;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.HexFormat;

/**
 * Serializes a serial number (internally stored as a long) into a hex string. A serial number is 6 bytes and a long
 * is 8 bytes, so the long is truncated.
 */
@Order(value = -100)
public class SerialNumberSerde implements Serde<Long> {

    @Override
    public Long deserialize(Decoder decoder, DecoderContext context, Argument<? super Long> type) throws IOException {
        ByteBuffer bb = ByteBuffer.allocate(8);
        byte[] dec = HexFormat.of().parseHex(decoder.decodeString());
        if(dec.length != 6)
            throw new IllegalArgumentException("Invalid serial number");
        bb.order(ByteOrder.BIG_ENDIAN)
                .putShort((short)0)
                .put(dec);
        return bb.rewind().getLong();
    }

    @Override
    public void serialize(Encoder encoder, EncoderContext context, Argument<? extends Long> type, Long value) throws IOException {
        byte[] out = new byte[6];
        ByteBuffer.allocate(8)
                .order(ByteOrder.BIG_ENDIAN)
                .putLong(value)
                .rewind()
                .get(2, out);
        encoder.encodeString(HexFormat.of().formatHex(out));
    }
}
