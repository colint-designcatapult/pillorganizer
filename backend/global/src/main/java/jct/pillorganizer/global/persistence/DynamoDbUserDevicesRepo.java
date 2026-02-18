package jct.pillorganizer.global.persistence;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.domain.model.Device;
import jct.pillorganizer.global.domain.model.User;
import jct.pillorganizer.global.domain.model.exception.EntityNotFoundException;
import jct.pillorganizer.global.domain.model.view.UserDevicesView;
import jct.pillorganizer.global.domain.repo.cqrs.UserDevicesRepo;
import jct.pillorganizer.global.persistence.entity.BaseControlPlaneEntity;
import jct.pillorganizer.global.persistence.entity.DeviceControlPlaneEntityType;
import jct.pillorganizer.global.persistence.entity.DeviceEntity;
import jct.pillorganizer.global.persistence.entity.DeviceUserAccessEntity;
import jct.pillorganizer.global.persistence.entity.UserEntity;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Singleton
public class DynamoDbUserDevicesRepo extends DynamoDbDeviceControlPlaneRepo<BaseControlPlaneEntity>
        implements UserDevicesRepo {
    @Inject
    public DynamoDbUserDevicesRepo(DynamoDbClient standardClient) {
        super(standardClient, BaseControlPlaneEntity.class);
    }

    @Override
    public Optional<UserDevicesView> get(String userId) {
        Key key  = Key.builder().partitionValue(DeviceUserAccessEntity.gsi1Pk(userId)).build();
        var results = this.gsi1.query(q -> q.queryConditional(QueryConditional.keyEqualTo(key)));

        User user = null;
        List<Device> devices = new ArrayList<>();
        for(var page : results) {
            for(var item : page.items()) {
                if(DeviceControlPlaneEntityType.USER.equals(item.getEntityType())) {
                    user = UserEntity.mapToDomain(item);
                } else if(DeviceControlPlaneEntityType.DEVICE_USER_ACCESS.equals(item.getEntityType())) {
                    devices.add(DeviceEntity.mapToDomain(item));
                }
            }
        }

        if(user == null) {
            throw new EntityNotFoundException("User not found: " + userId);
        }
        return Optional.of(new UserDevicesView(user, devices));
    }
}
