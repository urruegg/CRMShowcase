# Mobiliar Prototype to CRM Showcase Data-Model Design

| Field | Value |
| --- | --- |
| Status | Sprint 2 design baseline |
| Date | 2026-08-08 |
| Source | Structural BOM from the isolated Mobiliar rapid prototype |
| Target owner | AG-E-03 Enterprise Architect and AG-E-08 Dataverse Modeler |
| Related ADRs | ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0011, ADR-0012, ADR-0013, ADR-0019 |
| Licence | Configuration and own build; native product dependencies require capability-level validation |
| Maturity | Data-model design; no runtime AI capability is approved by this document |
| Upgrade impact | Additive target-model proposal. Source schema and publisher are not retained. |

## Executive decision

The prototype is valuable as requirement and interaction evidence, but it is
not a viable target data model.

The six custom tables show the intended domains: broker management, campaign
management, claims, households, offers, and policies. Three of those tables
were not fully represented in the solution package, and the package declares
605 missing dependencies. The solution also combines three custom apps,
custom HTML workspaces, native Sales/Service/Marketing customizations, search
configuration, environment settings, and a Copilot Studio bot in one
prototype solution.

The CRM Showcase will therefore rebuild selected capabilities on the existing
six-solution architecture. It will not import the source solution, retain its
publisher, or preserve its parallel party tables.

[ADR-0019](../adr/ADR-0019-provisional-insurance-data-model-shape.md) records
three candidate target shapes. Its working hypothesis is a layered hybrid:
retain the CRM operating model, use canonical P&C semantics in versioned
contracts, and persist only insurance-context projections justified by a named
CRM journey. The final physical projection mechanism remains subject to
Mobiliar core-system integration and data-platform discovery.

## Source observations

### Package shape

| Observation | Design consequence |
| --- | --- |
| 43 root components and 941 BOM items | Use the BOM as review evidence and backlog input, not as an import manifest. |
| 605 declared missing dependencies | Validate every dependent native capability and licence before rebuilding. |
| `Household`, `Policy`, and `Offer` exported with empty definitions | Treat source export as incomplete; metadata enrichment is mandatory for assessment. |
| 22 HTML/image web resources | Preserve user-journey intent, not implementation. Prefer model-driven configuration before custom pages. |
| Three custom apps plus native Customer Service and Marketing app changes | Split target changes by Sales, Service, and Marketing solution ownership. |
| One bot and 19 bot components | Inventory only. Prompt, topic, channel, maturity, licensing, safety, and accountability reviews precede adoption. |
| Source files contain email-like values and source hostnames | Keep source local; commit structural derivatives only. |

### Source custom tables

| Source table | Key source concepts | Decision |
| --- | --- | --- |
| `cr7e8_household` | account link, household income, member count, primary contact, segment | **Retire and redesign.** Household is `Account(accountType=Household)`, not a parallel party container. Derived income/member metrics require explicit source and refresh rules before adoption. |
| `cr7e8_broker` | account link, broker name, registration number, advisor, mandate count, conversion rate, primary contact | **Retire and redesign.** Broker is `Account(accountType=Broker)`. Registration and ownership are Account extensions or dated relationships. Conversion metrics belong in analytics, not the master record. |
| `cr7e8_policy` | account, household, policyholder, policy number, status, product line, dates, annual premium | **Redesign.** Policy is an Account-owned thin projection with external keys. The separate household and policyholder lookups are replaced by Account ownership plus explicit party roles. |
| `cr7e8_Claim` | claim number/type, Contact, date of loss, estimated amount | **Redesign.** Claim is an Account-owned thin projection. Contact involvement is represented through a claim-party role rather than portfolio ownership. |
| `cr7e8_offer` | Account, Contact, Lead, amount, status, product line, policy, validity | **Replace with native process plus projection.** Lead qualifies to Opportunity; native Quote is extended with external keys where a quote-engine projection is needed. |
| `cr7e8_campaign` | Account, Contact, Product, language, target metrics, audience hypothesis, go-live date | **Retire and redesign.** Use native Customer Insights - Journeys constructs and governed consent. Campaign performance metrics stay in analytics. |

