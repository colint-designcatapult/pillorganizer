package jct.pillorganizer.core.auth;

import io.micronaut.context.annotation.Value;
import io.micronaut.core.annotation.NonNull;
import io.micronaut.core.annotation.Nullable;
import io.micronaut.security.token.Claims;
import io.micronaut.security.token.jwt.validator.GenericJwtClaimsValidator;
import io.micronaut.security.token.jwt.validator.IssuerJwtClaimsValidator;
import io.micronaut.security.token.jwt.validator.JwtClaimsValidatorConfiguration;
import jakarta.inject.Singleton;

@Singleton
public class UserPoolValidator<T> implements GenericJwtClaimsValidator<T> {

    IssuerJwtClaimsValidator<T> publicValidator;
    IssuerJwtClaimsValidator<T> adminValidator;

    public UserPoolValidator(@Value("${app.auth.public.issuer}") String publicIssuer,
                             @Value("${app.auth.admin.issuer}") String adminIssuer) {
        this.publicValidator = new IssuerJwtClaimsValidator<>(new IssuerClaimValidatorConfig(publicIssuer));
        this.adminValidator = new IssuerJwtClaimsValidator<>(new IssuerClaimValidatorConfig(adminIssuer));
    }

    @Override
    public boolean validate(@NonNull Claims claims, T request) {
        if (publicValidator.validate(claims, request)) {
            return true;
        } else return adminValidator.validate(claims, request);
    }

    record IssuerClaimValidatorConfig(String issuer) implements JwtClaimsValidatorConfiguration {
        @Override
        public @Nullable String getAudience() {
            return null;
        }
        @Override
        public @Nullable String getIssuer() {
            return issuer;
        }
        @Override
        public boolean isSubjectNotNull() {
            return true;
        }
        @Override
        public boolean isNotBefore() {
            return false;
        }
        @Override
        public boolean isExpiration() {
            return true;
        }
        @Override
        public boolean isNonce() {
            return true;
        }
        @Override
        public boolean isOpenidIdtoken() {
            return true;
        }}
}
