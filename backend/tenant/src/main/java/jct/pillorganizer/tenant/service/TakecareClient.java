package jct.pillorganizer.tenant.service;

import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;

import org.zalando.problem.Problem;

import io.micronaut.context.annotation.Value;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.client.HttpClient;
import io.micronaut.http.client.annotation.Client;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.dto.CodeDTO;
import jct.pillorganizer.tenant.dto.CodingDTO;
import jct.pillorganizer.tenant.dto.FhirPatientDTO;
import jct.pillorganizer.tenant.dto.ObservationDTO;
import jct.pillorganizer.tenant.dto.ReferenceDTO;
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
    public Mono<FhirPatientDTO> getPatient(String patientId) {
        try {
            String endpoint = String.format("%s/fhir/Patient/%s", takecareApiUrl, patientId);
            
            HttpRequest<Object> request = HttpRequest.GET(endpoint)
                    .header("authorization", "Token " + takecareApiToken)
                    .header("accept", "application/json")
                    .header("content-type", "application/json");

            return Mono.from(httpClient.retrieve(request, FhirPatientDTO.class))
                    .doOnError(error -> {
                        Problem problem = Problem.builder()
                                .withTitle("HTTP error during patient retrieval")
                                .withDetail("Failed to retrieve patient: " + patientId + ". HTTP error: " + error.getMessage())
                                .build();
                        log.atWarning().withCause(error).log("Problem retrieving patient: %s", problem.getDetail());
                    })
                    .onErrorResume(throwable -> {
                        Problem problem = Problem.builder()
                                .withTitle("Failed to retrieve patient")
                                .withDetail("Error occurred while retrieving patient: " + patientId + ". Cause: " + throwable.getMessage())
                                .build();
                        
                        log.atWarning().withCause(throwable).log("Problem retrieving patient: %s", problem.getDetail());
                        return Mono.empty();
                    });
            
        } catch (Exception e) {
            Problem problem = Problem.builder()
                    .withTitle("Exception during patient retrieval")
                    .withDetail("Error creating request for patient: " + patientId + ". Exception: " + e.getMessage())
                    .build();
            
            log.atWarning().withCause(e).log("Problem retrieving patient: %s", problem.getDetail());
            return Mono.empty();
        }
    }


    /**
     * Creates an observation for a patient
     * @param patientId The patient ID to create the observation for
     * @param openTime The instant when the pillbox was opened
     * @param timeZone The timezone for the device
     * @return Mono containing the observation if created, empty Mono otherwise
     */
    public Mono<ObservationDTO> createObservation(String patientId, Instant openTime, ZoneId timeZone, String code) {
        try {
            String endpoint = String.format("%s/fhir/Observation", takecareApiUrl);

            CodingDTO codingDTO = CodingDTO.builder()
                .system("urn:gb:medical-measurement-type:short-code")
                .code(code)
                .build();

            CodeDTO codeDTO = CodeDTO.builder()
                .coding(Arrays.asList(codingDTO))
                .text("Heure d'ouverture du compartiment")
                .build();

            ReferenceDTO subject = ReferenceDTO.builder()
                .reference("Patient/" + patientId)
                .build();

            String formattedDateTime = DateTimeFormatter.ISO_OFFSET_DATE_TIME.format(openTime.atZone(timeZone));

            ObservationDTO observationDTO = ObservationDTO.builder()
                .resourceType("Observation")
                .status("final")
                .category(Arrays.asList("activity"))
                .code(codeDTO)
                .subject(subject)
                .performer(patientId)
                .effectiveDateTime(formattedDateTime)
                .valueDateTime(formattedDateTime)
                .build();

            HttpRequest<ObservationDTO> request = HttpRequest.POST(endpoint, observationDTO)
                    .header("authorization", "Token " + takecareApiToken)
                    .header("accept", "application/json")
                    .header("content-type", "application/json");

            // logRequestAsCurl(endpoint, observation);

            return Mono.from(httpClient.retrieve(request, ObservationDTO.class))
                    .doOnSuccess(observationResponse -> log.atInfo().log("Successfully created observation for patient with ID: %s", patientId))
                    .doOnError(error -> {
                        Problem problem = Problem.builder()
                                .withTitle("HTTP error during observation creation")
                                .withDetail("Failed to create observation for patient: " + patientId + ". HTTP error: " + error.getMessage())
                                .build();
                        log.atWarning().withCause(error).log("Problem creating observation: %s", problem.getDetail());
                    })
                    .onErrorResume(throwable -> {
                        Problem problem = Problem.builder()
                                .withTitle("Failed to create observation")
                                .withDetail("Error occurred while creating observation for patient: " + patientId + ". Cause: " + throwable.getMessage())
                                .build();
                        
                        log.atWarning().withCause(throwable).log("Problem creating observation: %s", problem.getDetail());
                        return Mono.empty();
                    });
            
        } catch (Exception e) {
            Problem problem = Problem.builder()
                    .withTitle("Exception during observation creation")
                    .withDetail("Error creating observation request for patient: " + patientId + ". Exception: " + e.getMessage())
                    .build();
            
            log.atWarning().withCause(e).log("Problem creating observation: %s", problem.getDetail());
            return Mono.empty();
        }
    }

    // /**
    //  * Logs the request as a curl command for debugging
    //  */
    // private void logRequestAsCurl(String endpoint, ObservationDTO observation) {
    //     try {
    //         ObjectMapper mapper = new ObjectMapper();
    //         mapper.findAndRegisterModules(); // For Java 8 time support
    //         String jsonBody = mapper.writerWithDefaultPrettyPrinter().writeValueAsString(observation);
            
    //         StringBuilder curlCommand = new StringBuilder();
    //         curlCommand.append("curl --location '").append(endpoint).append("' \\\n");
    //         curlCommand.append("--header 'authorization: Token ").append(takecareApiToken).append("' \\\n");
    //         curlCommand.append("--header 'accept: application/json' \\\n");
    //         curlCommand.append("--header 'content-type: application/json' \\\n");
    //         curlCommand.append("--data '\n").append(jsonBody).append("\n'");
            
    //         log.atInfo().log("Generated curl request:\n%s", curlCommand.toString());
            
    //     } catch (Exception e) {
    //         log.atWarning().withCause(e).log("Failed to generate curl command for debugging");
    //     }
    // }
} 