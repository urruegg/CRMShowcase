# ADR-0041 - Code Apps primary for bespoke full-page CRM UX

| Field | Value |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-08-19 |
| **Decision mode** | Committed decision |
| **Confidence** | Medium - the build rule and platform boundaries are approved; Advisor Cockpit DEV and TEST parity evidence is still required before B1 or B2 can be selected |
| **Deciders** | Repo owner - Enterprise Architect (`AG-E-03`) - Developer (`AG-E-02`) - SecDevOps (`AG-E-04`) - UX Designer (`AG-E-11`) |
| **Topic area** | A4 - Configuration, extensibility and upgrade safety - A8 - ALM and operations |
| **Use case** | UC-01 - Advisor Cockpit - US-301 |
| **Licence** | 🧩 configuration / own build - validate Power Apps Premium and applicable Dynamics 365 / Copilot Studio use rights for each persona before rollout |
| **Upgrade impact** | Medium - Code App shells, generated services, shared packages, solution membership and host configuration remain source-controlled and must be retested at platform or dependency upgrades |
| **CAF methodology** | Adopt - Govern: establish a supported implementation path and a reviewable source-to-environment control |
| **WAF pillar(s)** | Primary: Operational Excellence - Security and Reliability. Trade-off: pro-code maintenance and persona licensing validation increase delivery effort |
| **Zero Trust** | Verify the environment, app identity and signed-in persona explicitly; use least-privilege Dataverse access; assume breach by storing no client secret and promoting only the reviewed artifact |
| **Responsible AI** | Fairness, reliability and safety, privacy and security, inclusiveness, transparency and accountability remain enforced through parity evidence, explicit failure states, least privilege, accessibility, provenance and human approval |

## Context

The repository needs one unambiguous placement rule for CRM user experiences.
[ADR-0027](./ADR-0027-page-level-pcf-and-local-first-polish-loop.md) made a
page-level PCF the default for bespoke full-page surfaces before Power Apps
Code Apps became the approved foundation. The
[Advisor Cockpit parity design](../superpowers/specs/2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md)
now requires a bounded rule that preserves native model-driven strengths,
uses Code Apps where full-page control is justified, and retains PCF for
embedded host context.

The same design identifies an ALM constraint: the current noninteractive Code
Apps CLI publication path requires secret-based service-principal
authentication. That conflicts with the repository's OIDC and no-stored-secret
position. The exception must therefore be attended, DEV-only and unable to
bypass the managed TEST promotion path.

## Options

### Option A - Keep page-level PCF as the default

Continue using one page-level PCF control for each bespoke full-page CRM
surface. **Not selected:** PCF remains appropriate when the component requires
form, dataset or field context, but making it the full-page default couples a
standalone experience to an embedded-control contract.

### Option B - Use Code Apps for every CRM surface

Replace native forms, views, timelines, commands and embedded controls with
Code Apps. **Not selected:** this would rebuild supported model-driven behavior
and ignore the repository's configuration-first principle.

### Option C - Use a bounded placement rule (selected)

Use model-driven configuration for native CRM work, Code Apps for bespoke
full-page experiences, and PCF for embedded host-context controls. **Selected
as a committed decision:** each technology owns the surface that matches its
runtime contract, while exceptions require architecture review.

## Decision or working hypothesis

Code Apps are primary for bespoke full-page CRM experiences. Model-driven
configuration remains primary for native forms, views, timelines and commands;
PCF remains the extension path for embedded controls requiring form, dataset or
field context. The Advisor Cockpit B1/B2 proof validates host placement without
changing that build rule.

DEV Code App creation and update use one deterministic attended publication
contract because the current noninteractive CLI requires secret-based
service-principal authentication.
A maker/admin starts from a clean reviewed checkout at the reviewed commit,
verifies each app's `power.config.json` is bound to the approved DEV environment
ID, and builds and tests immediately before publication. The maker/admin creates
a sorted per-file SHA-256 manifest of `dist` using normalized relative paths,
serializes it as a BOM-free UTF-8 manifest, and hashes the manifest. Leave
`dist` unchanged between hashing and push, then run attended
`pa app push --solution-id <crmshow_Sales GUID>` to DEV only. The
operator captures the returned play URL, opens the published app, and verifies
`getContext().app.environmentId` equals the approved DEV environment ID.
Publication evidence records the commit, manifest hash, successful build and
test evidence, CLI version, app identity, solution identity, approved DEV
environment ID, returned play URL, runtime environment ID, operator, timestamp
and result. No client secret is introduced or stored.

