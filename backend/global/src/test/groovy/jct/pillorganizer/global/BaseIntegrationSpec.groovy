package jct.pillorganizer.global

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import io.micronaut.test.support.TestPropertyProvider
import org.testcontainers.containers.GenericContainer
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.spock.Testcontainers
import org.testcontainers.utility.DockerImageName
import spock.lang.Shared
import spock.lang.Specification

import software.amazon.awssdk.services.dynamodb.DynamoDbClient
import software.amazon.awssdk.services.dynamodb.model.*
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials
import software.amazon.awssdk.regions.Region

@Testcontainers
@MicronautTest
class BaseIntegrationSpec extends Specification implements TestPropertyProvider {

    static String getInitScriptPath() {
        def file = new File("init-aws.sh")
        if (!file.exists())
            file = new File("../init-aws.sh")
        if (!file.exists())
            throw new FileNotFoundException("Could not find init-aws.sh script")
        return file.absolutePath
    }

    @Shared
    static PostgreSQLContainer postgres = new PostgreSQLContainer<>("postgres:17.7")
            .withDatabaseName("pillorganizer")
            .withUsername("postgres")
            .withPassword("root")
            .withReuse(true)

    @Shared
    static GenericContainer dynamodb = new GenericContainer(DockerImageName.parse("docker.io/amazon/dynamodb-local:latest"))
            .withCommand("-jar DynamoDBLocal.jar -inMemory -sharedDb")
            .withExposedPorts(8000)
            .withReuse(true)

    def setupSpec() {
        def dynamoEndpoint = "http://${dynamodb.getHost()}:${dynamodb.getMappedPort(8000)}"
        def client = DynamoDbClient.builder()
                .endpointOverride(java.net.URI.create(dynamoEndpoint))
                .credentialsProvider(StaticCredentialsProvider.create(AwsBasicCredentials.create("test", "test")))
                .region(Region.CA_CENTRAL_1)
                .build()

        try {
            client.createTable { builder ->
                builder.tableName("DeviceControlPlane")
                       .keySchema(
                           KeySchemaElement.builder().attributeName("PK").keyType(KeyType.HASH).build(),
                           KeySchemaElement.builder().attributeName("SK").keyType(KeyType.RANGE).build()
                       )
                       .attributeDefinitions(
                           AttributeDefinition.builder().attributeName("PK").attributeType("S").build(),
                           AttributeDefinition.builder().attributeName("SK").attributeType("S").build(),
                           AttributeDefinition.builder().attributeName("GSI1_PK").attributeType("S").build(),
                           AttributeDefinition.builder().attributeName("GSI1_SK").attributeType("S").build(),
                           AttributeDefinition.builder().attributeName("GSI2_PK").attributeType("S").build(),
                           AttributeDefinition.builder().attributeName("GSI2_SK").attributeType("S").build()
                       )
                       .globalSecondaryIndexes(
                           GlobalSecondaryIndex.builder()
                               .indexName("GSI1")
                               .keySchema(
                                   KeySchemaElement.builder().attributeName("GSI1_PK").keyType(KeyType.HASH).build(),
                                   KeySchemaElement.builder().attributeName("GSI1_SK").keyType(KeyType.RANGE).build()
                               )
                               .projection(Projection.builder().projectionType("ALL").build())
                               .build(),
                           GlobalSecondaryIndex.builder()
                               .indexName("GSI2")
                               .keySchema(
                                   KeySchemaElement.builder().attributeName("GSI2_PK").keyType(KeyType.HASH).build(),
                                   KeySchemaElement.builder().attributeName("GSI2_SK").keyType(KeyType.RANGE).build()
                               )
                               .projection(Projection.builder().projectionType("ALL").build())
                               .build()
                       )
                       .billingMode(BillingMode.PAY_PER_REQUEST)
            }
        } catch (ResourceInUseException ignored) {
            // Already created
        }
    }

    @Override
    Map<String, String> getProperties() {
        if (!postgres.isRunning()) postgres.start()
        if (!dynamodb.isRunning()) dynamodb.start()

        def dynamoEndpoint = "http://${dynamodb.getHost()}:${dynamodb.getMappedPort(8000)}"

        return [
                // Postgres Config
                "datasources.default.url": postgres.getJdbcUrl(),
                "datasources.default.username": postgres.getUsername(),
                "datasources.default.password": postgres.getPassword(),
                "datasources.default.driverClassName": "org.postgresql.Driver",
                "datasources.default.allow-pool-suspension": "true",
                "flyway.datasources.default.enabled": "true",

                // AWS Config
                "aws.region": "ca-central-1",
                "aws.accessKeyId": "test",
                "aws.secretKey": "test",

                // Endpoint Overrides
                "aws.services.dynamodb.endpoint-override": dynamoEndpoint
        ]
    }
}
