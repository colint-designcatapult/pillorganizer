package jct.pillorganizer.tenant.repo;

import io.micronaut.data.annotation.Query;
import io.micronaut.data.jdbc.annotation.JdbcRepository;
import io.micronaut.data.model.query.builder.sql.Dialect;
import io.micronaut.data.repository.CrudRepository;
import jct.pillorganizer.tenant.dto.UserInfoDTO;
import jct.pillorganizer.tenant.model.user.User;

@JdbcRepository(dialect = Dialect.POSTGRES)
public interface UserRepository extends CrudRepository<User, String> {

    @Query(value = "select id from users where id = :id")
    UserInfoDTO findUserInfoDTOFromID(String id);

    @Query(value = "INSERT INTO users (id, name, email, user_type) VALUES (:id, :name, :email, 'USER') ON CONFLICT (id) " +
            "DO UPDATE SET name = EXCLUDED.name, email = EXCLUDED.email RETURNING *")
    User upsert(String id, String name, String email);

    @Query(value = "INSERT INTO users (id, user_type) VALUES (:id, 'USER') ON CONFLICT (id) " +
            "DO UPDATE SET id = EXCLUDED.id RETURNING *")
    User saveIdepotent(String id);

}
