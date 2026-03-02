package jct.pillorganizer.core.service;

import io.micronaut.crac.OrderedResource;
import jakarta.inject.Singleton;
import org.crac.Context;
import org.crac.Resource;

import java.security.SecureRandom;
import java.util.Base64;

@Singleton
public class SecureRandomService implements OrderedResource {
    private SecureRandom secureRandom;

    public SecureRandomService() {
        this.secureRandom = new SecureRandom();
    }

    public SecureRandom getSecureRandom() {
        return secureRandom;
    }

    public String generateRandomString(int byteLen) {
        byte[] bytes = new byte[byteLen];
        this.secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().encodeToString(bytes);
    }

    public String generateRandomToken() {
        return generateRandomString(16);
    }

    // CRaC

    @Override
    public void beforeCheckpoint(Context<? extends Resource> context) throws Exception {
        this.secureRandom = null;
    }

    @Override
    public void afterRestore(Context<? extends Resource> context) throws Exception {
        this.secureRandom = new SecureRandom();
    }
}
