package jct.pillorganizer.tenant;

import io.micronaut.runtime.Micronaut;
import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeIn;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;

@SecurityScheme(name = "jwt",
        type = SecuritySchemeType.HTTP,
        in = SecuritySchemeIn.HEADER,
        scheme = "bearer",
        bearerFormat = "jwt"
)
@OpenAPIDefinition(
    info = @Info(
            title = "CabiNET API",
            version = "0.1"
    )
)
@SecurityRequirement(name = "jwt")
public class TenantApplication {

    public static void main(String[] args) {
        Micronaut.run(TenantApplication.class, args);
    }
}
