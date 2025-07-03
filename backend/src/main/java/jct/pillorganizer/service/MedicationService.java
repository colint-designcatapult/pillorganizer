package jct.pillorganizer.service;

import io.micronaut.context.annotation.Bean;
import jakarta.inject.Inject;
import jct.pillorganizer.dto.SaveMedicationDTO;
import jct.pillorganizer.exceptions.MedicationNotFoundException;
import jct.pillorganizer.model.device.DeviceUser;
import jct.pillorganizer.model.medication.MedicationDispenseTime;
import jct.pillorganizer.model.medication.ScheduledMedication;
import jct.pillorganizer.repo.MedicationDispenseTimeRepository;
import jct.pillorganizer.repo.ScheduledMedicationRepository;

import javax.transaction.Transactional;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;

/**
 * Business logic for operations on ScheduledMedication objects.
 */
@Bean
public class MedicationService {

    @Inject
    ScheduledMedicationRepository scheduledMedicationRepository;

    @Inject
    MedicationDispenseTimeRepository dispenseTimeRepository;

    /**
     * Deletes a single ScheduledMedication (and their dependents) by ID.
     * @param medicationID the ID of the medication to delete
     * @param deviceUser the device ID of the device the medication is associated with.
     */
    @Transactional
    public void delete(long medicationID, DeviceUser deviceUser) {
        Optional<ScheduledMedication> sm = scheduledMedicationRepository
                .findByIdAndDeviceUser(medicationID, deviceUser);
        if(sm.isPresent()) {
            dispenseTimeRepository.deleteAll(sm.get().getDispenseTimes());
            scheduledMedicationRepository.delete(sm.get());
        } else {
            throw new MedicationNotFoundException("Medication not found for ID: " + medicationID);
        }
    }

    /**
     * Creates or updates a medication associated with a device. If a medication exists with the ID specified in the DTO
     * object, it will be updated with the new information in the DTO. Otherwise, a new medication is created.
     * @param deviceUser device the medication is associated with
     * @param dto DTO object of the medication to persist
     * @return domain entity of the persisted medication
     */
    @Transactional
    public ScheduledMedication saveFromDto(DeviceUser deviceUser, SaveMedicationDTO dto) {
        ScheduledMedication med, res;

        if(dto.id() == null) {
            // New medication
            med = new ScheduledMedication();
            med.setDeviceUser(deviceUser);
            med.setDevice_user_id(deviceUser.getId());
            med.setShape(dto.shape());
            med.setColor((int) dto.color());
            med.setMed_name(dto.name());
            med.setDispenseTimes(Set.of());
            res = scheduledMedicationRepository.save(med);

            // Insert dispense times
            Set<MedicationDispenseTime> mdsSet = new HashSet<>(dto.dispenseTimes().size());
            for(long dispenseID : dto.dispenseTimes()) {
                MedicationDispenseTime dt = new MedicationDispenseTime();
                dt.setMedicationID(med.getId());
                dt.setDispenseID(dispenseID);
                dt.setQuantity(1);  // todo: quantity support
                mdsSet.add(dispenseTimeRepository.save(dt));
            }

            res.setDispenseTimes(mdsSet);
        } else {
            // Update existing medication

            med = scheduledMedicationRepository.retrieveByDeviceUserAndId(deviceUser, dto.id());
            scheduledMedicationRepository
                    .update(med.getId(), dto.name(), dto.shape(), (int) dto.color());
            med.setMed_name(dto.name());
            med.setShape(dto.shape());
            med.setColor((int) dto.color());
            res = med;

            // Merge dispense time

            for(long dispenseID : dto.dispenseTimes()) {
                Optional<MedicationDispenseTime> opt =
                        dispenseTimeRepository.findByDispenseIDAndMedicationID(dispenseID, med.getId());
                if(opt.isEmpty()) {
                    MedicationDispenseTime dt = new MedicationDispenseTime();
                    dt.setMedicationID(med.getId());
                    dt.setDispenseID(dispenseID);
                    dt.setQuantity(1);  // todo: quantity support
                    res.getDispenseTimes().add(dispenseTimeRepository.save(dt));
                }
            }

            for(MedicationDispenseTime dt : dispenseTimeRepository.findByMedicationID(med.getId())) {
                if(!dto.dispenseTimes().contains(dt.getDispenseID())) {
                    res.getDispenseTimes().remove(dt);
                    dispenseTimeRepository.delete(dt);
                }
            }

        }
        return res;
    }

}
