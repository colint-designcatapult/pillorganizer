package jct.pillorganizer.model;


/**
 * Enumeration of different event types received from pill organizers for use in our database models.
 * @deprecated should use protobuf directly
 */
public enum EventType {
    OPENED(0),
    CLOSED(1),
    MISSED(2),
    RELOAD(3);
    private final int val;

    EventType(int val) {
        this.val = val;
    }

    /**
     * Converts the event type into the firmware event type ID
     * @return firmware event type ID for this event type
     * @deprecated
     */
    public int getIntValue() {
        return this.val;
    }
}
