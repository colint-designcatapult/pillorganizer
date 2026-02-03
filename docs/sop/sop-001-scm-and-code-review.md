# SOP-001 - Software Configuration Management and Code Review

Effective Date: 02/02/2026

Policy Owner: Brendan Heinonen

Supervisory Authority: Travis Cochran (VP of Engineering) 

##  Purpose
To establish a secure and traceable process for managing software code changes, ensuring that all code contributed to the production codebase is reviewed, tested, and approved in accordance with IEC 62304 and 21 CFR Part 820.

## Scope
This policy applies to all software developed for the Health-E Smart Pill Organizer, specifically regarding the master branch of the source control repository.

##  Policy
### Version Control System
- All source code shall be managed in a centralized Git repository hosted on GitHub and owned by Design Catapult organization.
- Direct commits to the master branch are strictly prohibited.
### Branching Strategy
- Developers shall create "feature branches" for all new development, bug fixes, or experiments.  
- Branch names should include the issue ID to link code to requirements/bugs.
### Pull Requests (PR)
- To merge code into master, a Pull Request must be opened.
- The PR description must summarize the changes and reference the specific Requirement or Issue ID being addressed.
- All PRs must pass automated build and unit test pipelines (CI/CD) before being eligible for review.
### Code Review Requirements
- Separation of Duties: The Author of the code cannot approve their own PR.
- Minimum Reviewers: At least one (1) qualified software developer other than the author must review and approve the PR.
- Scope of Review: The reviewer shall verify:
  - Code logic and safety.
  - Adherence to coding standards.
  - Presence of necessary unit tests.
  - Necessary and accurate documentation, including requirements.
  - Absence of hardcoded credentials or secrets.
### Merging
- Only after the required approvals and passing CI checks may the code be merged.
- The merge record serves as the electronic audit trail for the change.
