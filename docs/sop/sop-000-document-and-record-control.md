# SOP-000 - Document & Record Control

Effective Date: 02/05/2026

Policy Owner: Brendan Heinonen

Supervisory Authority: Travis Cochran (VP of Engineering) 

## Purpose
To establish a Git-centric standard for the creation, approval, issuance, and retention of controlled documents and records.
This policy ensures that all project software documentation is traceable, secure, and protected from unauthorized or unintended changes.

## Scope
This policy applies to all Quality Management System (QMS) documents for the Health-E Smart Pill Organizer.
This includes, but is not limited to:
- Controlled Documents: Standard Operating Procedures (SOPs), Architecture Design Records (ADRs), Design and Development Files, Medical Device Files, User Needs, Risk/Hazard Analysis, System Requirements (SyRS), Software Requirements (SRS), and Software Design Specifications (SDS).
- Quality Records: Test Reports, Code Review logs, and Release Notes.

## Policy
### Document Creation & Storage
All controlled documents are maintained as source files within the designated Git repository.

- **Format:**
  - Requirements, Specifications, Risk Analyses, and SOUP/OTS lists are maintained using Strictdoc syntax to ensure granular traceability and structured export.
  - SOPs, Policies, ADRs, and design/development documentation are maintained in Markdown `(.md)` format.
  - Documents in Markdown or Strictdoc format may be exported into a different format (like PDF or HTML) for convenience purposes only. The source document in Git shall be the document in force. 
- **Location:** The Git repository acts as the secure physical storage location for all documents.

### Version Control & History

The Git version control system automates the revision history and retention of documents.
- Current Version: The file version present on the default branch (e.g., master) is considered the "Current Effective Version."
- The Git commit log preserves the complete history of changes, including who made the change, when it was made, and the specific content modified.
- Prevention of Unintended Use: Accessing the repository defaults to the Current Effective Version. Old versions are automatically archived in the commit history and are not present in the working directory.

### Review & Approval (Electronic Signatures)
Changes to controlled documents are managed via the GitHub Pull Request (PR) workflow in accordiance with [SOP-001].
- Drafting: Changes are made on a feature branch.
- Review: A Pull Request is opened to merge the changes into the default branch.
- Approval: An Authorized Signer must review the Pull Request. The Authorized Signer's affirmative review (e.g., "Approve" status on GitHub) constitutes the legally binding Electronic Signature and authorization for release.

## Control of Quality Records
Quality Records provide evidence that activities have been performed. Once finalized, they must remain immutable.

### Code Reviews
- Record Definition: The GitHub Pull Request (PR) object itself serves as the official Quality Record for code reviews.
- Content: The PR record permanently retains the code diffs, reviewer comments, resolution of comments, and final approval timestamps.
- Storage: These records are stored permanently within the GitHub repository metadata and are searchable by PR number and commit hash.

### Test Reports (CI/CD)
- Generation: Test reports are generated automatically by the Continuous Integration (CI/CD) pipeline upon code submission.
- Traceability: Every test report must contain the specific Git Commit Hash it verified to ensure unambiguous traceability between the code and the test result.
- Storage & Retention:
  - Validated Test Reports are stored as Permanent Artifacts attached to the associated GitHub Release (or designated permanent storage bucket).
  - Note: Temporary CI pipeline artifacts (which auto-expire) are not considered the permanent record.

