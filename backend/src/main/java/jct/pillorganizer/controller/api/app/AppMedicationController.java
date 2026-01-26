package jct.pillorganizer.controller.api.app;

import java.util.Optional;

import jakarta.transaction.Transactional;

import io.micronaut.http.annotation.Body;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Delete;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.PathVariable;
import io.micronaut.http.annotation.Post;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.auth.AuthService;
import jct.pillorganizer.dto.SaveMedicationDTO;
import jct.pillorganizer.model.device.DeviceUser;
import jct.pillorganizer.model.medication.ScheduledMedication;
import jct.pillorganizer.repo.DeviceUserRepository;
import jct.pillorganizer.repo.ScheduledMedicationRepository;
import jct.pillorganizer.service.MedicationService;
import lombok.extern.flogger.Flogger;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Controller("/api/v1/device")
@Flogger
public class AppMedicationController {

    @Inject
    ScheduledMedicationRepository scheduledMedicationRepository;

    @Inject
    AuthService authService;

    @Inject
    MedicationService medicationService;

    @Inject
    DeviceUserRepository deviceUserRepository;

    @Operation(summary = "List medications for a device")
    @Get("/{id}/medication")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Flux<ScheduledMedication> medications(@PathVariable("id") long deviceID) {
        long userId = authService.getUserID();
        DeviceUser deviceUser = deviceUserRepository.findByUserIDAndDeviceIDAndDeletedFalseOrThrow(userId, deviceID);
        
        DeviceUser medicationDeviceUser = deviceUser;
        if (!deviceUser.isOwner()) {
            Optional<DeviceUser> ownerOptional = deviceUserRepository.findByDeviceIDAndOwnerTrueAndDeletedFalse(deviceID);
            if (ownerOptional.isPresent()) {
                medicationDeviceUser = ownerOptional.get();
            }
        }
        
        return Flux.fromIterable(scheduledMedicationRepository.retrieveByDeviceUser(medicationDeviceUser));
    }

    @Operation(summary = "Saves a medication")
    @Post("/{id}/medication")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    @Transactional
    public ScheduledMedication saveMedication(@PathVariable("id") long deviceID, @Body SaveMedicationDTO model) {
        long userId = authService.getUserID();
        DeviceUser deviceUser = deviceUserRepository.findByUserIDAndDeviceIDAndDeletedFalseOrThrow(userId, deviceID);
        return medicationService.saveFromDto(deviceUser, model);
    }


    @Operation(summary = "Deletes a medication")
    @Delete("/{id}/medication/{med_id}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public void deleteMedication(@PathVariable("id") long deviceID, @PathVariable("med_id") long medicationID) {
        long userId = authService.getUserID();
        DeviceUser deviceUser = deviceUserRepository.findByUserIDAndDeviceIDAndDeletedFalseOrThrow(userId, deviceID);
        medicationService.delete(medicationID, deviceUser);
    }

    @Operation(summary = "Gets a medication by ID")
    @Get("/{id}/medication/{med_id}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Mono<ScheduledMedication> get(@PathVariable("id") long deviceID, @PathVariable("med_id") long medicationID) {
        long userId = authService.getUserID();
        DeviceUser deviceUser = deviceUserRepository.findByUserIDAndDeviceIDAndDeletedFalseOrThrow(userId, deviceID);
        
        DeviceUser medicationDeviceUser = deviceUser;
        if (!deviceUser.isOwner()) {
            Optional<DeviceUser> ownerOptional = deviceUserRepository.findByDeviceIDAndOwnerTrueAndDeletedFalse(deviceID);
            if (ownerOptional.isPresent()) {
                medicationDeviceUser = ownerOptional.get();
            }
        }
        
        ScheduledMedication med = scheduledMedicationRepository.retrieveByDeviceUserAndId(medicationDeviceUser, medicationID);
        return Mono.just(med);
    }

}
