package jct.pillorganizer.global.persistence;

import jct.pillorganizer.global.persistence.entity.BaseControlPlaneEntity;
import software.amazon.awssdk.enhanced.dynamodb.*;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;


public class DynamoDbDeviceControlPlaneRepo<T extends BaseControlPlaneEntity> {

    protected final DynamoDbTable<T> table;
    protected final DynamoDbIndex<T> gsi1;
    protected final DynamoDbIndex<T> gsi2;

    protected static final String TABLE_NAME = "DeviceControlPlane";

    protected DynamoDbDeviceControlPlaneRepo(DynamoDbClient standardClient, Class<T> entityType) {
        DynamoDbEnhancedClient enhancedClient = DynamoDbEnhancedClient.builder()
                .dynamoDbClient(standardClient)
                .build();

        this.table = enhancedClient.table(TABLE_NAME, TableSchema.fromBean(entityType));
        
        // Initialize GSI lookups
        this.gsi1 = this.table.index("GSI1");
        this.gsi2 = this.table.index("GSI2");
    }

}
