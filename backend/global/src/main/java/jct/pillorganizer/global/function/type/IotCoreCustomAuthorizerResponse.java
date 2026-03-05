package jct.pillorganizer.global.function.type;

import io.micronaut.serde.annotation.Serdeable;

import java.util.List;

@Serdeable.Serializable
public record IotCoreCustomAuthorizerResponse(boolean isAuthenticated, String principalId, List<String> policyDocuments,
                                              Integer disconnectAfterInSeconds, Integer refreshAfterInSeconds) {
}
