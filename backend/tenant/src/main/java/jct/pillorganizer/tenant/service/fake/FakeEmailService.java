package jct.pillorganizer.tenant.service.fake;

import io.micronaut.context.annotation.Requires;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.service.EmailService;
import lombok.extern.flogger.Flogger;

@Singleton
@Flogger
public class FakeEmailService implements EmailService {
    @Override
    public void sendEmail(String recipientEmail, String subject, String htmlContent) {
        log.atInfo().log("Fake email send to %s, subject: \"%s\"", recipientEmail, subject);
        log.atInfo().log("%s", htmlContent);
    }
}
