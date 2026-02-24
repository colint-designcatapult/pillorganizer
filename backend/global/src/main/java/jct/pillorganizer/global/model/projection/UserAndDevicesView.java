package jct.pillorganizer.global.model.projection;

import jct.pillorganizer.global.model.BaseControlPlaneEntity;
import jct.pillorganizer.global.model.DeviceUserLinkEntity;
import jct.pillorganizer.global.model.UserEntity;
import lombok.Builder;
import lombok.Getter;
import lombok.Value;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbFlatten;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbImmutable;

@Value
@Builder
@DynamoDbImmutable(builder = UserAndDevicesView.UserAndDevicesViewBuilder.class)
public class UserAndDevicesView {
    @Getter(onMethod_ = {@DynamoDbFlatten})
    BaseControlPlaneEntity base;

    @Getter(onMethod_ = @DynamoDbAttribute("UserId"))
    String userId;

    @Getter(onMethod_ = @DynamoDbAttribute("UserName"))
    String userName;

    @Getter(onMethod_ = @DynamoDbAttribute("UserSub"))
    String userSub;

    @Getter(onMethod_ = @DynamoDbAttribute("DeviceId"))
    String deviceId;

    @Getter(onMethod_ = @DynamoDbAttribute("PrimaryUser"))
    Boolean primaryUser;

    @Getter(onMethod_ = @DynamoDbAttribute("TenantId"))
    String tenantId;

    @Getter(onMethod_ = @DynamoDbAttribute("ModelId"))
    String modelId;
}
