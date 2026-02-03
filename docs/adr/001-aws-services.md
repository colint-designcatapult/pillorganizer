# ADR-001 Use of AWS Services & Infrastructure

**Status:** Proposed

**Date:** 2026-01-26

**Authors:** Brendan Heinonen, Colin Tran

## Context and Problem Statement
We need to finalize the infrastructure to host the backend for the IoT device, mobile app, and data persistence/storage.
Infrastructure must allow for compliance with regulations and industry best practices.
The solution must support at least 2,000 users and have data locality in Canada.
We are a small team with limited operations resources, so reducing validation scope is highly preferred.


## Decision
We will use Amazon Web Services (AWS) with maximum use of managed services to reduce operational complexity and validation scope.
HIPAA compliance is possible with a free BAA (Business Associate Agreement), and the proposed services are all covered by the standard AWS BAA.
We can inspect AWS ISO/IEC certifications so we get that for "free".

Core stack includes:
- **IoT Core**. Communications with the device over MQTT. Pre-validated to handle device state management, configuration, OTA updates, and provisioning. High scalability and reliability with low operational overhead.
- **Simple Queue Service**. Events from devices are buffered in a queue for safety. Ensures events aren't lost and flattens activity spikes. For example, if all 2,000 users take their medication at 8am in the morning, the massive influx of these events won't overload our backend -- they'll be queued. High scalability and reliability.
- **Aurora Serverless v2 PostgreSQL**. Fully managed SQL data store that's validated for very high reliability and hands-off operations.
- **Application Load Balancer**. Handles TLS termination and load balancing for scale. Pre-validated encryption.
- **Elastic Container Service**. Fully managed container orchestration platform.
- **Fargate**. Fully managed container execution. Very low operational overhead, all OS patching and security is handled by AWS.

AWS is configured primarily through IaC (Infrastructure as Code) using Git, providing natural approval and audit workflows.
AWS console access will only be through unique user IAM accounts -- root account is never used, allowing for individual attribution for all changes.
CloudTrail is used to audit "ClickOps" or changes through the AWS console. 

We considered AWS RDS for data storage but decided against it due to operational/uptime concerns. Requires configuring storage/IO ahead of time. We're responsible for updates, which is an operational concern.

We considered AWS App Runner but decided against it because it hasn't received feature updates for 18+ months and may be EOL soon.

We considered Heroku however there is no support for MQTT. 
We would need to provide out own MQTT implementation (high validation burden) and glue code to get data into Heroku.


## Consequences
**Positive:**
* Complete pre-validated solution significantly reduces validation scope.
* AWS handles almost all operations. We don't need to worry about downtime, patching, or security issues. Low operational complexity and needs.
* High scalability potential.
* Built-in regulatory compliance. Can be configured for HIPAA, 21 CFR Part 11, and can validate ISO/IEC certifications like 27001:2022, 27017:2015, 27018:2019, etc.
* Multiple Canadian regions to satisfy data locality.

**Negative:**
* Vendor lock-in. Very hard to switch off later.
* Expensive at low scale. We need to use ALBs and VPCs even in development/prototype stage which adds cost. Aurora does not scale to zero.
* Complexity. We still need to manage networking resources like VPCs and ensure all the "glue" works and is secure. AWS has a huge surface area and often difficult to get a picture of.
* Harder to locally test end-to-end. Integration testing possible through eg LocalStack.

