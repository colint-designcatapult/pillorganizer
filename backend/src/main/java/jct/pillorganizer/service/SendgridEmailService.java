package jct.pillorganizer.service;

import com.sendgrid.Method;
import com.sendgrid.Request;
import com.sendgrid.SendGrid;
import com.sendgrid.helpers.mail.Mail;
import com.sendgrid.helpers.mail.objects.Content;
import com.sendgrid.helpers.mail.objects.Email;
import io.micronaut.context.annotation.Requires;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import io.micronaut.context.annotation.Value;
import lombok.extern.flogger.Flogger;

import java.io.IOException;

@Requires(env = "prod")
@Singleton
@Flogger
class SendgridEmailService implements EmailService {

    private final String apiKey;
    private final String emailSender;

    @Inject
    public SendgridEmailService(@Value("${sendgrid.api-key}") String apiKey,
                                @Value("${email.sender}") String emailSender) {
        this.apiKey = apiKey;
        this.emailSender = emailSender;
    }

    @Override
    public void sendEmail(String recipientEmail, String subject, String htmlContent) throws IOException {
        Email from = new Email(emailSender);
        Email to = new Email(recipientEmail);

        Content content = new Content("text/html", htmlContent);

        Mail mail = new Mail(from, subject, to, content);

        SendGrid sg = new SendGrid(apiKey);
        Request request = new Request();

        request.setMethod(Method.POST);
        request.setEndpoint("mail/send");
        request.setBody(mail.build());
        sg.api(request);
    }
}
