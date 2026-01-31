package jct.pillorganizer.model.device;

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
