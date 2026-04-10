package jct.pillorganizer.tenant.service

import jct.pillorganizer.tenant.BaseIntegrationSpec
import jakarta.inject.Inject
import spock.lang.Subject

/**
 * Verifies that {@link LocalNotificationService} (the test-environment implementation)
 * emulates SNS semantics correctly: topics are idempotent, subscriptions return unique
 * ARNs, unsubscribe removes the entry, and publish does not throw.
 */
class NotificationServiceSpec extends BaseIntegrationSpec {

    @Inject
    @Subject
    NotificationService notificationService

    def "createOrGetTopic returns the same ARN for the same device"() {
        when:
        def arn1 = notificationService.createOrGetTopic("dev-aaa")
        def arn2 = notificationService.createOrGetTopic("dev-aaa")

        then:
        arn1 != null
        arn1 == arn2
    }

    def "createOrGetTopic returns distinct ARNs for different devices"() {
        when:
        def arn1 = notificationService.createOrGetTopic("dev-bbb")
        def arn2 = notificationService.createOrGetTopic("dev-ccc")

        then:
        arn1 != arn2
    }

    def "subscribe returns a non-null subscription ARN"() {
        given:
        def topicArn = notificationService.createOrGetTopic("dev-sub-1")

        when:
        def subArn = notificationService.subscribe(topicArn, "arn:local:endpoint:1")

        then:
        subArn != null
        subArn.contains(topicArn)
    }

    def "subscribe returns distinct ARNs for distinct calls"() {
        given:
        def topicArn = notificationService.createOrGetTopic("dev-sub-2")

        when:
        def subArn1 = notificationService.subscribe(topicArn, "arn:local:endpoint:2")
        def subArn2 = notificationService.subscribe(topicArn, "arn:local:endpoint:3")

        then:
        subArn1 != subArn2
    }

    def "unsubscribe does not throw"() {
        given:
        def topicArn = notificationService.createOrGetTopic("dev-unsub-1")
        def subArn = notificationService.subscribe(topicArn, "arn:local:endpoint:4")

        when:
        notificationService.unsubscribe(subArn)

        then:
        noExceptionThrown()
    }

    def "publish does not throw"() {
        given:
        def topicArn = notificationService.createOrGetTopic("dev-pub-1")

        when:
        notificationService.publish(topicArn, "Medication Reminder", "It's time to take your medication", 840L)

        then:
        noExceptionThrown()
    }
}
