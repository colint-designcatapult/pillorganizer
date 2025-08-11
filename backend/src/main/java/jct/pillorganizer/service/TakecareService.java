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
import jct.pillorganizer.dto.PatientValidationRequestDTO;
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
     * Validates and links a Takecare patient to the current user with form validation
     * @param patientID The patient ID to link
     * @param validationRequest The form data to validate against the patient
     * @return Mono that completes when linking is successful or throws Problem if validation fails
     */
    public Mono<Void> validateAndLinkTakecarePatient(String patientID, PatientValidationRequestDTO validationRequest) {
        return takecareClient.getPatient(patientID)
                .switchIfEmpty(Mono.defer(() -> {
                    return Mono.error(Problem.builder()
                            .withStatus(new HttpStatusType(HttpStatus.BAD_REQUEST))
                            .withTitle("Validation failed")
                            .withDetail("Invalid patient information provided")
                            .build());
                }))
                .flatMap(patient -> {
                    return userRepository.findUserInfoDTOFromID(authService.getUserID())
                            .switchIfEmpty(Mono.defer(() -> {
                                return Mono.error(Problem.builder()
                                        .withStatus(new HttpStatusType(HttpStatus.BAD_REQUEST))
                                        .withTitle("Validation failed")
                                        .withDetail("Invalid patient information provided")
                                        .build());
                            }))
                            .flatMap(user -> {
                                if (!isValidPatient(patient, validationRequest, patientID, user.email())) {
                                    return Mono.error(Problem.builder()
                                            .withStatus(new HttpStatusType(HttpStatus.BAD_REQUEST))
                                            .withTitle("Validation failed")
                                            .withDetail("Invalid patient information provided")
                                            .build());
                                }
                                
                                return storePatientIdInUser(user.id(), patientID);
                            });
                });
    }

    /**
     * Validates patient data against the provided form data and user email
     * @return true if all validations pass, false otherwise
     */
    private boolean isValidPatient(FhirPatientDTO patient, PatientValidationRequestDTO validationRequest, String patientID, String userEmail) {
        Optional<String> patientFirstNameOpt = getPatientFirstName(patient);
        Optional<String> patientLastNameOpt = getPatientLastName(patient);
        Optional<String> patientEmailOpt = getPatientEmail(patient);
        
        return patient.getActive() != null && patient.getActive() &&
               patientFirstNameOpt.isPresent() &&
               patientFirstNameOpt.get().equalsIgnoreCase(validationRequest.getFirstName()) &&
               patientLastNameOpt.isPresent() &&
               patientLastNameOpt.get().equalsIgnoreCase(validationRequest.getLastName()) &&
               patient.getBirthDate() != null && !patient.getBirthDate().trim().isEmpty() &&
               patient.getBirthDate().equals(validationRequest.getBirthDate()) &&
               patientEmailOpt.isPresent() &&
               patientEmailOpt.get().equals(userEmail);
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
                    return Mono.empty();
                });
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

    private Optional<String> getPatientFirstName(FhirPatientDTO patient) {
        if (patient.getName() == null || patient.getName().isEmpty()) {
            return Optional.empty();
        }

        return patient.getName().stream()
                .filter(name -> name.getUse() == null || 
                               String.valueOf(name.getUse()).equals("official") || 
                               String.valueOf(name.getUse()).equals("usual"))
                .filter(name -> name.getGiven() != null && !name.getGiven().isEmpty())
                .map(name -> name.getGiven().get(0))
                .findFirst();
    }

    private Optional<String> getPatientLastName(FhirPatientDTO patient) {
        if (patient.getName() == null || patient.getName().isEmpty()) {
            return Optional.empty();
        }

        return patient.getName().stream()
                .filter(name -> name.getUse() == null || 
                               String.valueOf(name.getUse()).equals("official") || 
                               String.valueOf(name.getUse()).equals("usual"))
                .filter(name -> name.getFamily() != null && !name.getFamily().trim().isEmpty())
                .map(name -> name.getFamily())
                .findFirst();
    }
} 