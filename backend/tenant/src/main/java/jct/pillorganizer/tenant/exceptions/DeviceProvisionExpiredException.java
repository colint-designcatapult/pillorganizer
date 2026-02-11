package jct.pillorganizer.tenant.exceptions;

public class DeviceProvisionExpiredException extends RuntimeException {
    public DeviceProvisionExpiredException(String message) {
        super(message);
    }
}
