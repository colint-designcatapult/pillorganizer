# ADR-009 Decision to use a Global Control Plane  

**Status:** Proposed

**Date:** 2026-02-19

**Authors:** Brendan Heinonen, Colin Tran

## Context and Problem Statement
Based on [ADR-008], we need a way to manage devices and route them to the correct tenant.
Further, a user needs to access potentially more than one device, potentially belonging to different tenants.
Thus we need a global layer to manage these relationships. 

## Decision
We will create a Global Control Plane service, formally Users & Device Provisioning Service as a separate component of the backend that is shared between all tenants.

We rejected burning a specific tenant into the firmware/device at manufacturing because then the device's tenant cannot be changed in the future.


## Consequences
**Positive:**
* Increased device flexibility. A device can be deprovisioned from one tenant, assigned to a different tenant, and then provisioned again onto the new tenant.
* Allows all tenants to share the same mobile phone app, and potentially other software components (like firmware or backend code).
* Allows for one user account to manage multiple devices that are provisioned possibly on more than one tenant.

**Negative:**
* Shared layer between tenants introduces risk of software bugs and data intermixing between tenants. Risk is mitigated becasue devices will receive a tenant-specific certificate for tenant authentication.
* Increased complexity, new software component that needs design, development, testing, and operational support.