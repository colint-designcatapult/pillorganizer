# Enhanced Error Logging and Monitoring Guide

This guide shows how to implement comprehensive error logging that works with CloudWatch monitoring and Slack alerts.

## 🚨 PRODUCTION-ONLY MONITORING

**IMPORTANT**: All CloudWatch alerts and Slack notifications are configured to **ONLY** deploy in the production environment. No alerts will be created for staging to avoid noise and focus on production issues.

## 🎯 What's Been Added

I've enhanced your CloudWatch monitoring with sophisticated error tracking:

### 📊 **7 Types of Error Monitoring:**

1. **General Application Errors** - Any ERROR level logs
2. **Critical Errors** - FATAL/CRITICAL level logs (immediate alerts)
3. **Database Errors** - Connection/SQL issues
4. **HTTP 5xx Errors** - Server errors
5. **Authentication/Security Errors** - Auth failures
6. **IoT/BLE Device Errors** - Device communication issues
7. **Java Exceptions** - Stack traces and exceptions

### 🚨 **Smart Alerting:**

- **Critical errors**: Alert immediately (any occurrence)
- **Database errors**: Alert after 3 occurrences in 5 minutes
- **HTTP 5xx**: Alert after 10 occurrences in 10 minutes
- **Error rate**: Alert when >5% of requests fail
- **IoT errors**: Alert after 3 occurrences (important for your pillbox devices)

## 🔧 Backend Implementation (Java/Micronaut)

### 1. Enhanced Logback Configuration

Update your `backend/src/main/resources/logback.xml`:

```xml
<configuration>
    <!-- Console Appender for Development -->
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="net.logstash.logback.encoder.LogstashEncoder">
            <includeContext>true</includeContext>
            <includeMdc>true</includeMdc>
            <customFields>{"application":"cabinet","environment":"${ENVIRONMENT:-local}"}</customFields>
        </encoder>
    </appender>

    <!-- CloudWatch JSON Appender -->
    <appender name="CLOUDWATCH" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
            <providers>
                <timestamp/>
                <version/>
                <logLevel/>
                <loggerName/>
                <mdc/>
                <arguments/>
                <stackTrace/>
                <pattern>
                    <pattern>
                        {
                            "timestamp": "%d{yyyy-MM-dd'T'HH:mm:ss.SSSX}",
                            "level": "%level",
                            "logger": "%logger{36}",
                            "thread": "%thread",
                            "message": "%message",
                            "application": "cabinet",
                            "environment": "${ENVIRONMENT:-local}",
                            "requestId": "%X{requestId:-}",
                            "userId": "%X{userId:-}",
                            "deviceId": "%X{deviceId:-}",
                            "exception": "%exception{short}",
                            "stackTrace": "%exception"
                        }
                    </pattern>
                </pattern>
            </providers>
        </encoder>
    </appender>

    <root level="INFO">
        <appender-ref ref="CLOUDWATCH"/>
    </root>

    <!-- Specific loggers -->
    <logger name="jct.pillorganizer" level="DEBUG"/>
    <logger name="io.micronaut.security" level="DEBUG"/>
    <logger name="org.hibernate.SQL" level="DEBUG"/>
</configuration>
```

### 2. Add Dependencies to `pom.xml`

```xml
<dependencies>
    <!-- Existing dependencies... -->

    <!-- Enhanced JSON logging -->
    <dependency>
        <groupId>net.logstash.logback</groupId>
        <artifactId>logstash-logback-encoder</artifactId>
        <version>7.4</version>
    </dependency>

    <!-- MDC Support -->
    <dependency>
        <groupId>org.slf4j</groupId>
        <artifactId>slf4j-api</artifactId>
        <version>2.0.9</version>
    </dependency>
</dependencies>
```

### 3. Enhanced Error Handling Service

Create `backend/src/main/java/jct/pillorganizer/service/ErrorTrackingService.java`:

