# ADR-005 Use Spock for backend unit & integration testing 

**Status:** Accepted

**Date:** 2026-02-02

**Authors:** Brendan Heinonen

## Context and Problem Statement
The backend needs an automated unit and integration testing solution.
It must work with the Micronaut framework, Maven build system, and support Testcontainers to spin up a local database and AWS instance. 

## Decision
We will use [Spock](https://spockframework.org/).

We rejected JUnit because the Java syntax is verbose for testing and requires external/separate libraries for mocking.

## Consequences
**Positive:**
* Very fast and quick to create tests.
* Powerful DSL allows for mocking and data-driven testing out of the box without separate libraries.
* Integrates with Micronaut, Testcontainers, Maven, and the JUnit 5+ platform natively.

**Negative:**
* Uses the Groovy language, which compiles to Java bytecode but lags behind Java versions in support. This is mitigated because we use OpenJDK long-term support versions so we don't want bleeding edge anyway. The DSL is easy to pick up for Java devs but ultimately many Java devs might not be familiar.
* Not as popular as JUnit.