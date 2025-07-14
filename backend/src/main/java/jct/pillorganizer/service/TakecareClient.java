package jct.pillorganizer.service;

import io.micronaut.context.annotation.Value;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.client.HttpClient;
import io.micronaut.http.client.annotation.Client;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.dto.FhirPatientDto;
import lombok.extern.flogger.Flogger;
import reactor.core.publisher.Mono;

@Singleton
@Flogger
public class TakecareClient {

    private final HttpClient httpClient;
    private final String takecareApiUrl;
    private final String takecareApiToken;

    @Inject
    public TakecareClient(@Client HttpClient httpClient,
                           @Value("${takecare.api.url}") String takecareApiUrl,
                           @Value("${takecare.api.token}") String takecareApiToken) {
        this.httpClient = httpClient;
        this.takecareApiUrl = takecareApiUrl;
        this.takecareApiToken = takecareApiToken;
    }

    /**
     * Retrieves a FHIR Patient by ID from the Takecare API
     * @param patientId The patient ID to retrieve
     * @return Mono containing the patient if found, empty Mono otherwise
     */
    public Mono<FhirPatientDto> getPatient(String patientId) {
        try {
            String endpoint = String.format("%s/fhir/Patient/%s", takecareApiUrl, patientId);
            
            HttpRequest<Object> request = HttpRequest.GET(endpoint)
                    .header("authorization", "Token " + takecareApiToken)
                    .header("accept", "application/json")
                    .header("content-type", "application/json");
            
            log.atInfo().log("Requesting patient with ID: %s", patientId);

            return Mono.from(httpClient.retrieve(request, FhirPatientDto.class))
                    .doOnSuccess(patient -> log.atInfo().log("Successfully retrieved patient with ID: %s", patientId))
                    .doOnError(error -> log.atWarning().withCause(error).log("Failed to retrieve patient with ID: %s", patientId))
                    .onErrorResume(throwable -> {
                        log.atWarning().withCause(throwable).log("Failed to retrieve patient with ID: %s", patientId);
                        return Mono.empty();
                    });
            
        } catch (Exception e) {
            log.atWarning().withCause(e).log("Error creating request for patient ID: %s", patientId);
            return Mono.empty();
        }
    }
} 