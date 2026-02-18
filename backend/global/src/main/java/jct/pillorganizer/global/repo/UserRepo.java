package jct.pillorganizer.global.repo;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.UserEntity;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.util.Optional;

@Singleton
public class UserRepo extends BaseControlPlaneRepo<UserEntity> {
    @Inject
    public UserRepo(DynamoDbClient standardClient) {
        super(standardClient, UserEntity.class);
    }

    public Optional<UserEntity> findByUserId(String userId) {
        Key key = Key.builder()
                .partitionValue(UserEntity.pk(userId))
                .sortValue(UserEntity.sk())
                .build();
        return Optional.ofNullable(this.table.getItem(key));
    }
}
