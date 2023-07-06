package jct.pillorganizer.service;

import com.google.auth.oauth2.ServiceAccountCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.*;
import io.micronaut.context.annotation.Value;
import jakarta.inject.Singleton;
import jct.pillorganizer.dto.DeviceNotificationDetails;
import lombok.extern.flogger.Flogger;

import java.io.IOException;

/**
 * Service to send push notifications to registered mobile phones.
 */
@Singleton
@Flogger
public class FirebaseMessageService {

    public FirebaseMessageService(@Value("${firebase.privkey}") String privKey,
                                  @Value("${firebase.project}") String projID,
                                  @Value("${firebase.email}") String email) throws IOException {
        String privkey = privKey.replace("\\n", "\n");
        FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(ServiceAccountCredentials.newBuilder()
                        .setProjectId(projID)
                        .setPrivateKeyString(privkey)
                        .setClientEmail(email)
                        .build())
                .build();
        FirebaseApp.initializeApp(options);
    }

    /**
     * Sends a pill reminder notification to a specific notification token.
     * @param details a structure containing the info necessary to deliver a push notification
     */
    public void sendPillReminderNotification(DeviceNotificationDetails details) {

        if(details.notificationToken() == null || details.notificationToken().isEmpty())
            return;

        log.atInfo().log("Sending to %s", details.notificationToken());

        try {

            Message message = Message.builder()
                .setNotification(Notification.builder()
                        .setTitle("Pill Organizer")
                        .setBody(String.format("(#%d-%s) It's time to take your pills!", details.deviceID(), details.deviceName()))
                        .build())
                .setAndroidConfig(AndroidConfig.builder()
                        .setTtl(3600)
                        .setNotification(AndroidNotification.builder()
                                .setColor("#f45342")
                                .build())
                        .build())
                .setApnsConfig(ApnsConfig.builder()
                        .setAps(Aps.builder().build())
                        .build())
                .setToken(details.notificationToken())
                .build();

            FirebaseMessaging.getInstance().send(message);
        } catch (FirebaseMessagingException e) {
            e.printStackTrace();
            // yes this is bad, just eat the error for now
        }
    }

}
