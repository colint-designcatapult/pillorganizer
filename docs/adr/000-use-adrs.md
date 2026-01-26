# ADR-000 Decision to use ADRs

**Status:** Accepted

**Date:** 2026-01-23

**Authors:** Brendan Heinonen

## Context and Problem Statement
We need to record architectural decisions for internal documentation and to align with industry best practices & regulatory requirements.

To align with IEC 62304 and FDA regulations, we must store the architecture as the project exists, and the evolution of the design and rationale for changes.


## Decision
We will use **Architectural Decision Records (ADRs)** stored as Markdown files within the project's Git repository to satisfy Design History Requirements.

1. ADRs will follow the template in `docs/adr/template.md`.
2. All decisions will be stored in `docs/adr`.
3. ADRs must be submitted via Pull Request (PR).
    The PR must be reviewed and approved by a second team member.
    The Git merge commit and PR history serve as the electronic signature and audit trail for the approval of the document.
4. A separate file `docs/architecture.md` will be updated to represent the current "Design Output" (the snapshot of the system state), referencing these ADRs for rationale.

We rejected Word documents or external QMS tools due to small team friction, risking that documentation lags behind the code.

## Consequences
**Positive:**
* Integrated into development tools, reducing context switching between other tools.
* Automatic time-stamped record keeping and audit trail.
* Changes are version-controlled with the impacted code.

**Negative:**
* Team members must manually ensure documentation matches code.
* Non-technical team members may find it difficult to navigate/use. We may be able to integrate 