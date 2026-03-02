package jct.pillorganizer.tenant.auth;

import io.micronaut.core.convert.ArgumentConversionContext;
import io.micronaut.core.type.Argument;
import io.micronaut.http.HttpRequest;
import io.micronaut.http.bind.binders.TypedRequestArgumentBinder;
import jakarta.inject.Singleton;
import jct.pillorganizer.tenant.model.user.User;

import java.util.Optional;

@Singleton
public class UserTypedRequestArgumentBinder implements TypedRequestArgumentBinder<User> {

    @Override
    public Argument<User> argumentType() {
        return Argument.of(User.class);
    }

    @Override
    public BindingResult<User> bind(ArgumentConversionContext<User> context, HttpRequest<?> source) {
        Optional<User> user = source.getAttribute(UserFilter.USER_ENTITY_ATTRIBUTE, User.class);
        return () -> user;
    }
}
