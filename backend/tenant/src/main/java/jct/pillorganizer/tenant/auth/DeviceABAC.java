package jct.pillorganizer.tenant.auth;

import io.micronaut.aop.Around;

import java.lang.annotation.Documented;
import java.lang.annotation.Retention;
import java.lang.annotation.Target;

import static java.lang.annotation.ElementType.*;
import static java.lang.annotation.RetentionPolicy.RUNTIME;

@Documented
@Retention(RUNTIME)
@Target({TYPE, METHOD, PARAMETER})
@Around
public @interface DeviceABAC {

    DeviceABACIDType idType() default DeviceABACIDType.NONE;

}