Git remains source of truth. TEST receives the exact managed artifact through
the existing OIDC pipeline. Direct TEST authoring is prohibited.

ADR-0033 options B1 and B2 remain unselected until the same complete Advisor
Cockpit has produced reviewable DEV and TEST parity evidence. This ADR chooses
the build path, not the final host placement.

## Evidence and assumptions

- **Known:** the approved Sprint 005 design fixes the build order, app-local
  generated Dataverse services, sequential local workflow, attended DEV
  publication and managed DEV-to-TEST promotion.
- **Known:** the existing Advisor Cockpit fixture harness is the reviewed visual
  baseline; the deployed PCF is not a user-visible runtime fallback.
- **Inferred:** the bounded rule will reduce custom host coupling without
  sacrificing native model-driven workflows.
- **Evidence still required:** complete B1 and B2 runs in DEV and TEST using the
  same synthetic scenario, least-privilege advisor, accessibility checks,
  provenance checks, writes and rereads, navigation checks, timings and
  promotion evidence.

## Framework and assurance alignment

- **CAF Adopt and Govern:** implementation uses a supported Power Platform
  surface and a source-controlled, reviewed promotion path.
- **WAF Operational Excellence, Security and Reliability:** one build rule,
  explicit runtime failure states, exact managed-artifact promotion and
  rollback evidence make changes supportable. The trade-off is the maintenance
  cost of pro-code packages and two proof hosts.
- **Zero Trust:** runtime access uses the signed-in advisor's Dataverse rights;
  maker/admin rights are deployment-only; no stored client secret or hard-coded
  DEV URL crosses the environment boundary.
- **Responsible AI:** the Advisor Cockpit keeps recommendations advisory;
  schema-validated writes and rereads protect reliability and safety; least
  privilege protects privacy and security; accessibility and locale checks
  protect inclusiveness; provenance and AI-assisted disclosure protect
  transparency; accept, edit and dismiss remain accountable human decisions.
  The shared scenario and parity scorecard expose host-specific differences for
  fairness review rather than hiding them behind fixture fallback.

## Validation and review triggers

Keep B1 and B2 unselected until the Sprint 005 evidence scorecard contains the
required live DEV and TEST runs for the complete Advisor Cockpit. The repo owner
and Enterprise Architect review that evidence with Developer, SecDevOps and UX
input; no automated score selects a winner.

Reopen this ADR if Microsoft provides a noninteractive Code App publication
path compatible with the repository's OIDC/no-secret posture, if generated
services cannot support the approved cockpit contract, if persona licensing
validation fails, or if native model-driven configuration can satisfy a future
bespoke full-page requirement without pro-code.

## Consequences

- **At the next release:** Code Apps, shared packages, generated services and
  solution membership are rebuilt and retested; embedded PCF controls continue
  under their existing ALM instructions.
- **Operationally:** attended publication is DEV-only and follows the
  deterministic contract above. The recorded commit, sorted per-file manifest,
  manifest hash, returned play URL and runtime environment ID bind the
  publication to the reviewed build and DEV target; TEST changes arrive only
  as the exact managed solution through the existing OIDC pipeline, never
  through direct TEST authoring.
- **For the customer's teams (shared responsibility):** makers publish to DEV,
  the pipeline promotes to TEST, administrators assign least-privilege access,
  and owners validate Power Apps Premium plus applicable product rights per
  persona.
- **Reversibility:** high for the build rule because native configuration and
  embedded PCF remain available; host selection stays reversible until B1/B2
  parity evidence is approved.

## Competitive note

The decision requires comparable CRM proposals to distinguish native
configuration, managed full-page pro-code experiences and embedded controls,
then demonstrate the upgrade and promotion cost of each rather than describing
all UI customization as one undifferentiated capability.

## Authoritative references

- [Power Apps Code Apps documentation](https://learn.microsoft.com/power-apps/developer/code-apps/)
- [Power Apps Code Apps ALM](https://learn.microsoft.com/power-apps/developer/code-apps/how-to/alm)
- [Connect Code Apps to Dataverse](https://learn.microsoft.com/power-apps/developer/code-apps/how-to/connect-to-dataverse)
- [ADR-0014 - agents advisory by design](./ADR-0014-agents-advisory-by-design.md)
- [ADR-0017 - ALM through the pipeline](./ADR-0017-alm-everything-through-the-pipeline.md)
- [ADR-0033 - CRM UX placement](./ADR-0033-crm-ux-placement-in-b2e-landscape.md)
