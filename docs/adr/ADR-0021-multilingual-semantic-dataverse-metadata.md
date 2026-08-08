# ADR-0021 — Multilingual semantic Dataverse metadata

| Field | Value |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-08-08 |
| **Decision mode** | Committed decision |
| **Confidence** | High — required target-language and AI-readiness constraint |
| **Deciders** | Product Owner, Enterprise Architect, Dataverse Modeler, Responsible-AI Officer |
| **Topic area** | A2 — Data model · A4 — Extensibility · A6 — AI · A8 — ALM |
| **Use case** | All Dataverse implementation sprints |
| **Licence** | 🧩 configuration / own build — validate tenant language-pack availability before deployment |
| **Upgrade impact** | Medium — every schema and user-interface component carries localized metadata and validation evidence |
| **CAF methodology** | Ready · Adopt · Govern · Manage |
| **WAF pillar(s)** | Operational Excellence · Reliability |
| **Zero Trust** | Metadata never grants data access; least-privilege table, row and field security remain authoritative. |
| **Responsible AI** | Inclusiveness, transparency, reliability and safety — agents receive precise semantic metadata but must still ground claims in authorized records. |

## Context

Dataverse metadata is consumed by makers, users, integrations, Copilot and
other agents. A technically valid schema with empty, tautological or
implementation-only descriptions is not semantically usable. It forces every
consumer to reverse-engineer meaning and increases the risk that agents select
the wrong field, confuse CRM-owned state with an external projection, or infer
authority the CRM does not have.

The target architecture supports English, German, French and Italian. This is
not an application-copy concern added after schema implementation. Dataverse
labels and descriptions are solution metadata and must be designed,
source-controlled, reviewed and deployed with the component they describe.

## Options

### Option A — English-only schema, translate application surfaces later

Use English metadata for tables and columns, then translate forms and apps when
customer-facing screens are built.

**Rejected:** makers, integrations, search, Copilot and agents would encounter
incomplete multilingual semantics. Later translation would create
environment-only drift and inconsistent choices and help text.

### Option B — Four-language labels, minimal descriptions

Translate display names and choice labels but keep descriptions optional or
technical.

**Rejected:** labels identify a concept but do not define scope, mastership,
units, lifecycle, sensitivity or projection status. Semantic discovery remains
unsafe and integration mappings remain ambiguous.

### Option C — Four-language semantic metadata ✅ chosen

Use English (`1033`) as the base language. Enable German (`1031`), French
(`1036`) and Italian (`1040`) through native Dataverse language support. Ship
precise English descriptions and reviewed localized labels/descriptions with
every relevant solution component.

## Decision

English (`1033`) is the base metadata language for stable logical/schema names
and canonical definitions. German (`1031`), French (`1036`) and Italian
(`1040`) are supported translations.

Every table, column, relationship, choice, action and custom API has a precise
English display name and business-semantic description. Every user-visible
name, label, choice text, help text, form/view/command label and relevant
description is translated into DE, FR and IT using native Dataverse localized
labels in the owning solution.

A description states business meaning and scope and, where relevant:

- source and mastership;
- whether the value is CRM-owned or projected;
- units and canonical values;
- sensitivity and permitted use;
- effective-dating and lifecycle semantics;
- relationship direction and role meaning.

Logical and schema names remain stable English machine identifiers.
Localization never changes API names.

Metadata may guide schema discovery, tool generation and field selection by
Copilot or another agent. It is not record-level grounding, customer evidence,
authorization, or consent.

## Validation and review

CI and deployment smoke tests must reject:

- missing or blank descriptions;
- descriptions equal to logical/display names without added meaning;
- `TBD`, `TODO`, placeholder or copied descriptions;
- missing EN, DE, FR or IT localized labels for user-visible components;
- missing localized choice values;
- translations that alter CRM or insurance-domain meaning;
- environment-only metadata not represented in the solution source.

The Dataverse Modeler owns metadata completeness. CRM and Insurance Domain
Experts review terminology and translation equivalence. The Responsible-AI
Officer reviews metadata used for semantic discovery and verifies that AI
evaluations reject metadata-only factual claims.

## Consequences

- **At the next release:** Sprint 3 Insurance Foundation includes all four
  languages and semantic descriptions from its first DEV deployment.
- **Environment readiness:** DE, FR and IT language support is enabled in DEV
  and TEST before importing multilingual components.
- **Operationally:** metadata and translation changes follow the same PR,
  versioning, deployment and drift controls as schema changes.
- **For implementation teams:** a Dataverse component is incomplete until its
  semantic description and translations are complete.
- **For AI:** schema discovery improves, but grounding, access control and
  deterministic mutation controls remain unchanged.
- **For integration and analytics:** stable English identifiers and semantic
  descriptions flow into contracts, CDM traits and downstream mappings.
- **Reversibility:** labels and descriptions can be improved additively; the
  four-language commitment is not optional per sprint.