```java
package jct.pillorganizer.service;

import io.micronaut.context.annotation.Bean;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;

import jakarta.inject.Singleton;
import java.util.Map;
import java.util.UUID;

@Singleton
public class ErrorTrackingService {
    private static final Logger log = LoggerFactory.getLogger(ErrorTrackingService.class);

    public void logError(String message, Throwable throwable) {
        logError(message, throwable, null);
    }

    public void logError(String message, Throwable throwable, Map<String, String> context) {
        try {
            // Add context to MDC
            if (context != null) {
                context.forEach(MDC::put);
            }

            // Add error tracking ID
            MDC.put("errorId", UUID.randomUUID().toString());
            MDC.put("errorType", throwable != null ? throwable.getClass().getSimpleName() : "GenericError");

            if (throwable != null) {
                log.error(message, throwable);
            } else {
                log.error(message);
            }
        } finally {
            // Always clear MDC
            if (context != null) {
                context.keySet().forEach(MDC::remove);
            }
            MDC.remove("errorId");
            MDC.remove("errorType");
        }
    }

    public void logCriticalError(String message, Throwable throwable) {
        logCriticalError(message, throwable, null);
    }

    public void logCriticalError(String message, Throwable throwable, Map<String, String> context) {
        try {
            if (context != null) {
                context.forEach(MDC::put);
            }

            MDC.put("errorId", UUID.randomUUID().toString());
            MDC.put("severity", "CRITICAL");
            MDC.put("errorType", throwable != null ? throwable.getClass().getSimpleName() : "CriticalError");

            // Use a logger specifically for critical errors
            Logger criticalLogger = LoggerFactory.getLogger("CRITICAL." + ErrorTrackingService.class.getName());

            if (throwable != null) {
                criticalLogger.error("CRITICAL: {}", message, throwable);
            } else {
                criticalLogger.error("CRITICAL: {}", message);
            }
        } finally {
            if (context != null) {
                context.keySet().forEach(MDC::remove);
            }
            MDC.remove("errorId");
            MDC.remove("severity");
            MDC.remove("errorType");
        }
    }

    // Specific error types for better monitoring
    public void logDatabaseError(String message, Throwable throwable) {
        Map<String, String> context = Map.of(
            "category", "database",
            "subsystem", "persistence"
        );
        logError("DATABASE ERROR: " + message, throwable, context);
    }

    public void logAuthenticationError(String message, String userId) {
        Map<String, String> context = Map.of(
            "category", "authentication",
            "subsystem", "security",
            "userId", userId != null ? userId : "unknown"
        );
        logError("AUTH ERROR: " + message, null, context);
    }

    public void logIoTDeviceError(String message, String deviceId, Throwable throwable) {
        Map<String, String> context = Map.of(
            "category", "iot",
            "subsystem", "device-communication",
            "deviceId", deviceId != null ? deviceId : "unknown"
        );
        logError("DEVICE ERROR: " + message, throwable, context);
    }
}
```

### 4. Global Exception Handler

Create `backend/src/main/java/jct/pillorganizer/exception/GlobalExceptionHandler.java`:

```java
package jct.pillorganizer.exception;

import io.micronaut.http.HttpRequest;
import io.micronaut.http.HttpResponse;
import io.micronaut.http.HttpStatus;
import io.micronaut.http.annotation.Error;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.hateoas.JsonError;
import io.micronaut.http.hateoas.Link;
import jct.pillorganizer.service.ErrorTrackingService;
import org.slf4j.MDC;

import jakarta.inject.Inject;
import java.sql.SQLException;

@Controller
public class GlobalExceptionHandler {

    @Inject
    private ErrorTrackingService errorTrackingService;

    @Error(global = true)
    public HttpResponse<JsonError> handleGeneral(HttpRequest request, Throwable ex) {
        // Add request context to MDC
        MDC.put("requestUri", request.getUri().toString());
        MDC.put("requestMethod", request.getMethod().toString());
        MDC.put("userAgent", request.getHeaders().get("User-Agent"));

        // Log the error with appropriate severity
        if (ex instanceof SQLException || ex.getCause() instanceof SQLException) {
            errorTrackingService.logDatabaseError("Unhandled database exception", ex);
            return HttpResponse.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new JsonError("Database error occurred")
                            .link(Link.SELF, Link.of(request.getUri())));
        }

        if (ex instanceof SecurityException) {
            errorTrackingService.logAuthenticationError("Security exception",
                MDC.get("userId"));
            return HttpResponse.status(HttpStatus.FORBIDDEN)
                    .body(new JsonError("Access denied")
                            .link(Link.SELF, Link.of(request.getUri())));
        }

        // Default error handling
        errorTrackingService.logError("Unhandled exception in request", ex);

        return HttpResponse.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new JsonError("Internal server error")
                        .link(Link.SELF, Link.of(request.getUri())));
    }

    @Error(status = HttpStatus.NOT_FOUND, global = true)
    public HttpResponse<JsonError> notFound(HttpRequest request) {
        return HttpResponse.notFound(
                new JsonError("Resource not found")
                        .link(Link.SELF, Link.of(request.getUri()))
        );
    }
}
```

### 5. Request Tracking Filter

Create `backend/src/main/java/jct/pillorganizer/filter/RequestTrackingFilter.java`:

```java
package jct.pillorganizer.filter;

import io.micronaut.http.HttpRequest;
import io.micronaut.http.MutableHttpResponse;
import io.micronaut.http.annotation.Filter;
import io.micronaut.http.filter.HttpServerFilter;
import io.micronaut.http.filter.ServerFilterChain;
import org.reactivestreams.Publisher;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;

import java.util.UUID;

@Filter("/**")
public class RequestTrackingFilter implements HttpServerFilter {
    private static final Logger log = LoggerFactory.getLogger(RequestTrackingFilter.class);

    @Override
    public Publisher<MutableHttpResponse<?>> doFilter(HttpRequest<?> request,
                                                     ServerFilterChain chain) {
        // Generate request ID
        String requestId = UUID.randomUUID().toString();
        MDC.put("requestId", requestId);

        long startTime = System.currentTimeMillis();

        return chain.proceed(request).doOnNext(response -> {
            long duration = System.currentTimeMillis() - startTime;

            // Log request completion with status
            MDC.put("responseStatus", String.valueOf(response.getStatus().getCode()));
            MDC.put("duration", String.valueOf(duration));

            if (response.getStatus().getCode() >= 500) {
                log.error("Request failed with 5xx status: {} {} - {} ms",
                    request.getMethod(),
                    request.getUri(),
                    duration);
            } else if (response.getStatus().getCode() >= 400) {
                log.warn("Request failed with 4xx status: {} {} - {} ms",
                    request.getMethod(),
                    request.getUri(),
                    duration);
            } else {
                log.info("Request completed: {} {} - {} ms",
                    request.getMethod(),
                    request.getUri(),
                    duration);
            }
        }).doFinally(signalType -> {
            // Always clean up MDC
            MDC.clear();
        });
    }
}
```

