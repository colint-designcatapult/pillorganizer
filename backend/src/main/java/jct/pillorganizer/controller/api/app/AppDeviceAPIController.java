package jct.pillorganizer.controller.api.app;

import com.google.protobuf.InvalidProtocolBufferException;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.*;
import io.micronaut.problem.HttpStatusType;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.auth.AuthService;
import jct.pillorganizer.auth.DeviceABAC;
import jct.pillorganizer.auth.DeviceABACIDType;
import jct.pillorganizer.dto.*;
import jct.pillorganizer.model.device.Device;
import jct.pillorganizer.model.device.DeviceClass;
import jct.pillorganizer.model.device.DeviceProvision;
import jct.pillorganizer.proto.Pill;
import jct.pillorganizer.repo.*;
import jct.pillorganizer.service.DeviceProvisionService;
import jct.pillorganizer.service.DeviceStateService;
import jct.pillorganizer.service.DeviceUserService;
import lombok.extern.flogger.Flogger;
import org.zalando.problem.Problem;

import javax.transaction.Transactional;
import java.text.ParseException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.temporal.TemporalAccessor;
import java.util.Base64;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * API endpoints for the app to configure and view device information and state.
 */
@Controller("/api/v1/device")
@Flogger
public class AppDeviceAPIController {

    @Inject
    DeviceRepository deviceRepository;

    @Inject
    DeviceProvisionService deviceProvisionService;

    @Inject
    DeviceStateRepository deviceStateRepository;

    @Inject
    DeviceScheduleRepository deviceScheduleRepository;

    @Inject
    DeviceStateService stateService;

    @Inject
    DeviceEventRepository deviceEventRepository;

    @Inject
    AuthService authService;

    @Inject
    DeviceUserRepository deviceUserRepository;

    @Inject
    DeviceStateService deviceStateService;

    @Inject
    DeviceUserService deviceUserService;

    @Operation(summary = "Lists devices that the user has access to")
    @Get("/list")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Set<DeviceUserDTO> listDeviceUser() {
        if (authService.isAdmin()) {
            Set<DeviceUserDTO> result = new HashSet<>(deviceUserRepository.findByUserID(authService.getUserID()));
            Set<Long> ids = result.stream().map(DeviceUserDTO::deviceID).collect(Collectors.toSet());

            deviceRepository.findAll()
                    .stream()
                    .filter(d -> !ids.contains(d.getId()))
                    .map(d -> new DeviceUserDTO(
                            -1, d.getId(), d.getDeviceClass(), d.getCustomName(), d.getLastSync(),
                            d.getSerialNo(), false, false, false, d.getBaseTZ()))
                    .forEach(result::add);

            return result;
        } else {
            return deviceUserRepository.findByUserID(authService.getUserID());
        }
    }

    @Operation(summary = "Soft deletes the device user link")
    @Delete("/{id}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> removeDeviceFromUser(@QueryValue long id) {
        Device device = authService.accessDevice(id);
        deviceUserService.removeDeviceFromUser(authService.getUserID(), device.getId());
        return HttpResponse.ok();
    }

    @Operation(summary = "Initiates provisioning")
    @Post("/provision/start")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public DeviceProvision startProvisioning(@Body StartProvision startProvision,
            @Header("X-Local-TZ") @Nullable String timezone) {
        String tz = "UTC";
        if (timezone != null) {
            if (ZoneId.getAvailableZoneIds().contains(timezone)) {
                tz = timezone;
            } else {
                throw Problem.builder().withStatus(new HttpStatusType(HttpStatus.BAD_REQUEST))
                        .withTitle("Invalid timezone")
                        .build();
            }
        }

        return deviceProvisionService.startProvisioning(
                startProvision.getSerialNo(),
                DeviceClass.valueOf(startProvision.getDeviceClass()),
                tz);
    }

    @Operation(summary = "Checks provisioning status")
    @Post("/provision/{id}/verify")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<?> checkProvisionStatus(@QueryValue long id, @Body VerifyProvision vp) {
        Device d = deviceProvisionService.checkProvisioning(id, vp.getSerialNo(), vp.getSsid());
        return HttpResponse.ok(new ProvisionStatus(
                true, d.getId()));
    }

