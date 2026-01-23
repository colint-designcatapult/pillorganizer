package jct.pillorganizer.service.fake;

import io.micronaut.context.annotation.Replaces;
import io.micronaut.context.annotation.Requires;
import jakarta.inject.Singleton;
import jct.pillorganizer.service.EmailService;
import jct.pillorganizer.service.TakecareService;
import lombok.extern.flogger.Flogger;

import java.io.IOException;

@Requires(notEnv = "prod")
@Singleton
@Flogger
public class FakeEmailService implements EmailService {
    @Override
    public void sendEmail(String recipientEmail, String subject, String htmlContent) {
        log.atInfo().log("Fake email send to %s, subject: \"%s\"", recipientEmail, subject);
        log.atInfo().log("%s", htmlContent);
    }
}
