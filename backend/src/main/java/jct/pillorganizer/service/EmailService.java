package jct.pillorganizer.service;

import java.io.IOException;

public interface EmailService {

    void sendEmail(String recipientEmail, String subject, String htmlContent) throws IOException;

}
