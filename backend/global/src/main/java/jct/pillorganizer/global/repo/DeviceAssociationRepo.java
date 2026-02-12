package jct.pillorganizer.global.repo;

import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.DeviceAssociation;
import software.amazon.awssdk.enhanced.dynamodb.DynamoDbEnhancedClient;
import software.amazon.awssdk.enhanced.dynamodb.DynamoDbTable;
import software.amazon.awssdk.enhanced.dynamodb.TableSchema;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

@Singleton
public class DeviceAssociationRepo {

    private final DynamoDbTable<DeviceAssociation> table;

    public DeviceAssociationRepo(DynamoDbClient standardClient) {
        DynamoDbEnhancedClient enhancedClient = DynamoDbEnhancedClient.builder()
                .dynamoDbClient(standardClient)
                .build();

        this.table = enhancedClient.table("DeviceAssociation", TableSchema.fromBean(DeviceAssociation.class));
    }

}
