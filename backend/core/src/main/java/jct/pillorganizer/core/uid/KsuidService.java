package jct.pillorganizer.core.uid;

import com.github.ksuid.Ksuid;
import jakarta.inject.Singleton;

@Singleton
public class KsuidService {

    public String generateKsuid() {
        return Ksuid.newKsuid().toString();
    }

    public String toString(byte[] ksuid) {
        return Ksuid.newBuilder().withKsuidBytes(ksuid).build().toString();
    }

    public byte[] toBytes(String encoded) {
        return Ksuid.fromString(encoded).asBytes();
    }

}
