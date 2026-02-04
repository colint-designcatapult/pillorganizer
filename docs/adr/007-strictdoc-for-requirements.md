# ADR-002 Decision to use StrictDoc for Requirements Management

**Status:** Accepted

**Date:** 2026-02-04

**Authors:** Colin Tran, Brendan Heinonen

## Context and Problem Statement
We need a robust way to manage requirements and demonstrate traceability for compliance (e.g., HIPAA, 21 CFR Part 11, ISO/IEC certifications).

Traditional tools such as Excel or hardware-focused RM tools are slow, prone to "documentation rot," and make traceability cumbersome when code changes.

We need a lightweight, Git-based solution that:
* Allows requirements to live alongside code.
* Provides traceability between requirements and tests.
* Automatically generates a traceability matrix.
* Reduces manual overhead for compliance documentation.

Our small team prefers solutions that minimize operational and validation burden.

## Decision
We will adopt **StrictDoc**, an open-source requirements management tool that integrates with Git and CI/CD workflows.

1. **Requirements in Git:** Written in a structured text format inside the repository, enabling version control, branching, and PR-based review.
2. **Automated Traceability:** Tests reference requirement IDs, allowing automatic generation of a traceability matrix in PDF.
3. **CI/CD Enforcement:** Traceability checks can be integrated into CI/CD pipelines to ensure requirements are always tested and up-to-date.
4. **Lightweight Workflow:** Avoids external spreadsheets or Word docs, reducing documentation drift and review overhead.
5. **Open-source / Free:** No licensing costs, fully Git-integrated.


## Consequences
**Positive**
* Requirements and code/tests stay in sync, reducing errors and drift.
* CI/CD enforcement ensures the traceability matrix is always current.
* Eliminates reliance on disconnected tools, simplifying workflow.
* Low operational overhead, no extra infrastructure required.
* Integrates naturally into Git-based development workflows.

**Negative:**
* Requires team familiarity with StrictDoc syntax and Git workflows.
* Less visual than traditional RM tools (though PDF export mitigates this).
* Smaller ecosystem compared to enterprise tools like Jira.