package jct.pillorganizer.global.persistence.entity;

import jct.pillorganizer.global.domain.model.User;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;

@DynamoDbBean
public class UserEntity extends BaseControlPlaneEntity {

    public static UserEntity from(User user) {
        UserEntity entity = new UserEntity();
        entity.setPk(pk(user.userId()));
        entity.setSk(skMetadata());
        entity.setGsi1Pk(gsi1Pk(user.userId()));
        entity.setGsi1Sk(gsi1Sk());
        entity.setEntityType(DeviceControlPlaneEntityType.USER);
        
        entity.setUserId(user.userId());
        entity.setEmail(user.email());
        entity.setUserName(user.name());
        entity.setVersion(user.version());
        return entity;
    }

    public static User mapToDomain(BaseControlPlaneEntity entity) {
        return new User(entity.getUserId(), entity.getEmail(), entity.getUserName(), entity.getVersion());
    }
    
    public static String pk(String userId) {
        return "USER#" + userId;
    }
    public static String skMetadata() {
        return "METADATA";
    }
    public static String gsi1Pk(String userId) {
        return "USER#" + userId;
    }
    public static String gsi1Sk() {
        return "METADATA";
    }

}
