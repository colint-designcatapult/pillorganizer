# ADR-008 Decision to Physically & Logically Isolate Clinical Trial Environments

**Status:** Accepted

**Date:** 2026-02-11

**Authors:** Brendan Heinonen, Colin Tran

## Context and Problem Statement
The pill organizer may be used for adherence tracking as part of a clinical trials.
Clinical trials have different access, data retention, and regulatory requirements compared to commercial use.
Further, mixing data between personal/commercial use and between clinical trials is a data hygiene risk.
We need a way to ensure commercial users and each clinical trial is separated from one another (multi-tenancy).

Tracked in issue #28.


## Decision
We will use multi-instance tenancy (otherwise known as a cell-based architecture).
Each "tenant", i.e., a clinical trial, has its own dedicated backend infrastructure to the highest extent practicable.
At a minimum, each tenant has dedicated and separate persistence layer (databases), messaging layer (IoT Core, MQTT, REST APIs, queues), and logic layer (backend server instances).
Core, low-risk infrastructure (VPCs, container repositories, ECS clusters) may be shared between tenants.
After initial setup and provisioning, devices are configured in such a way that they can only communicate with the appropriate tenant environment through cryptographic means.

We rejected logical multi-tenancy (enforced in software) because of the risk of software bugs breaking isolation leading to data intermixing or privacy risk.

## Consequences
**Positive:**
* Strong isolation between tenants is best for security, reliability, and regulatory compliance.
* Leverages our existing IaC setup, can easily create different tenant environments.
* Easier to attribute operational costs (i.e., AWS costs) to a particular trial for billing purposes.
* Allows tailored customization for specific tenant needs (e.g., data retention).
* Allows for the researchers to access the "raw" database without other tenant data leakage risk. 

**Negative:**
* Needs a "global" layer to ensure single sign-on and API traffic is routed to the correct tenant.
* Increased operational burden. This is mitigated by our use of IaC/CDK.
* Need to ensure PII is protected from trial environments to avoid issues with unblinding researchers.