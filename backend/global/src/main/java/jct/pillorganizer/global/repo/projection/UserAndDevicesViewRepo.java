package jct.pillorganizer.global.repo.projection;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.DeviceUserLinkEntity;
import jct.pillorganizer.global.model.projection.UserAndDevicesView;
import jct.pillorganizer.global.repo.BaseControlPlaneRepo;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.util.List;
import java.util.stream.Collectors;

@Singleton
public class UserAndDevicesViewRepo extends BaseControlPlaneRepo<UserAndDevicesView> {
    @Inject
    public UserAndDevicesViewRepo(DynamoDbClient standardClient) {
        super(standardClient, UserAndDevicesView.class);
    }

    public List<UserAndDevicesView> findAllByUserId(String userId) {
        QueryConditional queryConditional = QueryConditional.keyEqualTo(
                Key.builder()
                        .partitionValue(DeviceUserLinkEntity.pk(userId))
                        .build()
        );

        return this.table.query(queryConditional)
                .stream()
                .flatMap(page -> page.items().stream())
                .collect(Collectors.toList());
    }
}
