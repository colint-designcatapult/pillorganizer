package jct.pillorganizer.model.device;

/**
 * Describes the "type" of pill organizer a device is. There is presently only a single pill organizer model. This enum
 * is to possibly support multiple models in the future, possibly with wildly different bin configurations.
 */
public enum DeviceClass {
    v1_7x2(14);

    private final int binCount;

    DeviceClass(int binCount) {
        this.binCount = binCount;
    }

    public int getBinCount() {
        return binCount;
    }
}