## Target conceptual model

```text
Account
  accountType: Household | Business | Broker
  |
  +-- ContactRole -- Contact
  |     role, validFrom, validTo, source
  |
  +-- AccountOwnership
  |     owner/agency, territory, validFrom, validTo
  |
  +-- PolicyProjection
  |     externalSystem + externalId
  |     +-- PolicyPartyRole -- Contact
  |     +-- InsuredAssetProjection
  |
  +-- ClaimProjection
  |     externalSystem + externalId
  |     +-- ClaimPartyRole -- Contact
  |
  +-- Opportunity
        +-- Quote (externalSystem + externalId when engine-backed)

Contact
  +-- Consent (one row per channel and purpose)
  +-- Lead (expression of interest, always linked to Contact and Account)
        +-- LeadCluster
```

Portfolio ownership is always at Account. Contacts participate through roles.
Policy, claim, and quote projections never become systems of record.

## Target table decisions

### Native tables extended

| Table | Extension | Target solution | Mastership |
| --- | --- | --- | --- |
| `account` | `accountType`; broker registration reference where required; relationship rollups only when traceable | `crmshow_DataModel` | CRM for relationship context; external party master for mastered identity attributes |
| `contact` | lifecycle stage and governed relationship navigation | `crmshow_DataModel` | External partner master projection |
| `lead` | required parent Contact and Account; LeadCluster lookup; interest metadata | `crmshow_DataModel` and `crmshow_Sales` | CRM |
| `opportunity` | external demand/quote correlation identifiers where required | `crmshow_DataModel` | CRM for demand; engines for rating |
| `quote` | `externalSystem`, `externalId`, engine status, retrieved-at timestamp | `crmshow_DataModel` | Quote engine |
| `incident` | provenance and external assistance/claim references where required | `crmshow_Service` | CRM for service case |

### Custom tables proposed

| Table | Purpose | Required relationships | Target solution | Mastership |
| --- | --- | --- | --- | --- |
| `crmshow_contactrole` | Effective-dated Contact participation in a Household, Business, or Broker Account | Account N:1, Contact N:1 | `crmshow_DataModel` | CRM |
| `crmshow_leadcluster` | Bundle related interests and prevent over-contacting | Account N:1, Lead 1:N | `crmshow_DataModel` | CRM |
| `crmshow_consent` | Consent per Contact, channel, and purpose with source and capture date | Contact N:1 | `crmshow_DataModel` | CRM or governed consent service projection |
| `crmshow_policyprojection` | Minimal policy context for CRM journeys | Account N:1; external alternate key | `crmshow_DataModel` | Policy administration engine |
| `crmshow_policypartyrole` | Effective-dated insured, policyholder, payer, driver, or other approved roles | Policy N:1, Contact N:1 | `crmshow_DataModel` | Policy administration engine projection |
| `crmshow_claimprojection` | Minimal claim context for service and 360-degree view | Account N:1; optional Policy N:1; external alternate key | `crmshow_DataModel` | Claims engine |
| `crmshow_claimpartyrole` | Claimant, insured, reporter, injured party, or other approved roles | Claim N:1, Contact N:1 | `crmshow_DataModel` | Claims engine projection |
| `crmshow_insuredassetprojection` | Vehicle, building, home, or generic insured-object reference | Account N:1, Policy N:1, external alternate key | `crmshow_DataModel` | Policy administration engine |
| `crmshow_accountownership` | Effective-dated GA, agency, broker-manager, and territory responsibility | Account N:1; owning party/user reference | `crmshow_DataModel` | CRM |

Names remain subject to Dataverse schema implementation review, but the
boundaries and ownership decisions are fixed by the cited ADRs.

## Field policy for external projections

