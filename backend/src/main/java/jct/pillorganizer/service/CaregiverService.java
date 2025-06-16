package jct.pillorganizer.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.model.device.DeviceCaregiverCode;
import jct.pillorganizer.repo.CaregiverRepository;
import lombok.extern.flogger.Flogger;

import javax.transaction.Transactional;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.Optional;

@Singleton
@Flogger
public class CaregiverService {
    @Inject
    CaregiverRepository caregiverRepository;

    @Transactional
    public DeviceCaregiverCode findCaregiverCode(long code) {
        Timestamp currentTime = Timestamp.from(Instant.now());

        Optional<DeviceCaregiverCode> caregiverCodeOpt = caregiverRepository
                .findByCodeAndExpiresAtGreaterThanAndDeletedFalse(
                        code,
                        currentTime
                );

        return caregiverCodeOpt.orElse(null);
    }

    @Transactional
    public void deleteCaregiverCode(long caregiverCodeId) {
        Optional<DeviceCaregiverCode> codeOptional = caregiverRepository.findById(caregiverCodeId);

        if (codeOptional.isPresent()) {
            DeviceCaregiverCode code = codeOptional.get();
            code.setDeleted(true);
            caregiverRepository.update(code);
        }
    }
}