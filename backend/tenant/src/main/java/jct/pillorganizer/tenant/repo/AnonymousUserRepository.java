package jct.pillorganizer.tenant.repo;

import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.reactive.ReactorCrudRepository;
import jct.pillorganizer.tenant.model.user.AnonymousUser;

@Repository
public interface AnonymousUserRepository extends ReactorCrudRepository<AnonymousUser, Long> {



}
