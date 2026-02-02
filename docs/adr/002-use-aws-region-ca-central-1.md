# ADR-002 Use AWS Region `ca-central-1`

**Status:** Accepted

**Date:** 2026-02-02

**Authors:** Brendan Heinonen

## Context and Problem Statement
We need all user data to be in Canada to satisfy client data sovereignty requirements.
All user data must be stored and processed in Canada.
We are already using AWS so we must pick an AWS region 


## Decision
We will create all AWS resources in `ca-central-1`. 
We rejected `ca-west-1` (Calgary) because it's new and lacks flagship parity.

## Consequences
**Positive:**
* Satisfies Canadian data sovereignty requirements.
* De-facto flagship region in Canada for AWS.
* Almost all AWS services are available on `ca-central-1`.

**Negative:**
* Single region is an availability risk (if the whole region goes down), mitigated because `ca-central-1` has 3 availability zones so we can have high-availability with multi-AZ architecture. Can also bring up `ca-west-1` as a failover/disaster recovery region. 
* Slightly higher costs (10-15%) (true for all Canadian regions).
* New AWS features will take slightly longer to reach `ca-central-1` (true for all Canadian regions).