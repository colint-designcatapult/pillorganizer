package jct.pillorganizer

import io.micronaut.test.extensions.spock.annotation.MicronautTest;
import io.micronaut.test.support.TestPropertyProvider;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.containers.localstack.LocalStackContainer;
import org.testcontainers.spock.Testcontainers;
import org.testcontainers.utility.DockerImageName
import org.testcontainers.utility.MountableFile;
import spock.lang.Shared;
import spock.lang.Specification;

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
    static LocalStackContainer localstack = new LocalStackContainer(DockerImageName.parse("localstack/localstack:latest"))
            .withEnv("SERVICES", "sqs,iot,secretsmanager")
            .withCopyFileToContainer(
                    MountableFile.forHostPath("init-aws.sh"),
                    "/etc/localstack/init/ready.d/init-aws.sh"
            )
            .withReuse(true)

    @Override
    Map<String, String> getProperties() {
        if (!postgres.isRunning()) postgres.start()
        if (!localstack.isRunning()) localstack.start()

        return [
                // Postgres Config
                "datasources.default.url": postgres.getJdbcUrl(),
                "datasources.default.username": postgres.getUsername(),
                "datasources.default.password": postgres.getPassword(),

                // AWS Config
                "aws.region": localstack.getRegion(),
                "aws.accessKeyId": localstack.getAccessKey(),
                "aws.secretKey": localstack.getSecretKey(),

                // Endpoint Overrides
                "aws.services.sqs.endpoint-override": localstack.getEndpointOverride(LocalStackContainer.Service.SQS).toString(),
                "aws.services.secretsmanager.endpoint-override": localstack.getEndpointOverride(LocalStackContainer.Service.SECRETSMANAGER).toString(),
                // Todo: add IoT Core endpoint override
        ]
    }
}


