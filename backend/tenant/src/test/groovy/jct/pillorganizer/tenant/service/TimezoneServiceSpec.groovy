package jct.pillorganizer.tenant.service

// @relation(UN-102, scope=file)
// @relation(UN-101, scope=file)
// @relation(UN-105, scope=file)
import com.fasterxml.jackson.databind.ObjectMapper
import io.micronaut.jackson.databind.JacksonDatabindMapper
import spock.lang.Specification
import spock.lang.Subject

class TimezoneServiceSpec extends Specification {

    @Subject
    TimezoneService timezoneService = new TimezoneService(new JacksonDatabindMapper(new ObjectMapper()))

    def "should convert known IANA timezone to POSIX string"() {
        expect:
        timezoneService.toPosix("America/New_York") == "EST5EDT,M3.2.0,M11.1.0"
        timezoneService.toPosix("America/Los_Angeles") == "PST8PDT,M3.2.0,M11.1.0"
        timezoneService.toPosix("Europe/Paris") == "CET-1CEST,M3.5.0,M10.5.0/3"
        timezoneService.toPosix("Etc/UTC") == "UTC0"
    }

    def "should throw for unknown IANA timezone"() {
        when:
        timezoneService.toPosix("Mars/Olympus_Mons")

        then:
        def e = thrown(IllegalArgumentException)
        e.message.contains("Unknown IANA timezone")
    }

    def "should throw for null timezone"() {
        when:
        timezoneService.toPosix(null)

        then:
        def e = thrown(IllegalArgumentException)
        e.message.contains("null or blank")
    }

    def "should throw for blank timezone"() {
        when:
        timezoneService.toPosix("   ")

        then:
        def e = thrown(IllegalArgumentException)
        e.message.contains("null or blank")
    }
}
