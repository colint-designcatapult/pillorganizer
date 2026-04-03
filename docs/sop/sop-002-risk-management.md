# SOP-002 - Risk Management

Effective Date: 02/05/2026

Policy Owner: Brendan Heinonen

Supervisory Authority: Travis Cochran (VP of Engineering) 

## Purpose
To establish a systematic procedure for the management of risks associated with medical device software, including how hazards are identified, estimating and evaluating risks, controlling risks, and monitoring their effectiveness throughout the product lifecycle, in compliance with ISO 14971 and IEC 62304.

## Scope
This policy applies to all software developed for the Health-E Smart Pill Organizer.

## Policy
### Risk Management Policy

The overall policy is to design and manufacture devices that are safe and effective.
- Risk Reduction: Risks shall be reduced as far as possible (AFAP) without adversely affecting the benefit-risk ratio.
- Benefit-Risk: We accept residual risks only if the medical benefits to the patient outweigh the remaining residual risk.

### Risk Management Process

The Risk Management Process is iterative and stored within the Strictdoc requirements structure in the Git repository.

#### Hazard Analysis

The team shall identify known and foreseeable hazards associated with the medical device in both normal and fault conditions.
- Software Anomaly Assumption: In accordance with IEC 62304, the probability of a software failure causing a hazard is assumed to be 100% (P5) unless an external hardware risk control measure (e.g., a watchdog timer or hardware interlock) prevents the hazard.
- Therefore, the Probability of Harm (P) is calculated as `1.0 * P(sequence of events)`.

#### Risk Estimation (Scoring)

Risks are estimated by assigning a Severity (S) and a Probability (P) to each hazardous situation.

**Table 1: Severity (S) - Impact on Patient/User**
| Level | Name | Definition |
| ----- | ---- | ---------- |
|S5|Catastrophic|Resulting in patient death, brain death, or permanent impairment.|
|S4|Critical|Resulting in permanent impairment or life-threatening injury.|
|S3|Serious|Resulting in injury or impairment requiring professional medical intervention.|
|S2|Minor|Resulting in temporary injury or impairment not requiring professional medical intervention.|
|S1|Negligible|Inconvenience or temporary discomfort.|


**Table 2: Probability (P) - Likelihood of Harm Occurring**
| Level | Name | Definition |
| ----- | ---- | ---------- |
|P5|Frequent|Likely to occur frequently during device lifetime.|
|P4|Probable|Likely to occur a few times during device lifetime.|
|P3|Occasional|Likely to occur once during device lifetime.|
|P2|Remote|Unlikely to occur, but possible.|
|P1|Improbable|So unlikely it can be assumed not to occur.|

#### Risk Evaluation (The Matrix)

The Risk Level is determined by the intersection of Severity and Probability.

**Table 3: Risk Acceptance Matrix**

|P / S|Negligible (S1)|Minor (S2)|Serious (S3)|Critical (S4)|Catastrophic (S5)|
|-|-|-|-|-|-|
|Frequent (P5)|Conditional|Unacceptable|Unacceptable|Unacceptable|Unacceptable|
|Probable (P4)|Acceptable|Conditional|Unacceptable|Unacceptable|Unacceptable|
|Occasional (P3)|Acceptable|Conditional|Conditional|Unacceptable|Unacceptable|
|Remote (P2)|Acceptable|Acceptable|Conditional|Conditional|Unacceptable|
|Improbable (P1)|Acceptable|Acceptable|Acceptable|Conditional|Conditional|

- Acceptable: The risk is negligible; no further reduction is mandatory, though it is encouraged.
- Conditional: The risk is acceptable ONLY IF a Benefit-Risk Analysis confirms the benefit outweighs the risk, AND all practicable controls have been applied.
- Unacceptable: The risk must be reduced through risk control measures. If it cannot be reduced, the project cannot proceed without a critical Executive Benefit-Risk review.

### Risk Control

For any risk not deemed "Acceptable," risk control measures must be applied in the following priority order (per ISO 14971):

1. Inherent Safety by Design: (e.g., Eliminating the hazard entirely).
2. Protective Measures: (e.g., Alarms, hardware cut-offs, assertions).
3. Information for Safety: (e.g., Warnings in the User Manual). Note: This is the least effective control.

### Verification of Risk Control

Every Risk Control measure must be verified.

- Traceability: The verification method (Test Case, Code Review, Inspection) must be linked to the Risk Control ID in Strictdoc.
- Implementation: If the verification passes, the Residual Risk is re-evaluated using the matrix above.

## Risk Management File
The aggregation of the Hazard Analysis, Risk Evaluation, Control definitions, and Verification links constitutes the Risk Management File.
This is generated from the Git repository (Strictdoc) and approved by an Authorized Signer prior to release.

