package jct.pillorganizer.tenant

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.tenant.repo.UserRepository

@MicronautTest
class UserSpec extends BaseIntegrationSpec {

    @Inject
    UserRepository repo;

    def "test"() {
        when:
        var found = repo.findByEmail("test")
        then:
        found.blockOptional().isEmpty()
    }

}
