# ADR-0020 — Domain ownership within the six-solution architecture

| Field | Value |
| --- | --- |
| **Status** | Proposed hypothesis — Option C is preferred pending implementation and integration evidence |
| **Date** | 2026-08-08 |
| **Decision mode** | Working hypothesis |
| **Confidence** | Medium — the current ALM structure and domain map support the choice; core-system and data-platform integration details remain incomplete |
| **Deciders** | Enterprise Architect, Dataverse Modeler, Integration Engineer, SecDevOps; customer architecture confirmation required |
| **Topic area** | A1 — Architecture vision · A2 — Data model · A4 — Extensibility · A8 — ALM |
| **Use case** | [GitHub issue #6](https://github.com/urruegg/CRMShowcase/issues/6) · Option C from [ADR-0019](./ADR-0019-provisional-insurance-data-model-shape.md) |
| **Licence** | 🧩 configuration / own build — solution packaging is an ALM design choice, not a product capability claim |
| **Upgrade impact** | Medium — component ownership and dependency direction affect every future Dataverse extension |
| **CAF methodology** | Plan · Ready · Adopt · Govern · Manage |
| **WAF pillar(s)** | Primary: Operational Excellence. Advances Reliability; trades some deployment independence for lower operational complexity and cost. |
| **Zero Trust** | Least privilege — security roles and access boundaries follow business purpose and persona, independent of solution packaging. |
| **Responsible AI** | Not directly AI-specific. AI components remain subject to separate Responsible AI review and may not bypass domain ownership or the deterministic action layer. |

## Context

[ADR-0019](./ADR-0019-provisional-insurance-data-model-shape.md) selects a
layered hybrid as the provisional target data-model shape:

1. CRM-owned relationship and work;
2. source-mastered insurance context;
3. CRM orchestration and traceability;
4. canonical integration contracts and data products.

The repository already defines six deployable Dataverse solutions:

- `crmshow_Foundation`;
- `crmshow_DataModel`;
- `crmshow_Integration`;
- `crmshow_Sales`;
- `crmshow_Service`;
- `crmshow_Marketing`.

The Mobiliar intake also establishes semantic domains including party and
relationship, consent, sales and demand, policy/claim/quote projections,
service and assistance, marketing, broker/distribution, orchestration, and
integration.

The architecture must decide whether these semantic domains should become
separate Dataverse solution packages. A one-to-one mapping sounds clean but can
create excessive dependencies and release overhead. A single broad data-model
solution is easy to deploy but can become an ungoverned dumping ground.

This decision is deliberately provisional. The core-system and data-platform
integration design may change which components are persisted, virtualized, or
implemented outside Dataverse. That evidence can affect component ownership and
dependency direction even if the six top-level solution names remain stable.

## Decision drivers

The solution architecture must:

1. preserve deterministic import order and explicit dependencies;
2. give every component one semantic owner;
3. keep shared tables reusable across Sales, Service, and Marketing;
4. prevent app-specific process and user-interface components from leaking into
   the shared data-model kernel;
5. avoid a large number of small solutions whose dependency graph costs more
   than the isolation they provide;
6. support independent review by Dataverse, integration, security, and
   application owners;
7. permit later decomposition without renaming the publisher or rebuilding the
   entire schema;
8. accommodate persisted, virtualized, event-fed, and data-platform-backed
   insurance projections;
9. make ownership and upgrade impact visible in pull requests.

## Terminology

- **Domain** is a semantic ownership boundary. It defines the meaning,
  invariants, steward, and permitted dependencies of a component.
- **Solution** is a deployment and ALM boundary. It defines package versioning,
  import order, dependencies, and release ownership.
- **App** is a user-experience boundary. It composes shared tables and
  domain-specific processes for a persona.

Domains and solutions do not require a one-to-one mapping.

## Options

### Option A — One broad `crmshow_DataModel` solution

Place all shared and custom Dataverse tables in `crmshow_DataModel`. Keep
`crmshow_Foundation`, `crmshow_Integration`, and the three application
solutions, but use domain names, documentation, and ownership metadata rather
than physical packages to separate Party, Insurance Context, Orchestration,
Demand, Service, Consent, and Distribution.

#### Advantages

- Simplest dependency graph and import order.
- Fastest initial implementation.
- Relationships between custom tables rarely create cross-solution dependency
  problems.
- One package provides a complete schema baseline for every application.
- Low administrative overhead for versioning and releases.

#### Disadvantages

- The data-model solution can become a dumping ground for every new custom
  table.
- Ownership is documented rather than structurally visible.
- A change in one app domain increments and tests the shared package.
- App-specific process tables can accidentally become permanent shared
  contracts.
- Reviewers must inspect every component to determine whether a change crosses
  domain boundaries.
- Later decomposition becomes harder as forms, views, relationships, choices,
  plug-ins, and security components accumulate.

#### Conditions that favour Option A

- The target remains a small showcase with few custom tables.
- One team owns the complete Dataverse schema and release train.
- Core integrations expose screen-ready summaries and require little
  Dataverse-side orchestration.
- Independent domain release cadence has no value.

### Option B — One Dataverse solution per semantic domain

Create separate packages such as Party, Consent, Insurance Context,
Orchestration, Demand, Service/Assistance, Marketing, and Distribution. Each
domain versions and deploys its own tables, relationships, processes, and
security components.

#### Advantages

- Strongest structural visibility of semantic ownership.
- Independent versioning and release cadence by domain.
- Smaller package diffs and more focused reviewers.
- Clear bounded contexts for teams that operate independently.
- A domain can be replaced or retired without repackaging unrelated
  components, provided dependencies remain acyclic.

#### Disadvantages

- Produces many packages for a showcase-sized implementation.
- Shared tables such as Account and Contact require extensions from several
  solutions, making layer order and ownership harder to understand.
- Cross-domain relationships create a dense dependency graph and increase the
  risk of cycles.
- Security roles, shared choices, forms, views, business process flows, and
  custom APIs become difficult to place consistently.
- Coordinated changes span several versions, pipelines, and import steps.
- Operational overhead can exceed the value of independent deployment.
- Dataverse solutions are not fully isolated bounded contexts; components still
  share one metadata and runtime platform.

#### Conditions that favour Option B

- Separate teams independently own and release large domain modules.
- The domain model becomes substantially larger than the current showcase.
- Cross-domain dependencies are few, stable, and acyclic.
- Independent installation or customer-specific domain composition becomes a
  product requirement.

### Option C — Preserve six solutions and enforce domain ownership

Retain the existing six deployable solutions. Treat semantic domains as strict
component-ownership boundaries inside those packages. Keep
`crmshow_DataModel` as a small shared schema kernel, use
`crmshow_Integration` for behavior at external boundaries, and place
app-specific process and user-interface components in Sales, Service, or
Marketing.

#### Target dependency shape

```text
crmshow_Foundation
  |
  +-- crmshow_DataModel
  |      |
  |      +-- crmshow_Integration  [when integration components bind to shared tables]
  |      |
  |      +-- crmshow_Sales
  |      +-- crmshow_Service
  |      +-- crmshow_Marketing
  |
  +-- generic integration components may remain Foundation-only
```

Application solutions depend on the shared schema and on the integration
capabilities they invoke. Dependency direction is downward toward Foundation
and DataModel; app solutions never become dependencies of shared core
solutions.

#### Solution responsibilities

| Solution | Owns | Must not own |
| --- | --- | --- |
| `crmshow_Foundation` | Publisher, shared choice sets, environment-neutral configuration definitions, baseline security-role building blocks | Business-domain tables, app forms, integration logic |
| `crmshow_DataModel` | Shared Account/Contact extensions; CRM-owned cross-app relationship tables; approved insurance-context projections; shared alternate keys and relationships | App-specific forms, dashboards, business process flows, rating or underwriting logic |
| `crmshow_Integration` | Custom APIs, actions, plug-ins, service endpoints, event-schema pointers, projection refresh, mapping, idempotency, and reconciliation behavior | Insurance business rules, app navigation, persona-specific UX |
| `crmshow_Sales` | Lead, Opportunity, and Quote process extensions; sales forms, views, commands, business process flows, advisor cockpit | Shared party semantics, mastered policy logic, service-only workflow |
| `crmshow_Service` | Case and assistance process extensions; service forms, queues, routing configuration, dispatch and service-specific operational tables | Shared party semantics, sales qualification, claims settlement |
| `crmshow_Marketing` | Journey, segment, event, activation, and marketing-specific experience components | Parallel consent master, shared party master, enterprise campaign analytics |

#### Domain ownership inside the six solutions

| Semantic domain | Primary owning solution | Representative components |
| --- | --- | --- |
| Foundation and shared configuration | `crmshow_Foundation` | Publisher, global choices, shared role fragments |
| Party and relationship | `crmshow_DataModel` | Account/Contact extensions, AccountContactRole |
| Consent and preference | `crmshow_DataModel` | Cross-channel consent contract and shared gate data; Marketing consumes but does not redefine it |
| Distribution and responsibility | `crmshow_DataModel` | AccountAssignment for General Agency, broker management, territory, and handover |
| Insurance context | `crmshow_DataModel` | Policy, Coverage, Claim, RiskObject, Location, Jurisdiction, and party-role projections justified by ADR-0019 |
| Shared orchestration state | `crmshow_DataModel` | ImpactAssessment, EligibilityDecisionProjection, handover/remediation records needed by more than one app |
| Integration behavior | `crmshow_Integration` | APIs, actions, plug-ins, event processing, projection refresh, reconciliation |
| Sales and demand | `crmshow_Sales` | Lead/Opportunity/Quote extensions, LeadCluster presentation and sales process |
| Service and assistance | `crmshow_Service` | Case extensions, AssistanceCase, Dispatch, service line items, queues and routing |
| Marketing activation | `crmshow_Marketing` | Journeys, segments, event and activation extensions |

The semantic owner approves meaning and invariants. The solution owner approves
packaging and dependencies. Where these are different roles, both reviews are
required.

#### Component placement rules

1. A component has exactly one owning solution.
2. A shared table is defined in `crmshow_DataModel`; app solutions may add
   app-specific forms, views, charts, commands, and process assets without
   changing the table's cross-app semantics.
3. A table used by only one app starts in that app solution unless it is part of
   the shared party, insurance-context, or orchestration contract.
4. A second app needing an app-owned table triggers an ownership review before
   reuse. The table is promoted to `crmshow_DataModel` only if its semantics are
   genuinely cross-app.
5. Integration behavior belongs in `crmshow_Integration`; business rules remain
   in the authoritative system or the owning CRM domain.
6. `crmshow_Integration` declares a dependency on `crmshow_DataModel` when its
   components reference shared tables. Generic integration components may remain
   dependent only on Foundation.
7. Shared choice sets belong in Foundation only when their meaning is stable
   across domains. Domain-specific choices stay with the owning table.
8. Security roles may aggregate privileges across solutions, but table
   privileges follow the owning domain and least-privilege personas.
9. Circular dependencies are prohibited. A proposed cycle means the component
   boundary or ownership is wrong.
10. No component enters a shared core solution solely because its final owner is
    uncertain.

#### Advantages

- Matches the established ALM architecture and repository layout.
- Provides strong enough ownership without package proliferation.
- Keeps Account, Contact, consent, assignments, and insurance projections
  reusable across applications.
- Isolates external-boundary behavior from user-experience customization.
- Supports configuration-first application development.
- Allows app teams to evolve forms and processes without redefining shared
  semantics.
- Leaves a controlled path to split a domain into its own solution if future
  scale and team independence justify it.

#### Disadvantages

- Ownership is enforced by governance and CI conventions rather than one
  package per domain.
- `crmshow_DataModel` can still grow without disciplined admission rules.
- Changes spanning shared schema, integration behavior, and app UX require
  coordinated versions across several existing solutions.
- The current Integration dependency declaration may need to change when
  components bind to DataModel tables.
- Cross-solution component layering must be tested in clean-environment imports,
  not only in a long-lived sandbox.

#### Conditions that favour Option C

- The six-solution architecture remains the accepted ALM baseline.
- Shared party and insurance-context tables serve multiple apps.
- The implementation is one product with coordinated pipelines rather than
  independently sold domain modules.
- Core-system and data-platform discovery may change projection mechanisms but
  not the need for stable semantic ownership.
- The team is willing to enforce placement rules in reviews and CI.

## Comparison

| Criterion | Option A — broad DataModel | Option B — solution per domain | Option C — six solutions + domain ownership |
| --- | --- | --- | --- |
| Initial simplicity | Highest | Lowest | High |
| Semantic ownership visibility | Low | Highest | High |
| Dependency complexity | Lowest initially | Highest | Medium |
| Fit with current repository | Medium | Low | Highest |
| Shared-table reuse | High | Medium | High |
| Independent domain deployment | Low | Highest | Medium |
| Risk of package proliferation | Low | Highest | Low |
| Risk of DataModel becoming a dumping ground | Highest | Lowest | Medium, controlled by rules |
| Clean-environment import test importance | High | Highest | Highest |
| Adaptability to integration discovery | Medium | Medium | High |
| Reversibility | Medium | Medium | High |

## Working hypothesis

Adopt **Option C — preserve the six solutions and enforce strict domain
ownership** as the provisional target architecture.

This hypothesis establishes the packaging and dependency rules for the detailed
Option C Dataverse model. It does not approve the final table set. A component
must still satisfy ADR-0019's projection justification before it enters
`crmshow_DataModel`.

The current hypothesis is:

- domain is the semantic ownership boundary;
- solution is the deployment boundary;
- app is the persona and process boundary;
- these boundaries are related but not one-to-one.

## Evidence and assumptions

### Known

- The repository already contains the six solution containers and a manifest
  with deterministic dependency order.
- Sales, Service, and Marketing share party, consent, and insurance context.
- ADR-0019 keeps policy, claim, quote, rating, underwriting, and settlement
  systems authoritative.
- The Mobiliar BOM mapping already assigns source artefacts to the current six
  target solutions.

### Inferred

- One coordinated product and pipeline can manage several solution versions
  without requiring fully independent domain releases.
- Shared insurance projections will be fewer and more stable than app-specific
  forms and process components.
- Strict review and CI rules can provide sufficient ownership enforcement at
  showcase scale.

### Evidence still required

- The definitive core-system and data-platform integration map.
- Which projections are persisted, virtualized, event-fed, or composed.
- Actual cross-solution dependencies produced by Dataverse exports.
- Clean-environment import behavior and uninstall/upgrade behavior.
- Whether teams require independent domain release cadence.
- Security-role composition and business-unit/territory behavior across apps.

## Validation and review triggers

Re-open this ADR when:

- ADR-0019 is revisited after core-system or data-platform discovery;
- a domain requires an independent release cadence or optional installation;
- `crmshow_DataModel` accumulates app-specific tables or becomes a delivery
  bottleneck;
- a circular dependency or repeated cross-solution import failure appears;
- an app-owned table becomes a stable cross-app contract;
- a shared table is used by only one app and can be demoted safely;
- integration components require a different dependency direction;
- a clean-environment deployment, upgrade, or uninstall test contradicts the
  assumed package boundaries;
- Microsoft changes Dataverse solution-layering or industry-solution packaging
  in a way that materially affects the trade-off.

The review compares evidence against the criteria above. It may retain Option C,
move toward the simpler Option A, or split a proven domain toward Option B. Any
change is recorded by updating or superseding this ADR; solution ownership must
never drift silently.

## Consequences

- **At the next release:** new tables and components must declare semantic
  domain, owning solution, dependency direction, and upgrade impact.
- **Operationally:** deployment tests must install the six solutions into a
  clean environment in manifest order.
- **For the customer's teams:** semantic domain owners and solution/package
  owners share approval where responsibilities differ.
- **For integration:** `crmshow_Integration` dependency on DataModel is decided
  from actual component references and recorded in the manifest.
- **For security:** solution boundaries do not substitute for table privileges,
  field security, business units, teams, and persona-based access.
- **For cost:** the design avoids the pipeline and maintenance overhead of many
  small solutions while retaining a path to future decomposition.
- **Reversibility:** high. A mature domain can be extracted into a separate
  solution after its contracts and dependencies are stable.
- **Upgrade impact:** additive app changes remain isolated; breaking shared
  schema changes follow the repository's major-version and ADR rules.

## Reusable hypothesis-driven decision pattern

Use this pattern for architecture decisions during CRM Showcase implementation
sprints when material evidence is incomplete:

1. State the outcome and decision pressure.
2. Document two or three credible options with advantages, disadvantages, and
   conditions that favour each.
3. Separate what is known, inferred, and still requires validation.
4. Select one option as a working hypothesis and state confidence.
5. Define evidence that can confirm or reject the hypothesis.
6. Define explicit review triggers and the roles that decide.
7. Implement only the smallest reversible slice needed to produce evidence.
8. Update or supersede the ADR when evidence changes the choice; never let the
   architecture drift silently.

A proposed hypothesis is directional enough to unblock a reviewable slice but
is not equivalent to an accepted irreversible commitment.

## Competitive note

The approach avoids both a monolithic unmanaged CRM solution and a
micro-solution architecture that copies software-service boundaries into
Dataverse without operational benefit. It retains auditable ALM boundaries,
canonical domain ownership, and the ability to adapt once Mobiliar's core
systems and data platform are understood.
