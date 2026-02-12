package jct.pillorganizer.global.repo;

import com.github.ksuid.Ksuid;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.DeviceRegistry;
import software.amazon.awssdk.enhanced.dynamodb.DynamoDbEnhancedClient;
import software.amazon.awssdk.enhanced.dynamodb.DynamoDbTable;
import software.amazon.awssdk.enhanced.dynamodb.TableSchema;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.time.Instant;

@Singleton
public class DeviceRegistryRepo {

    private final DynamoDbTable<DeviceRegistry> table;

    public DeviceRegistryRepo(DynamoDbClient standardClient) {
        DynamoDbEnhancedClient enhancedClient = DynamoDbEnhancedClient.builder()
                .dynamoDbClient(standardClient)
                .build();

        this.table = enhancedClient.table("DeviceRegistry", TableSchema.fromBean(DeviceRegistry.class));
    }

}
