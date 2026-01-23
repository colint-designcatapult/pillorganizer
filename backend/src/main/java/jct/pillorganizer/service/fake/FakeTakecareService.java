package jct.pillorganizer.service.fake;

import io.micronaut.context.annotation.Replaces;
import io.micronaut.context.annotation.Requires;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.auth.AuthService;
import jct.pillorganizer.dto.ObservationDTO;
import jct.pillorganizer.dto.PatientValidationRequestDTO;
import jct.pillorganizer.repo.UserRepository;
import jct.pillorganizer.service.TakecareClient;
import jct.pillorganizer.service.TakecareService;
import lombok.extern.flogger.Flogger;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.time.ZoneId;

@Requires(notEnv = "prod")
@Replaces(TakecareService.class)
@Singleton
@Flogger
public class FakeTakecareService extends TakecareService {

    @Inject
    public FakeTakecareService(UserRepository userRepository, AuthService authService) {
        super(null, userRepository, authService);
    }

    @Override
    public Mono<Void> validateAndLinkTakecarePatient(String patientID, PatientValidationRequestDTO validationRequest) {
        long userId = authService.getUserID();
        log.atInfo().log("Fake link user [%d] to patient [%d]", userId, patientID);
        log.atInfo().log("First name: %s\tLast name: %s\tBirth date: %s", validationRequest.getFirstName(),
                validationRequest.getLastName(), validationRequest.getBirthDate());
        storePatientIdInUser(userId, patientID);
        return Mono.empty();
    }

    @Override
    public Mono<ObservationDTO> createObservation(String patientID, Instant openTime, ZoneId timeZone, String code) {
        log.atInfo().log("Fake Takecare observation: patientID=%s, openTime=%s, tz=%s, code=%s", patientID,
                openTime.toString(), timeZone.toString(), code);
        return Mono.empty();
    }
}
