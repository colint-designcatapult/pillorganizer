package jct.pillorganizer.auth;

import java.io.IOException;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import jakarta.validation.Valid;
import io.github.resilience4j.ratelimiter.RateLimiterConfig;
import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.annotation.Body;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Post;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.inject.Inject;
import jct.pillorganizer.dto.ValidateRecoveryCodeDTO;
import jct.pillorganizer.dto.SendRecoveryCodeDTO;
import jct.pillorganizer.repo.UserRepository;
import jct.pillorganizer.service.EmailService;
import reactor.core.publisher.Mono;
import io.github.resilience4j.ratelimiter.RateLimiter;
import java.time.Duration;

/**
 * Handles email via HTTP.
 */
@Controller
public class ForgottenPasswordController {

    @Inject
    private EmailService emailService;

    @Inject
    UserRepository userRepo;

    @Inject
    AuthService authService;

    private final RateLimiter rateSendLimiter;
    private final Map<String, Integer> failedAttempts = new ConcurrentHashMap<>();
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);

    private final int maxValidateTry = 5;

    @Inject
    public ForgottenPasswordController() {
        RateLimiterConfig config = RateLimiterConfig.custom()
                .limitRefreshPeriod(Duration.ofMinutes(1))
                .limitForPeriod(20)
                .build();

        this.rateSendLimiter = RateLimiter.of("myRateSendLimiter", config);

        // Schedule task to clear failed attempts every minute
        scheduler.scheduleAtFixedRate(() -> {
            failedAttempts.clear();
        }, 1, 1, TimeUnit.MINUTES);
    }

    @Post("/api/v1/mail/send_recovery_code")
    @Secured(SecurityRule.IS_ANONYMOUS)
    public Mono<HttpResponse<Void>> sendRecoveryCode(@Body @Valid SendRecoveryCodeDTO dto) {
        if (rateSendLimiter.acquirePermission()) {
            Random random = new Random();
            long recoveryCode = random.nextInt(900000) + 100000;

            try {
                String subject = "Password Recovery Link for Cabinet";
                String htmlContent = "<html><body>" +
                        "<p>Hello,</p>" +
                        "<p>You recently requested to reset your password for your Cabinet account.</p>" +
                        "<p>Please use the following recovery code to set your new password:</p>" +
                        "<p>Recovery Code: <strong>" + recoveryCode + "</strong></p>" +
                        "<p>If you didn't request this change, you can safely ignore this email.</p>" +
                        "<p>Best regards,<br>Your Cabinet Team</p>" +
                        "</body></html>";

                emailService.sendEmail(dto.getSendTo(), subject, htmlContent);
                userRepo.updateUserRecoveryCode(recoveryCode, dto.getSendTo());
                return Mono.just(HttpResponse.accepted());
            } catch (IOException e) {
                e.printStackTrace();
                return Mono.just(HttpResponse.serverError());
            }
        }
        return Mono.just(HttpResponse.status(HttpStatus.TOO_MANY_REQUESTS));
    }

    @Operation(summary = "Validate the recovery code")
    @Post("/api/v1/mail/validate_recovery_code")
    @Secured(SecurityRule.IS_ANONYMOUS)
    public Mono<Boolean> validateRecoveryCode(@Body @Valid ValidateRecoveryCodeDTO dto) {
        int attempts = failedAttempts.getOrDefault(dto.getEmail(), 0);
        if (attempts >= maxValidateTry) {
            return Mono.error(new RuntimeException("Too many attempts. Please try again later."));
        }
        return userRepo.getRecoveryCodeByEmail(dto.getEmail()).map(number ->

        {
            boolean validationSuccessful = (number == dto.getRecoveryCode());
            if (!validationSuccessful) {
                failedAttempts.put(dto.getEmail(), attempts + 1);
            }
            return validationSuccessful;
        }).defaultIfEmpty(false);
    }
}
