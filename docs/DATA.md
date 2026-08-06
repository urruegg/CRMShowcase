# Data Model, Data Architecture & the 360° View

| Field | Value |
| --- | --- |
| **Topic area** | **A2** — Data model, data architecture, 360° customer view |
| Status | Draft 0.2 · **Owner** `AG-E-03` |

## What the customer asks

How the central 360° customer and partner view is technically realised; a
**live demonstration** of data-model extensibility and configuration of new
business objects, fields, relationships and permissions; how data from
different source systems is merged; how **data ownership and mastership** are
governed; how duplicates are detected and handled; how currency of the view is
assured; and how **household structures, life events, partner relationships
and contracts** integrate — and in what form that information is available to
different roles.

## Ground the model in the Common Data Model

Before we invent a table, we check what Microsoft's **Common Data Model
(CDM)** already ships. CDM is the shared semantic layer Dataverse, Dynamics
365, Power Platform, Azure Data Lake and Fabric already agree on
([About CDM](https://learn.microsoft.com/common-data-model/use)).

For the illustrated insurance vertical the natural anchors are:

- **[Property and Casualty Data Model](https://learn.microsoft.com/common-data-model/schema/core/industrycommon/financialservices/propertyandcasualtydatamodel/overview)**
  — `Policy`, `PolicyProduct`, `PolicyTransaction`, `LOB` (Line of Business),
  `Coverage` / `CoverageLOB` / `CoverageDetail`, `ExclusionInclusion(LOB)`,
  `CauseOfLoss(LOB)`, `Claim` / `ClaimRevision`, `InsuredAutoAsset` /
  `InsuredHomeAsset` / `InsuredGenericAsset`, `InsuredAssetLocation`,
  `Insurer`, `Agency`, `Agent`, `PolicyAgent`, `PolicyAgency`, `Payment`,
  `AuthorizedJurisdiction`. This is the canonical entity set for the golden
  thread.
- **[Financial Services Common Data Model](https://learn.microsoft.com/common-data-model/schema/core/industrycommon/financialservices/financialservicescommondatamodel/overview)**
  — horizontal FSI entities including `Group` and `Groupmember` (households).
- **[Industry accelerators catalogue](https://learn.microsoft.com/dynamics365/industry/accelerators/overview)**
  — cross-vertical patterns worth studying.

**The Healthcare accelerator is the pattern to steal, even for insurance.**
The [Dataverse Healthcare APIs](https://learn.microsoft.com/industry/healthcare/business-applications/dataverse-healthcare-apis-overview)
put a **thin CRM on top of FHIR** — FHIR stays the master, Dataverse holds a
mapped projection with reference keys, and a data-integration toolkit handles
the boundary. That is the exact shape of
[ADR-0008 — Thin CRM over the systems of record](./adr/ADR-0008-thin-crm-over-systems-of-record.md):
Microsoft ships this pattern as first-party architecture. We are not
inventing it.

### Mapping our ADRs to CDM

| Our concept (ADR) | Reuse CDM entity | Extension pattern |
| --- | --- | --- |
| Household as `Account` with `accountType` ([ADR-0006](./adr/ADR-0006-account-centre-of-gravity.md)) | `Account` (P&C + core) | Add `accountType` optionset; do not create a parallel container. |
| Portfolio at Account with `ContactRole` ([ADR-0007](./adr/ADR-0007-portfolio-at-account.md)) | `Policy` + `Contact` + `Account`; roles via `PolicyAgent` / `RelatedPartyContract` | Add a `ContactRole` custom optionset on the party-role relationship. |
| Reference keys to engines ([ADR-0008](./adr/ADR-0008-thin-crm-over-systems-of-record.md)) | `Policy.externalReferenceKey`, `Claim.externalReferenceKey`, `Payment.externalReferenceKey` | Add a required `externalSystem` + `externalId` on each projected record. |
| Consent per channel ([ADR-0010](./adr/ADR-0010-consent-per-contact-per-channel.md)) | `Contact` + a Consent sub-entity | Custom table linked to `Contact`; do not overload existing preference fields. |
| Event-driven cascade ([ADR-0011](./adr/ADR-0011-event-driven-cascade.md)) | `Policy`, `Claim`, `PolicyTransaction` state changes | Emit typed events from CDM P&C tables. |
| Jurisdiction-driven eligibility ([ADR-0012](./adr/ADR-0012-jurisdiction-driven-eligibility.md)) | `AuthorizedJurisdiction` + `LOB` | Extend `AuthorizedJurisdiction` with a monopoly/free-market flag; enforce via a rule table. |
| GA territory ([ADR-0013](./adr/ADR-0013-ga-ownership-and-territory.md)) | `Agency` + `Agent` + `PolicyAgency` + `PolicyAgent` | First-class, dated ownership relationship on `Account`. |

Owners of this grounding: [AG-E-08 Dataverse Modeler](../.github/agents/dataverse-modeler.agent.md)
and [AG-E-07 Data Engineer & Scientist](../.github/agents/data-engineer-scientist.agent.md).

## Non-negotiables

- **No real customer data in the demo** (DP-14,
  [SUPERPOWERS_CONTRACT.md §1.3](../SUPERPOWERS_CONTRACT.md)).
- **Tenant isolation** — demo runs in the demo tenant only. Environment slots
  and where real values live: [ENVIRONMENTS.md](./ENVIRONMENTS.md).
- **Audit every mutation** initiated by an agent (who / what / when / why).

## Core model

```
Account  (accountType: Household · Business · Broker)          ← ADR-0006
  │  1:N  originates
  ├── Contact  (lifecycleStage: Prospect · Interested Party · Customer) ← ADR-0009
  │      │  via ContactRole: Primary · Co-decision-maker · Contextual · BrokerManager
  │      │  1:N expresses
  │      └── Lead ──N:1──> LeadCluster  (anti-over-contact)
  │                 │ 1:1 qualifies →
  │                 └── Opportunity → Quote / Offer
  ├── Policy   ─── external reference key → policy admin engine  ← ADR-0008
  ├── Claim    ─── external reference key → claims engine
  └── Case · Activity · NextBestAction · Consent
```

**Portfolio hangs off the Account, never the Contact**
([ADR-0007](./adr/ADR-0007-portfolio-at-account.md)) — building, contents and
liability cover are inherently shared in a household.

## Mastership

| Domain | Master | CRM holds |
| --- | --- | --- |
| Partner identity | Partner master (external) | projection + link |
| Policy | Policy administration engine | reference-keyed projection |
| Claim | Claims engine | reference-keyed projection |
| Quote | Quoting engine | reference-keyed projection |
| Relationship, roles, consent, demand | **CRM** | master |

Answer the data-ownership question with this table. It is the shortest possible
version of [ADR-0008](./adr/ADR-0008-thin-crm-over-systems-of-record.md), and it
is what an architecture audience will write down.

## Data domains for synthetic seeding

| Domain | Description | Sensitivity in demo |
| --- | --- | --- |
| D1 | CRM party graph (accounts, contacts, roles, relationships) | synthetic-only |
| D2 | Policy / claim / quote projections | synthetic reference keys |
| D3 | Interaction history (emails, calls, chats) | synthetic-only |
| D4 | Consent records | synthetic-only |
| D5 | Knowledge base articles for service triage | public / synthetic |
| D6 | Marketing briefs & brand-voice guides | synthetic |

Synthetic-data rules:

- Names, emails, phone numbers from clearly-fictional generators.
- Company names from the canonical Microsoft demo set (Contoso, Fabrikam,
  Adventure Works).
- No copy-pasted real emails, transcripts, or contracts. Ever.

## Duplicates & identity

- Identity resolution and golden-record handling with a **closed remediation
  loop** — the agent proposes, a steward confirms. No silent merges.
- Demo case: one inbound phone number resolving to several households.

## Household structures & life events

Household membership change reshapes **who is insured under which policy** —
marriage (households merge, liability extends, duplicate contents cover to
consolidate), divorce (split), birth, death, child moving out. This is a graph
question, not a field question, and it is why `ContactRole` exists.

## Extensibility — demonstrated live

Topic area A2 explicitly asks for a live demo of extending the model. Do the
extension on stage (new business object, field, relationship, permission), then
show it in `solution/` under source control. The two halves together are the
answer; either alone is not.

## Deterministic action layer

See [AI.md](./AI.md) — every agent-initiated mutation goes through a
schema-validated tool call. Direct writes from LLM output are prohibited.

## Storage

Environment slots and where real values live are described in
[ENVIRONMENTS.md](./ENVIRONMENTS.md). Real tenant / environment / GUID values
never live in Git.

## Platform gotchas — treat as constraints

- Define **all lookups in one `create_table` call.** Create/delete/recreate has
  been observed to produce duplicate physical columns and corrupt tables.
- `msdyn_predictivescoreid` is not provisioned — `$expand` returns 400. Read
  `msdyn_leadscore` / `msdyn_leadgrade` / `msdyn_leadscoretrend` directly.
- `@odata.bind` navigation-property names are **case-sensitive** — a
  capitalised segment silently rejects the entire `createRecord`.

> These are worth showing an IT audience. Nobody invents gotchas; their
> presence is evidence that we have actually built this.

## ERD

`[TBD — publish the ERD to this repo once the schema is stabilised.]`
