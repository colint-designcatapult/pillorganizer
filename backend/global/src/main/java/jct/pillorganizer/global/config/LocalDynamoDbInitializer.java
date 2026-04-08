package jct.pillorganizer.global.config;

import io.micronaut.context.annotation.Requires;
import io.micronaut.context.event.ApplicationEventListener;
import io.micronaut.runtime.server.event.ServerStartupEvent;
import jakarta.inject.Singleton;
import jct.pillorganizer.global.model.BaseControlPlaneEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import software.amazon.awssdk.enhanced.dynamodb.DynamoDbEnhancedClient;
import software.amazon.awssdk.enhanced.dynamodb.DynamoDbTable;
import software.amazon.awssdk.enhanced.dynamodb.TableSchema;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.ResourceInUseException;

@Singleton
@Requires(env = {"local", "test"})
@Requires(beans = DynamoDbClient.class)
public class LocalDynamoDbInitializer implements ApplicationEventListener<ServerStartupEvent> {

    private static final Logger LOG = LoggerFactory.getLogger(LocalDynamoDbInitializer.class);

    private final DynamoDbClient dynamoDbClient;

    public LocalDynamoDbInitializer(DynamoDbClient dynamoDbClient) {
        this.dynamoDbClient = dynamoDbClient;
    }

    @Override
    public void onApplicationEvent(ServerStartupEvent event) {
        DynamoDbEnhancedClient enhancedClient = DynamoDbEnhancedClient.builder()
                .dynamoDbClient(dynamoDbClient)
                .build();

        DynamoDbTable<BaseControlPlaneEntity> table = enhancedClient.table("DeviceControlPlane", TableSchema.fromImmutableClass(BaseControlPlaneEntity.class));

        try {
            table.createTable();
            LOG.info("DynamoDB Table DeviceControlPlane created successfully.");
        } catch (ResourceInUseException ignored) {
            LOG.info("DynamoDB Table DeviceControlPlane already exists. Skipping creation.");
        } catch (Exception e) {
            LOG.error("Failed to create DynamoDB Table DeviceControlPlane", e);
        }
    }
}
