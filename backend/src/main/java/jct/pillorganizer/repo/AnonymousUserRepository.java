package jct.pillorganizer.repo;

import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.reactive.ReactorCrudRepository;
import jct.pillorganizer.model.user.AnonymousUser;

@Repository
public interface AnonymousUserRepository extends ReactorCrudRepository<AnonymousUser, Long> {



}
