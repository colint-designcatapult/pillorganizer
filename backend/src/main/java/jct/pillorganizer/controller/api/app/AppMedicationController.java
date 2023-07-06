package jct.pillorganizer.controller.api.app;

import io.micronaut.http.annotation.*;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.auth.AuthService;
import jct.pillorganizer.dto.SaveMedicationDTO;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.medication.ScheduledMedication;
import jct.pillorganizer.repo.ScheduledMedicationRepository;
import jct.pillorganizer.service.MedicationService;
import lombok.extern.flogger.Flogger;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import javax.transaction.Transactional;

@Controller("/api/v1/device")
@Flogger
public class AppMedicationController {

    @Inject
    ScheduledMedicationRepository scheduledMedicationRepository;

    @Inject
    AuthService authService;

    @Inject
    MedicationService medicationService;

    @Operation(summary = "List medications for a device")
    @Get("/{id}/medication")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Flux<ScheduledMedication> medications(@PathVariable("id") long deviceID) {
        Device d= authService.accessDevice(deviceID);
        return Flux.fromIterable(scheduledMedicationRepository.retrieveByDevice(d));
    }

    @Operation(summary = "Saves a medication")
    @Post("/{id}/medication")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    @Transactional
    public ScheduledMedication saveMedication(@PathVariable("id") long deviceID, @Body SaveMedicationDTO model) {
        Device d = authService.accessDevice(deviceID);
        return medicationService.saveFromDto(d, model);
    }


    @Operation(summary = "Deletes a medication")
    @Delete("/{id}/medication/{med_id}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public void deleteMedication(@PathVariable("id") long deviceID, @PathVariable("med_id") long medicationID) {
        Device d = authService.accessDevice(deviceID);
        medicationService.delete(medicationID, d);
    }

    @Operation(summary = "Gets a medication by ID")
    @Get("/{id}/medication/{med_id}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Mono<ScheduledMedication> get(@PathVariable("id") long deviceID, @PathVariable("med_id") long medicationID) {
        Device d= authService.accessDevice(deviceID);
        ScheduledMedication med = scheduledMedicationRepository.retrieveByDeviceAndId(d, medicationID);
        return Mono.just(med);
    }

}
