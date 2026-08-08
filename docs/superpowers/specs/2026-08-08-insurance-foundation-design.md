# Sprint 3 — Insurance Foundation

| Field | Value |
| --- | --- |
| **Status** | Approved design — ready for implementation planning |
| **Date** | 2026-08-08 |
| **Decision mode** | Reversible implementation hypothesis |
| **Working hypothesis** | A deliberately small Insurance Foundation is the safest first proof of the Option C layered-hybrid model and managed DEV-to-TEST lifecycle. |
| **Maturity** | Design; not yet deployed |
| **Licence** | 🧩 configuration / own build; Dynamics 365 and Power Platform entitlements must be validated per environment |
| **Upgrade impact** | Additive MINOR release; target `crmshow_Foundation` and `crmshow_DataModel` version `1.1.0.BUILD` |
| **Related ADRs** | [ADR-0006](../../adr/ADR-0006-account-centre-of-gravity.md) · [ADR-0007](../../adr/ADR-0007-portfolio-at-account.md) · [ADR-0008](../../adr/ADR-0008-thin-crm-over-systems-of-record.md) · [ADR-0017](../../adr/ADR-0017-alm-everything-through-the-pipeline.md) · [ADR-0019](../../adr/ADR-0019-provisional-insurance-data-model-shape.md) · [ADR-0020](../../adr/ADR-0020-domain-ownership-within-six-solution-architecture.md) · [ADR-0021](../../adr/ADR-0021-multilingual-semantic-dataverse-metadata.md) |
| **Frameworks** | CAF Ready, Adopt, Govern and Manage · WAF Reliability, Security, Operational Excellence and Cost Optimization · Zero Trust · Microsoft Responsible AI |

## 1. Outcome

Sprint 3 delivers the first deployable insurance data-model slice into the CRM
Showcase DEV environment and promotes it to TEST as managed solutions. It
proves four things before the broader relocation use case is built:

1. the Account-centred insurance model can represent households, businesses
   and brokers without turning Dataverse into a policy-administration system;
2. effective-dated people-to-account and policy-party roles can represent the
   relationships needed by Mobiliar private and business customers;
3. EN, DE, FR and IT metadata can be governed, deployed and validated as part
   of the schema;
4. an additive managed solution can be installed or updated in TEST through a
   pipeline with explicit version and rollback evidence.

The sprint is a reviewable foundation, not a claim that the target model is
final. Core-system and data-platform discovery may change the projection
boundaries under the review triggers in ADR-0019.

## 2. Scope

### Included

- enable and verify English (`1033`), German (`1031`), French (`1036`) and
  Italian (`1040`) in DEV and TEST;
- shared choices and security roles in `crmshow_Foundation`;
- native Account and Contact extensions in `crmshow_DataModel`;
- `AccountContactRole`, `PolicyProjection` and `PolicyPartyRole` custom tables;
- semantic descriptions and localized labels/descriptions for all introduced
  metadata;
- alternate keys, relationships, ownership and effective-dating rules;
- synthetic, clearly labelled, idempotent fixtures;
- solution source, validation, packaging and deployment automation;
- unmanaged DEV deployment and managed TEST install/update;
- metadata, schema, CRUD, security and deployment smoke tests;
- deployment evidence suitable for the GitHub feature issue and PR.

### Excluded

- coverage, risk object, location and jurisdiction projections;
- account assignment, claim, quote, change-event, impact-assessment and
  eligibility-decision tables;
- live policy, claims, rating or data-platform integrations;
- app-specific forms, workspaces or command bars beyond a minimal admin form
  needed for smoke testing;
- automated customer communication, pricing, underwriting or case closure;
- Copilot tools, prompts, runtime agents or AI-generated customer output;
- destructive managed-solution upgrade in TEST.

Those exclusions keep the sprint small enough to validate schema, semantics
and ALM independently. Sprint 4 adds the Relocation Vertical Slice.

## 3. Architectural approach

The design implements Option C from ADR-0019 and the domain ownership model
from ADR-0020:

