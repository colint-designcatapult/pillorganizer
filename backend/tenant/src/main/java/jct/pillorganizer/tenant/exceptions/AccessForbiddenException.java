package jct.pillorganizer.tenant.exceptions;

public class AccessForbiddenException extends RuntimeException {
    public AccessForbiddenException(String message) {
        super(message);
    }
}