### 6. Usage Examples in Controllers

```java
@Controller("/api/devices")
public class DeviceController {

    @Inject
    private ErrorTrackingService errorTrackingService;

    @Inject
    private DeviceService deviceService;

    @Get("/{deviceId}")
    public HttpResponse<?> getDevice(@PathVariable String deviceId) {
        try {
            // Add device context to all logs in this request
            MDC.put("deviceId", deviceId);

            Device device = deviceService.findById(deviceId);
            return HttpResponse.ok(device);

        } catch (DeviceNotFoundException ex) {
            errorTrackingService.logError("Device not found", ex,
                Map.of("deviceId", deviceId, "operation", "get"));
            return HttpResponse.notFound();

        } catch (DatabaseException ex) {
            errorTrackingService.logDatabaseError(
                "Failed to retrieve device from database", ex);
            return HttpResponse.serverError();

        } catch (Exception ex) {
            errorTrackingService.logCriticalError(
                "Unexpected error retrieving device", ex);
            return HttpResponse.serverError();
        }
    }

    @Post("/{deviceId}/provision")
    public HttpResponse<?> provisionDevice(@PathVariable String deviceId,
                                          @Body ProvisionRequest request) {
        try {
            MDC.put("deviceId", deviceId);
            MDC.put("operation", "provision");

            deviceService.provision(deviceId, request);
            return HttpResponse.ok();

        } catch (DeviceCommunicationException ex) {
            errorTrackingService.logIoTDeviceError(
                "Failed to communicate with device during provisioning",
                deviceId, ex);
            return HttpResponse.status(HttpStatus.FAILED_DEPENDENCY);

        } catch (Exception ex) {
            errorTrackingService.logCriticalError(
                "Critical error during device provisioning", ex);
            return HttpResponse.serverError();
        }
    }
}
```

## 🔍 Log Analysis and Dashboards

### CloudWatch Insights Queries

Use these queries in CloudWatch Logs Insights to analyze your errors:

```sql
# Top error types in the last hour
fields @timestamp, level, logger, message, exception
| filter level = "ERROR"
| stats count() as error_count by exception
| sort error_count desc
| limit 10

# Authentication errors with user context
fields @timestamp, message, userId, requestUri
| filter message like /AUTH ERROR/
| sort @timestamp desc

# Database errors by operation
fields @timestamp, message, stackTrace
| filter message like /DATABASE ERROR/
| sort @timestamp desc

# Device communication errors
fields @timestamp, message, deviceId, category
| filter category = "iot"
| sort @timestamp desc

# Error rate over time
fields @timestamp
| filter level = "ERROR"
| stats count() as errors by bin(5m)
| sort @timestamp
```

## 🚀 Deployment

After implementing the logging changes:

1. **Build and deploy your backend:**

   ```bash
   cd backend/
   ./mvnw clean package
   # Deploy to ECS (your existing process)
   ```

2. **Apply Terraform changes (PRODUCTION ONLY):**

   ```bash
   cd terraform/
   # Deploy to production only - alerts will NOT be created for staging
   make production-apply
   ```

   **Note**: The alerts are configured to only deploy in production environment!

3. **Test error logging:**
   ```bash
   # Trigger a test error to verify alerts work
   curl -X POST https://your-domain.com/api/test/error
   ```

## 📊 Benefits

✅ **Proactive monitoring**: Know about issues before users report them  
✅ **Contextual debugging**: Rich error context with request IDs, user IDs, device IDs  
✅ **Categorized alerts**: Different thresholds for different error types  
✅ **Slack integration**: Immediate team notifications  
✅ **Performance tracking**: Error rates and response time monitoring  
✅ **Security monitoring**: Authentication failure detection  
✅ **IoT-specific tracking**: Device communication error monitoring

## 🎛️ Customization

### Adjust Alert Thresholds

Edit thresholds in `terraform/cloudwatch-alerts.tf`:

```hcl
# Make critical alerts more sensitive
threshold = "0"  # Alert on ANY critical error

# Make general errors less sensitive for high-traffic apps
threshold = "20"  # Alert after 20 errors in 5 minutes
```

### Add Custom Error Categories

```java
public void logPaymentError(String message, String transactionId, Throwable throwable) {
    Map<String, String> context = Map.of(
        "category", "payment",
        "subsystem", "billing",
        "transactionId", transactionId
    );
    logError("PAYMENT ERROR: " + message, throwable, context);
}
```

Your error monitoring is now enterprise-grade! 🚀
