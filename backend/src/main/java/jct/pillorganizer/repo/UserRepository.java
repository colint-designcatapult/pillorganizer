package jct.pillorganizer.repo;

import io.micronaut.data.annotation.Query;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.reactive.ReactorCrudRepository;
import jct.pillorganizer.dto.UserInfoDTO;
import jct.pillorganizer.model.user.User;
import reactor.core.publisher.Mono;

@Repository
public interface UserRepository extends ReactorCrudRepository<User, Long> {

    Mono<User> findByEmail(String email);

    Mono<Integer> countByEmail(String email);

    @Query(nativeQuery = true, readOnly = false, value = "update users set user_type = 1, email = :email, " +
            "password_hash = :passwordHash where id = :id and user_type = 2")
    Mono<Integer> upgradeAnonymousUser(long id, String email, byte[] passwordHash);

    @Query(value = "select new jct.pillorganizer.dto.UserInfoDTO(id, email) from users where id = :id")
    Mono<UserInfoDTO> findUserInfoDTOFromID(long id);

}
