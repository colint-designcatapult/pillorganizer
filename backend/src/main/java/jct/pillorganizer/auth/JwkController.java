package jct.pillorganizer.auth;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.Produces;
import io.micronaut.security.annotation.Secured;
import io.micronaut.security.rules.SecurityRule;
import jakarta.inject.Inject;

import java.util.Map;

@Controller
public class JwkController {

    @Inject
    JwtIssuerService service;

    @Get("/jwk-set.json")
    @Produces(single = true)
    @Secured(SecurityRule.IS_ANONYMOUS)
    Map<String, Object> getJWKS() {
        return service.getJWKS();
    }

}