    @Operation(summary = "Queries info about a device")
    @Get("/{id}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public Device device(@QueryValue long id) {
        return deviceRepository.findById(id).get();
    }

    @Operation(summary = "Reloads the pills on a device")
    @Post("/{id}/reload")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public void reload(@QueryValue long id) {
        stateService.wrapperOf(deviceRepository.findById(id).get())
                .reload();
    }

    @Operation(summary = "Updates device basic settings", description = "Updates non-schedule settings for a device, including timezone, name, and notification token.")
    @Put("/{id}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    @DeviceABAC
    public DeviceUserDTO setDeviceSettings(
            @DeviceABAC(idType = DeviceABACIDType.DEVICE) @PathVariable("id") long deviceID,
            @Body UpdateDeviceUserSettings dto) {
        long userID = authService.getUserID();
        var devUser = deviceUserRepository.findByUserIDAndDeviceIDAndDeletedFalse(userID, deviceID);

        if (dto.deviceName().isPresent()) {
            deviceRepository.update(deviceID, dto.deviceName().get());
        }
        if (dto.notifications().isPresent()) {
            if (dto.notifications().get()) {
                deviceUserRepository.update(devUser.getId(), dto.notificationToken().get());
            } else {
                deviceUserRepository.updateNotificationTokenById(devUser.getId(), null);
            }
        }
        if (dto.timezone().isPresent()) {
            String tzString = dto.timezone().get();
            if (ZoneId.getAvailableZoneIds().contains(tzString)) {
                deviceRepository.updateBaseTZById(deviceID, tzString);
            } else {
                throw Problem.builder().withStatus(new HttpStatusType(HttpStatus.BAD_REQUEST))
                        .withTitle("Invalid timezone")
                        .build();
            }
        }

        return deviceUserRepository.retrieveByUserIDAndDeviceID(userID, deviceID)
                .get();
    }

    @Operation(summary = "App-proxied device sync")
    @Post("/{id}/sync")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    @DeviceABAC
    @Transactional
    public HttpResponse<?> sync(@DeviceABAC(idType = DeviceABACIDType.DEVICE) @PathVariable("id") long deviceID,
            @Body String body) throws InvalidProtocolBufferException {
        long userID = authService.getUserID();
        Device device = deviceRepository.findById(deviceID)
                .orElseThrow(() -> Problem.builder().withStatus(new HttpStatusType(HttpStatus.NOT_FOUND)).build());

        byte[] parsedBody = Base64.getDecoder().decode(body);

        Pill.SyncRequest req = Pill.SyncRequest.parseFrom(parsedBody);
        return HttpResponse.ok(
                Base64.getEncoder().encode(deviceStateService
                        .wrapperOf(device)
                        .sync(req, true)
                        .toByteArray()));
    }

    @Operation(summary = "Get device state on a particular date")
    @Post(value = "/{id}/state", consumes = { MediaType.APPLICATION_FORM_URLENCODED })
    @Secured(SecurityRule.IS_AUTHENTICATED)
    @DeviceABAC
    public DeviceStateDTO consolidatedState(@DeviceABAC(idType = DeviceABACIDType.DEVICE) @PathVariable long id,
            @QueryValue("date") String dateString) throws ParseException {
        DateTimeFormatter formatter = DateTimeFormatter.ISO_LOCAL_DATE;
        TemporalAccessor parsed = formatter.parse(dateString);
        LocalDate date = LocalDate.from(parsed);

        Device device = deviceRepository.findById(id)
                .orElseThrow(() -> Problem.builder().withStatus(new HttpStatusType(HttpStatus.NOT_FOUND)).build());

        return new DeviceStateDTO(
                device.getId(),
                device.getLastSync(),
                deviceStateService.calculateStateFlags(device),
                deviceStateService.buildDosePeriod(device, date),
                device.getBattery(),
                device.isCharging());
    }

}
