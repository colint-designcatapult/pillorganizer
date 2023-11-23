package jct.pillorganizer.exceptions;

public class DeviceProvisionExpiredException extends RuntimeException {
    public DeviceProvisionExpiredException(String message) {
        super(message);
    }
}
