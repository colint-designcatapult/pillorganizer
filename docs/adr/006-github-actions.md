# ADR-006 Use GitHub Actions for CI/CD

**Status:** Accepted

**Date:** 2026-02-02

**Authors:** Brendan Heinonen

## Context and Problem Statement
We need a CI/CD platform to automatically build, test, validate, and deploy code as commits are made to the repository.
The solution should minimize manual toil, ensure code quality gates are enforced, and accelerate deployment frequency.
Our repository is hosted by GitHub.

## Decision
We will use GitHub Actions for our primary CI/CD pipeline.

Exception: We will not use GitHub Actions for iOS builds at this time. We will determine an iOS CI/CD system in a separate ADR.

We rejected CircleCI and Travis CI to avoid tool fragmentation, requiring separate users and billing management.

## Consequences
**Positive:**
* Built in to our existing code repository for a unified ecosystem.
* AWS credentials are managed by GitHub instead of us by using OIDC, eliminating a security risk.
* Large ecosystem of existing build steps (including for AWS).

**Negative:**
* Vendor lock-in to GitHub as the workflow files are Actions-specific. A pipeline rewrite would be necessary to switch.
* Hard to test pipelines locally. Local testing tools like `act` don't perfectly emulate GitHub Actions.
* Needs a separate platform for iOS/macOS.