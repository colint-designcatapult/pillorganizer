package jct.pillorganizer.global.repo;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.UserEntity;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Singleton
public class UserRepo extends BaseControlPlaneRepo<UserEntity> {
    @Inject
    public UserRepo(DynamoDbClient standardClient) {
        super(standardClient, UserEntity.class);
    }

    public List<UserEntity> findAllByUserId(String userId) {
        QueryConditional queryConditional = QueryConditional.sortBeginsWith(
                Key.builder()
                        .partitionValue(UserEntity.pk(userId))
                        .sortValue(UserEntity.sk(""))
                        .build());

        return this.table.query(queryConditional)
                .items()
                .stream()
                .collect(Collectors.toList());
    }

    public Optional<UserEntity> findBySub(String sub) {
        QueryConditional queryConditional = QueryConditional.keyEqualTo(
                Key.builder()
                        .partitionValue(UserEntity.gsi2Pk(sub))
                        .sortValue(UserEntity.gsi2Sk())
                        .build());

        return this.gsi2.query(queryConditional)
                .stream()
                .flatMap(page -> page.items().stream())
                .findFirst();
    }
}
