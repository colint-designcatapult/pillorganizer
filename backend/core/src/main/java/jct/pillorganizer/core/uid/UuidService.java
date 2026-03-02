package jct.pillorganizer.core.uid;

import com.fasterxml.uuid.Generators;
import jakarta.inject.Singleton;

import java.util.UUID;

@Singleton
public class UuidService {

    public UUID generateUuid() {
        // UUID v7
        return Generators.timeBasedEpochGenerator().generate();
    }

}
