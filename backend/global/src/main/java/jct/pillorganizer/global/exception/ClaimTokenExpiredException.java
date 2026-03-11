package jct.pillorganizer.global.exception;

public class ClaimTokenExpiredException extends RuntimeException {
    public ClaimTokenExpiredException(String message) {
        super(message);
    }
}
