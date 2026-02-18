package jct.pillorganizer.tenant.exceptions;

public class MedicationNotFoundException extends RuntimeException {
    public MedicationNotFoundException(String message) {
        super(message);
    }
}