| Layer | Sprint 3 realization |
| --- | --- |
| CRM-owned relationship and work | Account type, Contact lifecycle stage and effective-dated AccountContactRole |
| Selective source-mastered insurance context | Thin PolicyProjection and PolicyPartyRole |
| Orchestration and traceability | Source identity, retrieval timestamps and deployment evidence only; operational event tables remain Sprint 4 |
| Canonical contracts and data products | Stable English logical names and explicit source/mastership semantics; no physical canonical lake model in this sprint |

The portfolio belongs to Account. Contact participates through roles and never
owns the portfolio. Policy records are projections over a system of record,
not policy administration records. Dataverse never rates, underwrites, binds,
cancels or calculates coverage.

## 4. Solution ownership and dependency

### `crmshow_Foundation`

Owns stable cross-domain building blocks:

- `crmshow_accounttype` global choice;
- `crmshow_contactlifecyclestage` global choice;
- `crmshow_accountcontactroletype` global choice;
- `crmshow_policypartyroletype` global choice;
- `crmshow_policystatus` global choice;
- `CRM Showcase Insurance Reader` security role;
- `CRM Showcase Insurance Data Steward` security role.

### `crmshow_DataModel`

Depends on `crmshow_Foundation` and owns:

- Account and Contact extensions;
- `crmshow_accountcontactrole`;
- `crmshow_policyprojection`;
- `crmshow_policypartyrole`;
- relationships, alternate keys and minimal administration forms/views.

No app solution changes in Sprint 3. No `crmshow_Integration` component is
needed until a live contract, event or synchronization mechanism exists.

## 5. Data model

### 5.1 Native Account extension

| Column | Type | Requirement | Semantics |
| --- | --- | --- | --- |
| `crmshow_accounttype` | Global choice | Required for showcase Accounts | Classifies the Account as Household, Business or Broker. It defines the CRM relationship container and does not describe a legal entity type in a source system. |

Choice values use publisher-scoped numeric values allocated once in
`crmshow_Foundation`:

- Household;
- Business;
- Broker.

The exact integer values are generated from the publisher option-value range
and are immutable after managed release.

### 5.2 Native Contact extension

| Column | Type | Requirement | Semantics |
| --- | --- | --- | --- |
| `crmshow_lifecyclestage` | Global choice | Optional | CRM-owned relationship maturity for an existing person: Prospect, Interested Party or Customer. It is not policy status, risk status or marketing consent. |

The Lead table remains an expression of interest linked to an existing Contact
and Account. Sprint 3 does not modify Lead.

### 5.3 `crmshow_accountcontactrole`

Purpose: represent a person's effective-dated role in a household, business or
broker Account without overloading Contact ownership or a single static
relationship field.

| Column | Type | Requirement | Semantics |
| --- | --- | --- | --- |
| `crmshow_name` | Text | Required | Human-readable role record name generated from Account, Contact and role. |
| `crmshow_accountid` | Account lookup | Required | Account in which the person has the role. |
| `crmshow_contactid` | Contact lookup | Required | Person holding the role. |
| `crmshow_roletype` | Global choice | Required | Household Member, Business Contact, Broker Contact, Decision Maker, Authorized Representative or Beneficial Owner. |
| `crmshow_validfrom` | Date only | Required | First date on which the role is valid. |
| `crmshow_validto` | Date only | Optional | Last date on which the role is valid; blank means open-ended, not permanent. |
| `crmshow_sourcesystem` | Text | Optional | Stable code for the source that asserted the relationship. |
| `crmshow_sourceid` | Text | Optional | Source record identifier; it is not a customer-facing number. |

Rules:

- `validTo` must be blank or on/after `validFrom`;
- records are user/team owned;
- ending a role sets `validTo`; normal business processing does not delete it;
- an alternate key on Account, Contact, role type and `validFrom` prevents an
  identical role interval from being created twice;
- potentially overlapping intervals are reported by a validation query for
  Data Steward review. They are not silently merged or deleted;
- source identity is required only for source-mastered roles. CRM-authored
  roles leave it blank and are auditable through standard Dataverse audit.

### 5.4 `crmshow_policyprojection`

Purpose: expose the minimum policy context needed for CRM work while keeping
policy administration in the core system.