Every policy, claim, quote, and insured-asset projection has:

- `externalSystem` identifying the engine contract;
- `externalId` identifying the mastered record;
- an alternate key across `externalSystem + externalId`;
- `retrievedAt` or `sourceUpdatedAt` for currency;
- lifecycle/status values mapped through a versioned integration contract;
- only the minimum fields required for the CRM use case.

Premiums, estimated claim amounts, statuses, and dates may be displayed as
projections. CRM does not calculate rating, eligibility, reserves, or policy
coverage.

## Source-to-target relationship corrections

| Source pattern | Target correction |
| --- | --- |
| Claim lookup directly to Contact | Claim belongs to Account; Contact participates through ClaimPartyRole. |
| Policy links to Account, Household, and policyholder | Policy belongs to Account; Household is the Account; policyholder is a dated PolicyPartyRole. |
| Offer links independently to Account, Contact, Lead, and Policy | Lead links to existing Contact and Account, qualifies to Opportunity, and produces a governed Quote/projection. |
| Broker as custom table linked to Account | Broker is Account type Broker with dated ownership/relationship records. |
| Campaign links directly to individual Account and Contact records | Native journey audience and consent controls determine activation; no parallel campaign master is introduced. |

## Domain artefact decisions

| Domain | Prototype evidence retained | Target implementation stance |
| --- | --- | --- |
| Advisor and sales cockpit | Advisor app, lead/offer/policy/household pages | Rebuild incrementally in `crmshow_Sales`; configuration first, custom page only with an ADR. |
| Broker management | Broker app and annual-review/offer-tracking pages | Rebuild on Broker Accounts and AccountOwnership after data model approval. |
| Claims and assistance | Claim cockpit, case pages, supervisor workspaces | Rebuild in `crmshow_Service` on native Case plus ClaimProjection. |
| Marketing and events | Campaign pages, performance dashboards, native Marketing app changes | Validate native Customer Insights - Journeys capabilities and licensing; rebuild only approved gaps. |
| AI and voice | Bot plus 19 components | Separate AI/voice design cycle with Responsible AI review and native-channel boundary validation. |
| Analytics | Performance and steering dashboards | Define measures in `docs/ANALYTICS.md`; operational CRM views stay separate from enterprise analytics. |

## Security and privacy

- No source records are migrated.
- No customer-branded source payload is committed to the public repository.
- Target access follows least privilege and the target security-role baseline.
- Projected insurance data is minimized by persona and purpose.
- Consent gates every outbound-capable action.
- Every agent-originated proposal and accepted mutation carries provenance.

## Licensing and maturity

The BOM marks all 605 external dependencies for licensing review. Native Sales,
Customer Service, Customer Insights - Journeys, Omnichannel, Copilot Studio,
voice, and AI capabilities must be validated individually before a capability
claim or implementation story is approved.

The bot and its topics are prototype evidence only. Their maturity is not
inferred from presence in the solution.

## Delivery slices after Sprint 2

1. Implement Account types, ContactRole, and AccountOwnership.
2. Implement Consent and LeadCluster with Lead parent enforcement.
3. Implement PolicyProjection and PolicyPartyRole.
4. Implement ClaimProjection and ClaimPartyRole.
5. Extend native Quote for engine-backed quote projection.
6. Rebuild one advisor-cockpit slice against the approved model.
7. Rebuild one service-cockpit slice against native Case and ClaimProjection.
8. Review marketing and event requirements against licensed native capability.
9. Run a separate Responsible AI design for bot, voice, prompts, and topics.

Each slice requires its own story, ADR linkage, tests, upgrade-impact statement,
licensing flag, and pipeline evidence.

## Acceptance conclusion

The prototype has been converted into traceable evidence without importing its
schema debt. The BOM and domain map are suitable inputs for future review and
backlog refinement. The next Dataverse implementation must start with the
Account-centred party and portfolio foundations, not with copying prototype
tables or user-interface files.
