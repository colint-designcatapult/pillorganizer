package jct.pillorganizer.model.device;

import jct.pillorganizer.proto.Pill;

/**
 *
 */
public enum BinStatus {
    DISABLED(0),
    TAKEN(1),
    MISSED(2),
    PENDING(3),
    TAKE_NOW(4);

    private final int val;

    /**
     * Converts a protobuf `BinStatus` into this Java enum.
     * @param st a protobuf `BinStatus`
     * @return java enum
     */
    public static BinStatus fromProtobuf(Pill.BinStatus st) {
        return switch (st.getNumber()) {
            case 0 -> DISABLED;
            case 1 -> TAKEN;
            case 2 -> MISSED;
            case 3 -> PENDING;
            case 4 -> TAKE_NOW;
            default -> throw new IllegalArgumentException("invalid status");
        };
    }

    BinStatus(int val) {
        this.val = val;
    }

    /**
     * Converts the status into an integer value compatible with how the firmware stores bin status.
     * @return the integer value of the bin status
     */
    public int getIntValue() {
        return this.val;
    }
}