| Column | Type | Requirement | Semantics |
| --- | --- | --- | --- |
| `crmshow_name` | Text | Required | Display name for the projected policy, normally derived from the policy number. |
| `crmshow_accountid` | Account lookup | Required | Portfolio-owning Household, Business or Broker Account. |
| `crmshow_policynumber` | Text | Required | Business-facing policy identifier from the source system. |
| `crmshow_externalsystem` | Text | Required | Stable source-system code that defines the namespace of `externalId`. |
| `crmshow_externalid` | Text | Required | Immutable source record identifier within `externalSystem`. |
| `crmshow_lineofbusinesscode` | Text | Required | Canonical line-of-business code; display labels remain localized outside the code. |
| `crmshow_status` | Global choice | Required | Mapped CRM status: Draft, Active, Suspended, Expired or Cancelled. It does not replace source status. |
| `crmshow_effectivefrom` | Date only | Required | Date from which the projected policy term is effective. |
| `crmshow_effectiveto` | Date only | Optional | Date through which the projected policy term is effective. |
| `crmshow_sourcelastmodifiedon` | Date and time, UTC | Required | Last modification timestamp reported by the source. |
| `crmshow_retrievedon` | Date and time, UTC | Required | Timestamp at which Dataverse retrieved or received this projection. |

Rules:

- alternate key: `externalSystem + externalId`;
- the Account lookup is mandatory and Contact ownership is prohibited;
- `effectiveTo` must be blank or on/after `effectiveFrom`;
- records are user/team owned to support team access and future portfolio
  assignment;
- a source removal or cancellation updates mapped status and/or effective
  dates; it does not hard-delete the projection;
- there is no premium, tariff, underwriting decision, coverage limit or
  payment balance in Sprint 3.

### 5.5 `crmshow_policypartyrole`

Purpose: represent effective-dated parties around a policy without assuming
that policyholder, payer, insured, owner and driver are the same person.

The party is represented by a Dataverse Customer lookup so the platform
enforces one Account-or-Contact reference without custom XOR logic.

| Column | Type | Requirement | Semantics |
| --- | --- | --- | --- |
| `crmshow_name` | Text | Required | Human-readable policy-party role name generated from policy, party and role. |
| `crmshow_policyid` | PolicyProjection lookup | Required | Projected policy to which the party role applies. |
| `crmshow_partyid` | Customer lookup | Required | Account or Contact holding the policy role. |
| `crmshow_roletype` | Global choice | Required | Policyholder, Insured, Payer, Owner, Driver, Beneficiary or Authorized Representative. |
| `crmshow_validfrom` | Date only | Required | First date on which the party role applies. |
| `crmshow_validto` | Date only | Optional | Last date on which the role applies. |
| `crmshow_sourcesystem` | Text | Required | Source-system namespace for the role assertion. |
| `crmshow_sourceid` | Text | Required | Immutable source record identifier for the role assertion. |

Rules:

- the party is not required to equal the PolicyProjection portfolio Account;
- `validTo` must be blank or on/after `validFrom`;
- alternate key: `sourceSystem + sourceId`;
- potentially overlapping role intervals are reported for Data Steward review;
- deactivation or end-dating is preferred to deletion.

All lookups for a custom table are introduced in the table's initial solution
definition. The implementation must not create, delete and recreate lookups.

Sprint 3 validates fixture and import payloads and reports invalid date order
for Data Steward remediation. Universal server-side enforcement across every
Dataverse write path is deferred to
[OR-001](../../requirements/OR-001-effective-date-integrity.md) / issue #9
because Dataverse does not publish a supported compiler contract for
Web-API-authored business-rule XAML. Sprint 3 does not fabricate workflow
payloads or introduce an unapproved plug-in boundary.

Duplicate interval detection also remains an explicit data-quality check in
Sprint 3. The follow-up feature decides whether overlaps remain warnings or
become hard constraints once the synchronization contract is known.

## 6. Metadata and localization contract

English (`1033`) is the base language and logical/schema names remain English.
German (`1031`), French (`1036`) and Italian (`1040`) are native Dataverse
translations.

Every introduced table, column, relationship, choice and choice value includes:

- a precise English display label and semantic description;
- DE, FR and IT labels;
- DE, FR and IT descriptions where Dataverse supports localized descriptions;
- an explicit statement of CRM ownership or source projection where relevant;
- lifecycle/effective-date meaning;
- canonical code and unit meaning where relevant;
- sensitivity and permitted-use guidance where relevant.

A description cannot merely repeat a display name. Metadata helps makers,
integrations and AI tools discover the schema, but it is not authorization,
consent, record grounding or evidence for a customer-facing claim.

Terminology review is shared:

- Dataverse Modeler: completeness and technical correctness;
- CRM Domain Expert: CRM meaning;
- Insurance Domain Expert: insurance meaning;
- Responsible-AI Officer: semantic-discovery safety;
- translators or native reviewers: language equivalence. Automated
  translation alone is not acceptance evidence.

## 7. Environment language enablement

Terraform owns the desired language contract:

```hcl
base_language        = "1033"
additional_languages = ["1031", "1036", "1040"]
```

The current Power Platform provider sets the Dataverse base language but has
no first-class additional-language resource. An idempotent committed
PowerShell control therefore reconciles the Terraform-owned LCID set through
the documented Dataverse `LanguageLocale` Web API:

1. acquire a short-lived token at runtime through the environment-scoped OIDC
   identity;
2. read each required `localeid`;
3. activate inactive required records through `SetState`;
4. read the final state and fail unless all four LCIDs are active;
5. emit environment, LCID and state evidence without tokens or customer data.

DEV uses the existing System Customizer application user. TEST uses its
environment-scoped System Administrator application user. No tenant-wide
administrator identity is introduced.

The control is safe to re-run. It does not automatically disable a language:
removing a supported language is a user-impacting architectural change and
requires a separate ADR. When the provider gains a first-class resource, the
implementation migrates to that resource and retires the script.

Language reconciliation runs after environment/application-user readiness and
before multilingual solution import. Deployment preflight independently
blocks import if any required LCID is inactive.

## 8. Security and auditing

Custom tables are user/team owned.

| Role | Access |
| --- | --- |
| `CRM Showcase Insurance Reader` | Organization-level read on the three custom tables and read access to required Account/Contact columns; no create, update, delete, assign or share. |
| `CRM Showcase Insurance Data Steward` | Reader access plus create/update/append/append-to on relationship and projection tables; no bulk delete and no security administration. |

The pipeline identity receives only the role already approved for its
environment. Runtime personas are assigned showcase roles explicitly; Sprint 3
does not modify out-of-box roles.

Dataverse auditing is enabled for the custom tables and material columns.
Fixtures and deployment evidence contain only synthetic, clearly labelled
Contoso data. No Mobiliar customer data or exported CRM records enter source
control, logs or tests.

## 9. Fixtures

Fixtures are deterministic and idempotent. They demonstrate:

- one synthetic Household Account with two Contacts and effective-dated roles;
- one synthetic Business Account with a business Contact;
- one synthetic Broker Account with a broker Contact;
- policy projections owned by Household and Business Accounts;
- policy-party roles showing that owner, driver, payer and policyholder can be
  different parties.

All records carry stable synthetic external identifiers. Fixture reruns update
the same records through alternate keys and never create duplicates.

## 10. ALM and deployment

### Versioning

This additive feature increments `crmshow_Foundation` and
`crmshow_DataModel` to `1.1.0.BUILD`. Unchanged solutions remain at their
current semantic version unless dependency metadata requires repackaging.

### DEV

- validate source and localization;
- pack unmanaged solutions in dependency order;
- import Foundation, then DataModel;
- publish;
- load/update fixtures;
- run schema, metadata, CRUD and security smoke tests.

### TEST

- pack managed solutions from the same reviewed source;
- preflight installed solution versions and required languages;
- install if no managed solution exists;
- otherwise import as managed **Update**, retaining components absent from the
  newer package;
- run smoke tests and attach evidence to the workflow run.

Sprint 3 does not manufacture a destructive component removal to demonstrate
Upgrade. Sprint 4 will execute both an additive managed Update and a controlled
Stage-for-Upgrade/Apply-Upgrade exercise when there is a legitimate upgrade
case. The import wrapper must nevertheless expose explicit `InstallOrUpdate`,
`StageForUpgrade` and `ApplyUpgrade` modes rather than always forcing
overwrite.

