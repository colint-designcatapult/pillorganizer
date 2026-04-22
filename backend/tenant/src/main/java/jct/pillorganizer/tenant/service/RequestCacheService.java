package jct.pillorganizer.tenant.service;

import io.micronaut.http.HttpRequest;
import io.micronaut.http.context.ServerRequestContext;
import io.micronaut.security.utils.SecurityService;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.model.device.DeviceUser;
import jct.pillorganizer.tenant.model.user.User;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import io.micronaut.data.annotation.event.PostPersist;
import io.micronaut.data.annotation.event.PostUpdate;

@Singleton
public class RequestCacheService {

    public static final String USER_ID_ATTRIBUTE = "userId";
    public static final String USER_ENTITY_ATTRIBUTE = "userEntity";
    public static final String USER_DEVICES_ATTRIBUTE = "userDevices";

    @Inject
    SecurityService securityService;

    @Inject
    UserService userService;

    public void processRequest(HttpRequest<?> request) {
        var auth = securityService.getAuthentication();
        if (auth.isEmpty()) {
            return; // Anonymous request
        }

        Object userId = auth.get().getAttributes().get("userId");
        if (userId == null) {
            return;
        }

        String userIdString = userId.toString();

        request.setAttribute(USER_ID_ATTRIBUTE, userIdString);

        User user = userService.ensureExists(userIdString);
        request.setAttribute(USER_ENTITY_ATTRIBUTE, user);

        Map<String, DeviceUser> deviceMap = userService.getDeviceUserMap(userIdString);
        request.setAttribute(USER_DEVICES_ATTRIBUTE, deviceMap);
    }

    public static Optional<User> getUser(HttpRequest<?> request) {
        return request.getAttribute(USER_ENTITY_ATTRIBUTE, User.class);
    }

    public static Optional<DeviceUser> getDevice(HttpRequest<?> request, String deviceId) {
        return request.getAttribute(USER_DEVICES_ATTRIBUTE, Map.class)
                .map(map -> (DeviceUser) map.get(deviceId));
    }

    @SuppressWarnings("unchecked")
    public static Map<String, DeviceUser> getDevices(HttpRequest<?> request) {
        return request.getAttribute(USER_DEVICES_ATTRIBUTE, Map.class)
                .orElse(Map.of());
    }

    public static Optional<User> getUser() {
        return ServerRequestContext.currentRequest()
                .flatMap(RequestCacheService::getUser);
    }

    public static Optional<DeviceUser> getDevice(String deviceId) {
        return ServerRequestContext.currentRequest()
                .flatMap(req -> getDevice(req, deviceId));
    }

    public static Map<String, DeviceUser> getDevices() {
        return ServerRequestContext.currentRequest()
                .map(RequestCacheService::getDevices)
                .orElseGet(Map::of);
    }

    @PostPersist
    @PostUpdate
    public void onUserUpdate(User user) {
        ServerRequestContext.currentRequest().ifPresent(req -> {
            Optional<User> currentUser = getUser(req);
            if (currentUser.isPresent() && currentUser.get().getId().equals(user.getId())) {
                req.setAttribute(USER_ENTITY_ATTRIBUTE, user);
            }
        });
    }

    @PostPersist
    @PostUpdate
    public void onDeviceUserUpdate(DeviceUser deviceUser) {
        ServerRequestContext.currentRequest().ifPresent(req -> {
            Optional<User> currentUser = getUser(req);
            // Protect against deviceUser.getUser() or deviceUser.getDevice() being lazily
            // uninitialized or null
            if (currentUser.isPresent() && deviceUser.getUser() != null && deviceUser.getDevice() != null
                    && currentUser.get().getId().equals(deviceUser.getUser().getId())) {
                Map<String, DeviceUser> currentDevices = getDevices(req);
                Map<String, DeviceUser> updatedDevices = new HashMap<>(currentDevices);
                updatedDevices.put(deviceUser.getDevice().getId(), deviceUser);
                req.setAttribute(USER_DEVICES_ATTRIBUTE, updatedDevices);
            }
        });
    }
}
