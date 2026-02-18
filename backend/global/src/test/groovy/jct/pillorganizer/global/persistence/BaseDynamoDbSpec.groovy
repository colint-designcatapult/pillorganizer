package jct.pillorganizer.global.persistence

import io.micronaut.test.extensions.spock.annotation.MicronautTest
import jakarta.inject.Inject
import jct.pillorganizer.global.BaseIntegrationSpec
import software.amazon.awssdk.services.dynamodb.DynamoDbClient
import software.amazon.awssdk.services.dynamodb.model.AttributeValue
import software.amazon.awssdk.services.dynamodb.model.DeleteItemRequest
import software.amazon.awssdk.services.dynamodb.model.GetItemRequest
import software.amazon.awssdk.services.dynamodb.model.PutItemRequest
import software.amazon.awssdk.services.dynamodb.model.ScanRequest
import software.amazon.awssdk.services.dynamodb.model.UpdateItemRequest
import spock.lang.Shared

@MicronautTest
abstract class BaseDynamoDbSpec extends BaseIntegrationSpec {

    @Inject
    @Shared
    protected DynamoDbClient dynamoDbClient

    protected abstract String tableName();

    def cleanup() {
        def scanRequest = ScanRequest.builder().tableName(tableName()).build()
        def scanResponse = dynamoDbClient.scan(scanRequest)

        scanResponse.items().each { item ->
            def key = [
                    "PK": item.get("PK")
            ]
            if (item.containsKey("SK"))
                key["SK"] = item.get("SK")
            def deleteRequest = DeleteItemRequest.builder()
                    .tableName(tableName())
                    .key(key)
                    .build()
            dynamoDbClient.deleteItem(deleteRequest)
        }
    }

    /**
     * Helper to manually insert data via the raw client (For the 'Given' block)
     */
    void insertRawRecord(Map<String, Object> itemData) {
        // Convert simple Groovy Map to AWS AttributeValues
        def itemValues = itemData.collectEntries { key, value ->
            def attrVal
            if (value instanceof Number) {
                attrVal = AttributeValue.builder().n(value.toString()).build()
            } else if (value instanceof Boolean) {
                attrVal = AttributeValue.builder().bool(value).build()
            } else {
                attrVal = AttributeValue.builder().s(value.toString()).build()
            }
            [(key): attrVal]
        }

        def request = PutItemRequest.builder()
                .tableName(tableName())
                .item(itemValues)
                .build()

        dynamoDbClient.putItem(request)
    }

    /**
     * Helper to manually update data via the raw client (For the 'Given' block)
     */
    void updateRawRecord(Map<String, String> key, Map<String, Object> attributesToUpdate) {
        def keyValues = key.collectEntries { k, v -> [(k): AttributeValue.builder().s(v).build()] }

        def names = [:]
        def values = [:]
        def parts = []

        // Consolidate the expression building into a single iteration
        attributesToUpdate.each { k, v ->
            parts << "#$k = :$k"
            names["#$k"] = k
            if (v instanceof Number) {
                values[":$k"] = AttributeValue.builder().n(v.toString()).build()
            } else if (v instanceof Boolean) {
                values[":$k"] = AttributeValue.builder().bool(v).build()
            } else {
                values[":$k"] = AttributeValue.builder().s(v.toString()).build()
            }
        }

        def request = UpdateItemRequest.builder()
                .tableName(tableName())
                .key(keyValues)
                .updateExpression("SET " + parts.join(", "))
                .expressionAttributeNames(names)
                .expressionAttributeValues(values)
                .build()

        dynamoDbClient.updateItem(request)
    }

    /**
     * Helper to manually fetch data via the raw client (For the 'Then' block)
     */
    Map<String, AttributeValue> fetchRawRecord(String partitionKeyName, String partitionKeyValue) {
        def key = [(partitionKeyName): AttributeValue.builder().s(partitionKeyValue).build()]

        def request = GetItemRequest.builder()
                .tableName(tableName())
                .key(key)
                .build()

        return dynamoDbClient.getItem(request).item()
    }

}
