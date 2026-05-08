package jct.pillorganizer.global.repo;

import io.micronaut.core.annotation.Nullable;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.UserEntity;
import software.amazon.awssdk.enhanced.dynamodb.Expression;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.Page;
import software.amazon.awssdk.enhanced.dynamodb.model.PutItemEnhancedRequest;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryEnhancedRequest;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Singleton
public class UserRepo extends BaseControlPlaneRepo<UserEntity> {
    @Inject
    public UserRepo(DynamoDbClient standardClient) {
        super(standardClient, UserEntity.class);
    }

    @Override
    public void save(UserEntity entity) {
        Expression condition = Expression.builder()
                .expression("attribute_not_exists(PK)")
                .build();

        PutItemEnhancedRequest<UserEntity> request = PutItemEnhancedRequest.builder(UserEntity.class)
                .item(entity)
                .conditionExpression(condition)
                .build();

        this.table.putItem(request);
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

    /**
     * Returns a single page of all users (up to {@code size}), queried via GSI1.
     * Optional {@code userIdFilter} narrows results to users whose userId begins with the filter.
     * Pass {@code cursor} from the previous page's {@link PageResult#nextCursor()} to advance;
     * pass {@code null} to start from the beginning.
     */
    public PageResult<UserEntity> findAllPaginated(int size, @Nullable String cursor, @Nullable String userIdFilter) {
        Map<String, AttributeValue> exclusiveStartKey = DynamoDbCursorUtil.decode(cursor);

        String skPrefix = (userIdFilter != null && !userIdFilter.isBlank())
                ? UserEntity.gsi1Sk(userIdFilter)
                : UserEntity.gsi1Sk("");

        QueryEnhancedRequest.Builder requestBuilder = QueryEnhancedRequest.builder()
                .queryConditional(QueryConditional.sortBeginsWith(
                        Key.builder()
                                .partitionValue(UserEntity.gsi1Pk())
                                .sortValue(skPrefix)
                                .build()))
                .limit(size);

        if (exclusiveStartKey != null) {
            requestBuilder.exclusiveStartKey(exclusiveStartKey);
        }

        Page<UserEntity> page = this.gsi1.query(requestBuilder.build()).iterator().next();
        return new PageResult<>(page.items(), DynamoDbCursorUtil.encode(page.lastEvaluatedKey()));
    }

    public PageResult<UserEntity> findAllPaginated(int size, @Nullable String cursor) {
        return findAllPaginated(size, cursor, null);
    }

    public Optional<UserEntity> findByEmail(String email) {
        QueryConditional queryConditional = QueryConditional.sortBeginsWith(
                Key.builder()
                        .partitionValue(UserEntity.gsi1Pk())
                        .sortValue(UserEntity.gsi1Sk(""))
                        .build());

        Expression filterExpression = Expression.builder()
                .expression("Email = :email")
                .expressionValues(Map.of(":email", AttributeValue.builder().s(email.toLowerCase()).build()))
                .build();

        QueryEnhancedRequest request = QueryEnhancedRequest.builder()
                .queryConditional(queryConditional)
                .filterExpression(filterExpression)
                .build();

        return this.gsi1.query(request)
                .stream()
                .flatMap(page -> page.items().stream())
                .findFirst();
    }

    public void updateFcmEndpointArn(UserEntity user, String fcmEndpointArn) {
        UserEntity updated = user.toBuilder()
                .fcmEndpointArn(fcmEndpointArn)
                .build();
        this.table.putItem(updated);
    }

    public void delete(UserEntity user) {
        this.table.deleteItem(Key.builder()
                .partitionValue(UserEntity.pk(user.getUserId()))
                .sortValue(UserEntity.sk(user.getUserSub()))
                .build());
    }
}

