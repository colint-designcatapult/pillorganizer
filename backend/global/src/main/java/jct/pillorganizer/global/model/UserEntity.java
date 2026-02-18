package jct.pillorganizer.global.model;

import lombok.*;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;

@DynamoDbBean
@EqualsAndHashCode(callSuper = true)
@Data
@AllArgsConstructor
@NoArgsConstructor
public class UserEntity extends BaseControlPlaneEntity {
    @Getter(onMethod_ = @DynamoDbAttribute("UserId"))
    private String userId;

    @Getter(onMethod_ = @DynamoDbAttribute("UserName"))
    private String userName;

    public static String pk(String userId) {
        return "USER#" + userId;
    }

    public static String sk() {
        return "METADATA";
    }

    public static String gsi1Pk() {
        return "USER";
    }

    public static String gsi1Sk(String userId) {
        return "USER#" + userId;
    }
}
