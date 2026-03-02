package jct.pillorganizer.tenant.exceptions;

public class InvalidTenantUserException extends RuntimeException {
    public InvalidTenantUserException(String message) {
        super(message);
    }
}
