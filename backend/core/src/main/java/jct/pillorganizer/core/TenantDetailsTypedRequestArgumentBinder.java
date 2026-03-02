package jct.pillorganizer.core;

import io.micronaut.core.convert.ArgumentConversionContext;
import io.micronaut.core.type.Argument;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.bind.binders.TypedRequestArgumentBinder;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.core.service.TenantService;

import java.util.Optional;

@Singleton
public class TenantDetailsTypedRequestArgumentBinder implements TypedRequestArgumentBinder<TenantDetails> {
    // Defined in io.micronaut.multitenancy.filter.TenantResolverFilter but it's package local so we
    // can't reference it.
    private static final String ATTRIBUTE_TENANT = "tenantIdentifier";

    @Inject
    TenantService tenantService;

    @Override
    public Argument<TenantDetails> argumentType() {
        return Argument.of(TenantDetails.class);
    }

    @Override
    public BindingResult<TenantDetails> bind(ArgumentConversionContext<TenantDetails> context, HttpRequest<?> source) {
        if (!source.getAttributes().contains(ATTRIBUTE_TENANT)) {
            return BindingResult.UNSATISFIED;
        }
        Optional<String> tenantOptional = source.getAttribute(ATTRIBUTE_TENANT, String.class);
        if (tenantOptional.isEmpty()) {
            return BindingResult.EMPTY;
        }
        return () -> tenantService.getTenantDetails(tenantOptional.get());
    }
}
