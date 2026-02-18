package jct.pillorganizer.global.persistence;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.domain.model.Device;
import jct.pillorganizer.global.domain.model.DeviceUserAccess;
import jct.pillorganizer.global.domain.model.User;
import jct.pillorganizer.global.domain.model.exception.EntityNotFoundException;
import jct.pillorganizer.global.domain.model.view.DeviceUsersView;
import jct.pillorganizer.global.domain.model.view.UserDevicesView;
import jct.pillorganizer.global.domain.repo.cqrs.DeviceUsersRepo;
import jct.pillorganizer.global.persistence.entity.BaseControlPlaneEntity;
import jct.pillorganizer.global.persistence.entity.DeviceControlPlaneEntityType;
import jct.pillorganizer.global.persistence.entity.DeviceEntity;
import jct.pillorganizer.global.persistence.entity.DeviceUserAccessEntity;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.QueryConditional;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Singleton
public class DynamoDbDeviceUsersRepo extends DynamoDbDeviceControlPlaneRepo<BaseControlPlaneEntity>
        implements DeviceUsersRepo {

    @Inject
    public DynamoDbDeviceUsersRepo(DynamoDbClient standardClient) {
        super(standardClient, BaseControlPlaneEntity.class);
    }

    @Override
    public Optional<DeviceUsersView> get(String deviceId) {
        Key key  = Key.builder().partitionValue(DeviceUserAccessEntity.pk(deviceId)).build();
        var results = this.table.query(q -> q.queryConditional(QueryConditional.keyEqualTo(key)));

        Device device = null;
        List<DeviceUserAccess> users = new ArrayList<>();
        for(var page : results) {
            for(var item : page.items()) {
                if(DeviceControlPlaneEntityType.DEVICE.equals(item.getEntityType())) {
                    device = DeviceEntity.mapToDomain(item);
                } else if(DeviceControlPlaneEntityType.DEVICE_USER_ACCESS.equals(item.getEntityType())) {
                    users.add(DeviceUserAccessEntity.mapToDomain(item));
                }
            }
        }

        if(device == null) {
            throw new EntityNotFoundException("Device not found: " + deviceId);
        }
        return Optional.of(new DeviceUsersView(device, users));
    }
}
