package jct.pillorganizer.service;

import java.time.Instant;
import java.time.ZoneId;
import java.util.Optional;

import org.zalando.problem.Problem;

import io.micronaut.http.HttpStatus;
import io.micronaut.problem.HttpStatusType;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.auth.AuthService;
import jct.pillorganizer.dto.FhirPatientDTO;
import jct.pillorganizer.dto.ObservationDTO;
import jct.pillorganizer.repo.UserRepository;
import lombok.extern.flogger.Flogger;
import reactor.core.publisher.Mono;

@Singleton
@Flogger
public class TakecareService {

    @Inject
    TakecareClient takecareClient;

    @Inject
    UserRepository userRepository;

    @Inject
    AuthService authService;

    /**
     * Links a Takecare patient to the current user
     * @param patientID The patient ID to link
     * @return Mono that completes when linking is successful or throws Problem if linking fails
     */
    public Mono<Void> linkTakecarePatient(String patientID) {
        long userID = authService.getUserID();
        log.atInfo().log("Validating Takecare patient %s for user %d", patientID, userID);
        
        return takecareClient.getPatient(patientID)
                .switchIfEmpty(Mono.defer(() -> {
                    log.atWarning().log("Patient not found: %s", patientID);
                    return Mono.error(Problem.builder()
                            .withStatus(new HttpStatusType(HttpStatus.NOT_FOUND))
                            .withTitle("Patient not found")
                            .build());
                }))
                .flatMap(patient -> {
                    validatePatientActive(patient, patientID);
                    String patientEmail = extractPatientEmail(patient, patientID);
                    
                    return userRepository.findUserInfoDTOFromID(userID)
                            .switchIfEmpty(Mono.defer(() -> {
                                log.atWarning().log("User not found: %d", userID);
                                return Mono.error(Problem.builder()
                                        .withStatus(new HttpStatusType(HttpStatus.NOT_FOUND))
                                        .withTitle("User not found")
                                        .build());
                            }))
                            .doOnNext(user -> validateEmailsMatch(user.email(), patientEmail, patientID))
                            .then(storePatientIdInUser(userID, patientID));
                })
                .doOnSuccess(ignored -> log.atInfo().log("Successfully validated Takecare patient %s for user %d", patientID, userID));
    }

    /**
     * Creates an observation for a patient
     * @param patientID The patient ID to create the observation for
     * @param openTime The instant when the pillbox was opened
     * @param timeZone The timezone for the device
     * @return Mono that completes when observation is created or throws Problem if creation fails
     */
    public Mono<ObservationDTO> createObservation(String patientID, Instant openTime, ZoneId timeZone, String code) {
        if (patientID == null || patientID.trim().isEmpty()) {
            Problem problem = Problem.builder()
                    .withTitle("Invalid patient ID for observation creation")
                    .withDetail("No takecare patient is linked - cannot create observation")
                    .build();
            log.atWarning().log("Problem creating observation: %s", problem.getDetail());
            return Mono.empty();
        }

        if (openTime == null) {
            Problem problem = Problem.builder()
                    .withTitle("Invalid open time for observation creation")
                    .withDetail("Open time is null - cannot create observation")
                    .build();
            log.atWarning().log("Problem creating observation: %s", problem.getDetail());
            return Mono.empty();
        }
        
        return takecareClient.createObservation(patientID, openTime, timeZone, code)
                .onErrorResume(throwable -> {
                    Problem problem = Problem.builder()
                            .withTitle("Failed to create observation")
                            .withDetail("Error occurred while creating observation for patient: " + patientID + ". Cause: " + throwable.getMessage())
                            .build();
                    
                    log.atWarning().withCause(throwable).log("Problem creating observation: %s", problem.getDetail());
                    return Mono.empty();
                });
    }

    private Mono<Void> storePatientIdInUser(long userID, String patientID) {
        return userRepository.updateTakecarePatientIdById(patientID, userID)
                .flatMap(updatedCount -> {
                    if (updatedCount == 0) {
                        log.atWarning().log("User not found for patient ID storage: %d", userID);
                        return Mono.error(Problem.builder()
                                .withStatus(new HttpStatusType(HttpStatus.NOT_FOUND))
                                .withTitle("User not found")
                                .build());
                    }
                    log.atInfo().log("Stored patient ID %s for user %d", patientID, userID);
                    return Mono.<Void>empty();
                });
    }

    private void validatePatientActive(FhirPatientDTO patient, String patientID) {
        boolean isActive = patient.getActive() != null && patient.getActive();
        log.atInfo().log("Patient active: %s", isActive);
        if (!isActive) {
            log.atWarning().log("Patient is inactive: %s", patientID);
            throw Problem.builder()
                .withStatus(new HttpStatusType(HttpStatus.BAD_REQUEST))
                .withTitle("Patient is inactive")
                .build();
        }
    }

    private String extractPatientEmail(FhirPatientDTO patient, String patientID) {
        Optional<String> emailOpt = getPatientEmail(patient);
        if (emailOpt.isEmpty()) {
            log.atWarning().log("Patient has no email: %s", patientID);
            throw Problem.builder()
                .withStatus(new HttpStatusType(HttpStatus.BAD_REQUEST))
                .withTitle("Patient has no email")
                .build();
        }
        return emailOpt.get();
    }

    private void validateEmailsMatch(String userEmail, String patientEmail, String patientID) {
        if (!userEmail.equals(patientEmail)) {
            log.atWarning().log("Email mismatch for patient %s: user=%s, patient=%s", 
                patientID, userEmail, patientEmail);
            throw Problem.builder()
                .withStatus(new HttpStatusType(HttpStatus.BAD_REQUEST))
                .withTitle("Patient email does not match user email")
                .build();
        }
    }

    private Optional<String> getPatientEmail(FhirPatientDTO patient) {
        if (patient.getTelecom() == null) {
            return Optional.empty();
        }

        return patient.getTelecom().stream()
                .filter(telecom -> telecom.getValue() != null && 
                        telecom.getValue().contains("@"))
                .map(telecom -> telecom.getValue())
                .findFirst();
    }
} 