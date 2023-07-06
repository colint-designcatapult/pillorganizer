package jct.pillorganizer.app;

import androidx.annotation.Nullable;

import com.espressif.provisioning.ESPConstants;

public class ESPProvisioningFailureException extends Exception {

    private final ESPConstants.ProvisionFailureReason reason;

    public ESPProvisioningFailureException(ESPConstants.ProvisionFailureReason reason) {
        this.reason = reason;
    }

    @Nullable
    @Override
    public String getMessage() {
        return reason.name();
    }

    public ESPConstants.ProvisionFailureReason getReason() {
        return this.reason;
    }
}
