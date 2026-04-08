package jct.pillorganizer.tenant

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import io.micronaut.test.support.TestPropertyProvider
import org.testcontainers.containers.GenericContainer
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.spock.Testcontainers
import org.testcontainers.utility.DockerImageName
import spock.lang.Shared
import spock.lang.Specification

@Testcontainers
@MicronautTest
class BaseIntegrationSpec extends Specification implements TestPropertyProvider {



    @Shared
    static PostgreSQLContainer postgres = new PostgreSQLContainer<>("postgres:17.7")
            .withDatabaseName("pillorganizer")
            .withUsername("postgres")
            .withPassword("root")
            .withReuse(true)

    @Override
    Map<String, String> getProperties() {
        if (!postgres.isRunning()) postgres.start()

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
                "aws.secretKey": "test"
        ]
    }
}
