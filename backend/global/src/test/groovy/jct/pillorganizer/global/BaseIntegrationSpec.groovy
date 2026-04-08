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



    @Shared
    static PostgreSQLContainer postgres = new PostgreSQLContainer<>("postgres:17.7")
            .withDatabaseName("pillorganizer")
            .withUsername("postgres")
            .withPassword("root")
            .withReuse(true)

    @Shared
    static GenericContainer dynamodb = new GenericContainer(DockerImageName.parse("docker.io/amazon/dynamodb-local:3.3.0"))
            .withCommand("-jar DynamoDBLocal.jar -inMemory -sharedDb")
            .withNetwork(org.testcontainers.containers.Network.SHARED)
            .withNetworkAliases("dynamodb")
            .withExposedPorts(8000)
            .withReuse(true)

    def setupSpec() {
        if (!dynamodb.isRunning()) {
            dynamodb.start()
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
