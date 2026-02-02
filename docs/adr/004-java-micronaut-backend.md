# ADR-004 Use Java Micronaut backend

**Status:** Accepted

**Date:** 2026-02-02

**Authors:** Brendan Heinonen

## Context and Problem Statement
The existing backend codebase we are taking on is built using the Micronaut framework (Java language).
We need to build a new device communications system based on AWS IoT Core.
The backend code has an API for users, devices, medications, and scheduling but does not have unit/integration tests.
We are a small team on a short deadline.


## Decision
We will use the existing Micronaut-based backend.

We rejected rewriting in another language or framework because a rewrite would take longer and the benefits are unclear.

## Consequences
**Positive:**
* Faster development time by leveraging existing code.
* Mobile app already works with the current backend.
* Java is a battle-tested programming language with a massive ecosystem and Micronaut is well-supported.


**Negative:**
* We will have to write tests for the existing code.
* The Micronaut ecosystem isn't as large as say, Spring.
* Need to remove obsolete device communication code.