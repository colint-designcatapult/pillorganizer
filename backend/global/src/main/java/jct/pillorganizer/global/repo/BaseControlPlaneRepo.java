package jct.pillorganizer.global.repo;

import software.amazon.awssdk.enhanced.dynamodb.*;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

public class BaseControlPlaneRepo<T> {
    protected final DynamoDbTable<T> table;
    protected final DynamoDbIndex<T> gsi1;
    protected final DynamoDbIndex<T> gsi2;
    protected final DynamoDbEnhancedClient enhancedClient;

    protected static final String TABLE_NAME = "DeviceControlPlane";

    protected BaseControlPlaneRepo(DynamoDbClient standardClient, Class<T> entityType) {
        this.enhancedClient = DynamoDbEnhancedClient.builder()
                .dynamoDbClient(standardClient)
                .build();

        this.table = enhancedClient.table(TABLE_NAME, TableSchema.fromImmutableClass(entityType));

        // Initialize GSI lookups
        this.gsi1 = this.table.index("GSI1");
        this.gsi2 = this.table.index("GSI2");
    }

    public void save(T entity) {
        this.table.putItem(entity);
    }

    public DynamoDbTable<T> getTable() {
        return table;
    }

    public DynamoDbEnhancedClient getEnhancedClient() {
        return enhancedClient;
    }
}
