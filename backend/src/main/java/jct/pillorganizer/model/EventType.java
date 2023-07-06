package jct.pillorganizer.model;


import jct.pillorganizer.proto.Pill;

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


    /**
     * Convert from an EventType as described in the protocol buffers to this enumeration
     * @param eventType a protobuf EventType
     * @return a Java EventType
     */
    public static EventType fromProtobuf(Pill.RecordedEvent.EventType eventType) {
        return switch (eventType) {
            case OPENED -> EventType.OPENED;
            case CLOSED -> EventType.CLOSED;
            case MISSED -> EventType.MISSED;
            default -> throw new IllegalArgumentException("invalid event type");
        };
    }

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
