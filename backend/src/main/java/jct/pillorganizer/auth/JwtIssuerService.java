package jct.pillorganizer.auth;

import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSSigner;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import io.micronaut.context.annotation.Value;
import jakarta.inject.Singleton;
import org.postgresql.shaded.com.ongres.scram.common.bouncycastle.base64.Base64;

import java.nio.charset.StandardCharsets;
import java.text.ParseException;
import java.util.Map;

@Singleton
public class JwtIssuerService {

    final JWKSet keySet;
    final JWSSigner signer;
    JwtIssuerService(@Value("${issuer.jwk}") String jwkEncoded) throws ParseException, JOSEException {
        String jwkDecoded = new String(Base64.decode(jwkEncoded), StandardCharsets.UTF_8);
        RSAKey jwk = RSAKey.parse(jwkDecoded);
        assert(jwk.isPrivate());
        keySet = new JWKSet(jwk.toPublicJWK())
                .toPublicJWKSet();                  // Important! Strip out all private keys
        signer = new RSASSASigner(jwk);
    }

    Map<String, Object> getJWKS() {
        return keySet.toJSONObject();
    }

}
