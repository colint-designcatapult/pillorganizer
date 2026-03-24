package jct.pillorganizer.tenant

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
    static LocalStackContainer localstack = new LocalStackContainer(DockerImageName.parse("localstack/localstack:latest"))
            .withEnv([
                    "DEFAULT_REGION": "ca-central-1",
                    "SERVICES": "sqs,iot,secretsmanager",
                    "ENVIRONMENT_KEY": "test",
                    "LOCALSTACK_ACKNOWLEDGE_ACCOUNT_REQUIREMENT": "1"
            ])
            .withCopyFileToContainer(
                    MountableFile.forHostPath(getInitScriptPath(), 0777),
                    "/etc/localstack/init/ready.d/init-aws.sh"
            )
            .withReuse(true)

    @Override
    Map<String, String> getProperties() {
        if (!postgres.isRunning()) postgres.start()
        if (!localstack.isRunning()) localstack.start()

        def sqsEndpoint = localstack.getEndpointOverride(LocalStackContainer.Service.SQS).toString()

        return [
                // Postgres Config
                "datasources.default.url": postgres.getJdbcUrl(),
                "datasources.default.username": postgres.getUsername(),
                "datasources.default.password": postgres.getPassword(),
                "datasources.default.driverClassName": "org.postgresql.Driver",
                "datasources.default.allow-pool-suspension": "true",
                "flyway.datasources.default.enabled": "true",

                // AWS Config
                "aws.region": localstack.getRegion(),
                "aws.accessKeyId": localstack.getAccessKey(),
                "aws.secretKey": localstack.getSecretKey(),

                // Endpoint Overrides
                "aws.services.sqs.endpoint-override": localstack.getEndpointOverride(LocalStackContainer.Service.SQS).toString(),
        ]
    }
}


