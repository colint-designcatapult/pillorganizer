package jct.pillorganizer.tenant.service;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Random;
import java.util.Set;
import java.util.stream.Collectors;

import jakarta.transaction.Transactional;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.dto.DeviceCaregiverCodeDTO;
import jct.pillorganizer.tenant.model.device.DeviceCaregiverCode;
import jct.pillorganizer.tenant.repo.CaregiverRepository;
import lombok.extern.flogger.Flogger;

@Singleton
@Flogger
public class CaregiverService {
    @Inject
    CaregiverRepository caregiverRepository;

    @Inject
    DeviceUserService deviceUserService;

    private final Random random = new Random();

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

    @Transactional
    public List<DeviceCaregiverCode> getValidShareCodesForDevices(Set<Long> deviceIds) {
        Timestamp currentTime = Timestamp.from(Instant.now());
        var result = caregiverRepository.findByDeviceIDInAndExpiresAtGreaterThanAndDeletedFalse(deviceIds, currentTime);
        return result;
    }

    @Transactional
    public List<DeviceCaregiverCodeDTO> getShareCodesForUser(long userID, List<Long> deviceIds) {
        Set<Long> accessibleDeviceIds = deviceIds.stream()
            .filter(deviceId -> deviceUserService.userHasAccessToDevice(userID, deviceId))
            .collect(Collectors.toSet());
        
        if (accessibleDeviceIds.isEmpty()) {
            return List.of();
        }
        
        List<DeviceCaregiverCode> shareCodes = getValidShareCodesForDevices(accessibleDeviceIds);
        
        return shareCodes.stream()
            .map(code -> new DeviceCaregiverCodeDTO(
                code.getId(),
                code.getPatientID(),
                code.getDeviceID(),
                code.getCode(),
                code.getExpiresAt().getTime(),
                code.isDeleted()
            ))
            .collect(Collectors.toList());
    }

    @Transactional
    public DeviceCaregiverCode generateCaregiverCode(long deviceId,  long userID) {
        deleteAllCodesForDevice(deviceId);
        
        long code = generateUniqueCode();
        
        Timestamp expiresAt = Timestamp.from(Instant.now().plusSeconds(600));
        
        DeviceCaregiverCode caregiverCode = new DeviceCaregiverCode();
        caregiverCode.setDeviceID(deviceId);
        caregiverCode.setCode(code);
        caregiverCode.setExpiresAt(expiresAt);
        caregiverCode.setDeleted(false);
        caregiverCode.setPatientID(userID);

        return caregiverRepository.save(caregiverCode);
    }

    @Transactional
    public void deleteAllCodesForDevice(long deviceId) {
        List<DeviceCaregiverCode> existingCodes = caregiverRepository.findByDeviceIDAndDeletedFalse(deviceId);
        
        for (DeviceCaregiverCode existingCode : existingCodes) {
            existingCode.setDeleted(true);
            caregiverRepository.update(existingCode);
        }
    }

    /**
     * Generate a unique code using application-level retry mechanism.
     * Database constraints ensure uniqueness.
     * 
     * @return A unique 6-digit code
     */
    private long generateUniqueCode() {
        while (true) {
            long code = 100000 + random.nextInt(900000);
            
            Timestamp currentTime = Timestamp.from(Instant.now());
            Optional<DeviceCaregiverCode> existingCode = caregiverRepository
                .findByCodeAndExpiresAtGreaterThanAndDeletedFalse(code, currentTime);
            
            if (existingCode.isEmpty()) {
                return code;
            }
        }
    }
}