Deployments occur only through GitHub Actions in accordance with ADR-0017.
Local scripts may validate or prepare artefacts but do not create an
alternative release path.

## 11. Failure handling and rollback

| Failure | Required behavior |
| --- | --- |
| Required language missing/inactive | Stop before solution import; report environment and LCID. |
| Metadata validation failure | Stop packaging; identify component, language and failed rule. |
| Solution import failure | Preserve PAC import logs and correlation details; do not run fixtures. |
| Fixture validation failure | Stop and retain imported additive schema for diagnosis; do not report deployment success. |
| TEST version not monotonic | Stop before import and report installed versus package version. |
| Partial language activation | Fail reconciliation after final read; rerun is safe. |
| Security smoke failure | Mark deployment failed; do not widen permissions automatically. |

Because Sprint 3 is additive, rollback means:

1. stop subsequent deployments;
2. disable fixture-driven use if needed;
3. restore the prior managed package only where Dataverse supports a safe
   monotonic package operation;
4. otherwise correct forward with a PATCH/MINOR release.

Data-bearing tables are not casually uninstalled from TEST. Any rollback that
would delete data requires explicit approval, backup evidence and an ADR.

## 12. Validation

### Source and CI

- manifest and dependency validation;
- solution checker;
- no unmanaged active layer in TEST;
- stable schema/logical names and publisher prefix;
- no lookup delete/recreate pattern;
- no secrets or non-synthetic personal data;
- metadata completeness in EN, DE, FR and IT;
- rejection of blank, tautological, placeholder or untranslated metadata;
- alternate-key and relationship definitions present;
- expected MINOR version bump.

### Environment smoke tests

- all required LCIDs active;
- both solutions present with expected managed state and versions;
- Account and Contact extension columns available;
- three custom tables, relationships and alternate keys available;
- Reader can read but cannot mutate;
- Data Steward can create/update but cannot administer security;
- fixture rerun creates no duplicates;
- fixture and import payloads with invalid effective-date order are rejected
  before mutation; online data-quality checks report any invalid records
  created through other write paths;
- the Customer lookup accepts exactly one Account or Contact reference;
- duplicate or overlapping role intervals are reported for Data Steward
  review;
- source-removal simulation end-dates/deactivates rather than deletes;
- localized labels and descriptions can be retrieved for all four LCIDs.

The PR and feature issue link the green workflow run, package versions and
smoke-test evidence.

Universal server-side effective-date enforcement is not a Sprint 3 completion
criterion. It is tracked as
[OR-001](../../requirements/OR-001-effective-date-integrity.md) and
[feature #9](https://github.com/urruegg/CRMShowcase/issues/9).

## 13. Sprint 4 dependency

Sprint 4 — Relocation Vertical Slice — starts only after Sprint 3 is deployed
successfully to TEST. It extends the foundation with Location, Jurisdiction,
CoverageProjection, RiskObjectProjection and typed facets, AccountAssignment,
ChangeEvent, ImpactAssessment, EligibilityDecision and integration contracts.

Sprint 4 reopens the Option C hypothesis if core-system or data-platform
evidence shows that:

- source identities cannot support the alternate-key strategy;
- party roles or effective dates are mastered differently;
- policy/coverage projection freshness cannot meet CRM use cases;
- canonical insurance contracts conflict with the proposed CRM semantics;
- managed solution layering cannot support the intended ownership boundary.

## 14. Definition of done

Sprint 3 is complete when:

- the feature issue and implementation PR provide story-to-ADR-to-test
  traceability;
- required languages are active in DEV and TEST through the IaC control;
- Foundation and DataModel source is committed with complete localized
  semantic metadata;
- automated validation is green;
- unmanaged DEV and managed TEST deployments succeed through the pipeline;
- fixtures and smoke tests pass in both environments;
- package versions and evidence are attached to the PR;
- the sandbox deployment is reviewable by the Product Owner, Enterprise
  Architect, Dataverse Modeler, CRM Domain Expert, Insurance Domain Expert and
  Responsible-AI Officer.
