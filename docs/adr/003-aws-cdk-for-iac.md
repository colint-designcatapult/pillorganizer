# ADR-003 Use AWS CDK (TypeScript) for IaC

**Status:** Accepted

**Date:** 2026-02-02

**Authors:** Brendan Heinonen

## Context and Problem Statement
Need to use Infrastructure-as-Code (IaC) to align with industry best practices and ensure traceability, testability, and compliance.
Need to be able to "check in" IaC code into the git repository for integration into our "GitOps" workflow.
The IaC solution must be testable and have full support for AWS services.

## Decision
We will use AWS Cloud Development Kit (CDK) v2 with TypeScript because it is the most supported option on AWS and TypeScript is a familiar language with type safety.
We rejected Terraform due to complexity, requiring more code to deploy an equivalent stack and uses a DSL.
We rejected AWS Copilot because it's deprecated and no longer receiving feature updates.

## Consequences
**Positive:**
* Tight integration and high level of support from AWS.
* Out-of-the-box compliance testing (HIPAA, etc) with `cdk-nag`.
* Supports all AWS services we use.
* Ensures we can bring up repeatable infrastructure on a fresh AWS account.
* Changes to infrastructure are logged and auditable via Git commits.

**Negative:**
* Further vendor lock-in with AWS. Can't use CDK easily with another cloud provider.
* Some AWS-provided abstractions are "magic" and hide resource allocation underneath high-level constructs that can lead to increased cost. Need to ensure we understand what every construct is doing.