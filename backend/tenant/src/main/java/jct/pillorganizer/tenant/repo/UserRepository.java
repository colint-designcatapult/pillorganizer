package jct.pillorganizer.tenant.repo;

import jakarta.annotation.Nullable;

import io.micronaut.data.annotation.Query;
import io.micronaut.data.annotation.Repository;
import io.micronaut.data.repository.reactive.ReactorCrudRepository;
import jct.pillorganizer.tenant.dto.UserInfoDTO;
import jct.pillorganizer.tenant.model.user.User;
import reactor.core.publisher.Mono;

@Repository
public interface UserRepository extends ReactorCrudRepository<User, Long> {

    Mono<User> findByEmail(String email);

    Mono<Integer> countByEmail(String email);

    @Query(value = "select new jct.pillorganizer.dto.UserInfoDTO(id, email, case when takecarePatientId is not null then true else false end) from users where id = :id")
    Mono<UserInfoDTO> findUserInfoDTOFromID(long id);

    @Query("UPDATE users u SET u.recoveryCode = :recoveryCode WHERE u.email = :email")
    void updateUserRecoveryCode(@Nullable Long recoveryCode, String email);

    @Query("UPDATE users u SET u.takecarePatientId = :takecarePatientId WHERE u.id = :userId")
    Mono<Integer> updateTakecarePatientIdById(String takecarePatientId, Long userId);

    Mono<Long> getRecoveryCodeByEmail(String email);

}
