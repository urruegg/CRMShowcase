# Demo-Feasible Dataverse Authoring and Bootstrap

| Field | Value |
| --- | --- |
| **Status** | Approved design - ready for implementation planning |
| **Date** | 2026-08-09 |
| **Decision mode** | Reversible implementation hypothesis |
| **Working hypothesis** | Separate tenant-feasible demo delivery from privileged target-state automation so the showcase can complete without weakening the steady-state CI identity. |
| **Confidence** | High for the demo boundary; medium for the target bootstrap pattern until tenant administration capabilities are validated |
| **Maturity** | Demo approach approved; target bootstrap remains a hypothesis |
| **Licence** | Configuration / own build; Power Platform and Dynamics 365 entitlements must be validated per environment |
| **Upgrade impact** | Medium - splits the initial authoring workflow into preflight, schema authoring, manual security bootstrap, and export gates |
| **Related** | [Sprint 3 Insurance Foundation](./2026-08-08-insurance-foundation-design.md) - [ADR-0005](../../adr/ADR-0005-power-platform-application-users-for-ci.md) - [ADR-0017](../../adr/ADR-0017-alm-everything-through-the-pipeline.md) - [ADR-0021](../../adr/ADR-0021-multilingual-semantic-dataverse-metadata.md) - [Issue #8](https://github.com/urruegg/CRMShowcase/issues/8) - [Issue #40](https://github.com/urruegg/CRMShowcase/issues/40) |
| **Frameworks** | CAF Ready, Adopt, Govern, Secure and Manage - WAF Reliability, Security and Operational Excellence - Zero Trust |

## 1. Outcome

The CRM Showcase must demonstrate a multilingual Insurance Foundation in the
available demo tenant without pretending that every target-state platform
operation is automatable under the current tenant permissions.

The implementation therefore has two explicit scopes:

1. **Demo-deliverable now:** a repeatable DEV workflow using the existing
   environment-scoped OIDC application user and its `System Customizer` role.
   It authors and validates tenant-feasible metadata and exports the reviewed
   Foundation and DataModel packages.
2. **Target-architecture hypothesis:** privileged environment bootstrap,
   automated security-role creation, and managed TEST promotion. These remain
   documented and reviewable, but they do not block the demo when the current
   tenant cannot support them safely.

The design does not solve permission failures by permanently elevating the DEV
CI identity. Expected Dataverse authorization boundaries are treated as
preconditions and scope decisions, not as transient GitHub Actions errors.

## 2. Evidence and root cause

GitHub Actions run
[31302762752](https://github.com/urruegg/CRMShowcase/actions/runs/31302762752/job/93218095999)
successfully reconciled:

- the four required languages;
- five shared choices;
- Account and Contact extensions;
- `AccountContactRole`, `PolicyProjection`, and `PolicyPartyRole`;
- ordinary and Customer lookups;
- alternate keys;
- invalid-date and overlap reporting views;
- administration views and forms;
- multilingual record metadata.

It then failed when `Publish-InsuranceFoundation.ps1 -Scope All` attempted to
create a Dataverse security role. The environment-scoped application user has
`System Customizer`, which intentionally lacks `prvCreateRole`.

The immediate authorization error is not the only root cause. The current
implementation also:

- combines environment bootstrap, schema authoring, security administration,
  convergence, and package export in one workflow;
- validates privileges only when a mutation is attempted;
- treats security roles like ordinary solution metadata even though they
  control access for the identity running the workflow;
- assumes immediate read-after-write consistency for metadata that Dataverse
  persists asynchronously;
- depends on operator-triggered reruns to recover newly visible relationships
  and columns;
- uses live Web API authoring for both the one-time bootstrap and the
  steady-state delivery path.

The design must remove these couplings rather than add retries around the final
authorization error.

## 3. Constraints

### Known tenant and platform constraints

- `crm-showcase-ci-dev` is an environment-scoped Dataverse application user
  with `System Customizer`.
- The identity can author the tested schema metadata but cannot create security
  roles or grant itself additional privileges.
- CI must not self-elevate.
- Creating or changing the application user's role requires an authorized
  Power Platform administrator.
- Dataverse metadata writes can be asynchronous and can normalize stored XML,
  component ownership, and key ordering.
- The current Terraform provider cannot create the Dataverse application user
  with its role; the repository uses an administrator-run bootstrap script.
- The showcase is a demo. It must not be blocked by target-state automation
  that cannot be executed safely in the available tenant.

### Non-negotiable guardrails

- OIDC federation remains mandatory; no client secret is introduced.
- The steady-state DEV identity remains least-privileged.
- No production tenant or real customer data is used.
- Every environment mutation is reviewable and traceable to a story and ADR.
- Partial metadata is never deleted and recreated to make a run pass.
- Unsupported target-state automation is documented as a hypothesis instead
  of being presented as delivered capability.

## 4. Options evaluated

### Option A - Permanently elevate the DEV CI identity

Assign `System Administrator` or a broad custom role that includes security-role
management to `crm-showcase-ci-dev`.

**Advantages**

- The existing monolithic workflow can create all components.
- Minimal workflow refactoring.

**Disadvantages**

- Violates least privilege for every subsequent run.
- Expands the impact of a compromised workflow or repository.
- Makes a one-time bootstrap permission a permanent runtime permission.
- Does not solve late precondition discovery or metadata convergence.

**Decision:** rejected for both demo and target architecture.

### Option B - Remove security roles from the showcase

Author only choices and data-model components, then export packages without the
two custom roles.

**Advantages**

- Runs under the current CI identity.
- Lowest implementation effort.

**Disadvantages**

- Weakens the reviewed Foundation solution and demo access story.
- Produces packages that do not match the approved Sprint 3 design.
- Avoids rather than models the bootstrap boundary.

**Decision:** rejected as the default. It remains an emergency fallback only if
the tenant administrator cannot perform the bounded manual prerequisite.

### Option C - Split demo delivery from privileged bootstrap

Keep schema authoring and export in the least-privileged workflow. Create the
two reviewed roles once through an authorized Power Platform administrator
runbook, then have CI verify rather than create them. Document a
dedicated automated bootstrap identity as the target-state hypothesis.

**Advantages**

- Delivers the intended demo packages without permanent CI elevation.
- Makes the tenant restriction explicit and auditable.
- Removes the circular dependency between the CI identity and role creation.
- Supports a later transition to automated privileged bootstrap.
- Keeps normal DEV reruns within the tested `System Customizer` capability.

**Disadvantages**

- The first demo deployment has a manual administrator prerequisite.
- Initial environment bootstrap is not fully pipeline-driven.
- The manual role creation must be captured back into exported solution source.

**Decision:** preferred.

## 5. Scope boundary

| Capability | Demo implementation | Target-architecture hypothesis |
| --- | --- | --- |
| Authentication | Existing environment-scoped OIDC application user | Separate OIDC identities for bootstrap and deployment |
| DEV steady-state role | `System Customizer` | Purpose-built deployment role validated against a capability matrix |
| Languages | Verify and reconcile EN, DE, FR, IT with the current control | Environment bootstrap fully automated where tenant APIs and permissions permit |
| Shared choices | Author and reconcile in `crmshow_Foundation` | Import from versioned solution source |
| Data model | Author and reconcile all reviewed Sprint 3 tables and children | Import from versioned solution source |
| Custom security roles | One-time administrator/maker creation from the reviewed contract; CI verifies | Approved bootstrap workflow creates and updates roles |
| DEV packages | Export exact managed and unmanaged Foundation/DataModel packages | Build packages from reviewed unpacked source |
| TEST promotion | Deferred to the solution-versioning sprint | Managed install/update/upgrade with approvals and rollback |
| Fixtures and persona security smoke tests | Deferred until custom roles exist and are exported | Automated after managed deployment |

## 6. Workflow architecture

### 6.1 Read-only preflight

The first job performs no Dataverse mutation. It validates:

- GitHub Environment variables and OIDC authentication;
- target environment identity;
- required languages and their current provisioned state;
- solution existence and publisher ownership;
- required privileges for the selected workflow phase;
- the existence and solution membership of the two custom roles;
- contract integrity and offline Pester suites;
- whether metadata authoring, role bootstrap, or export is required.

The preflight emits a structured plan with these phase states:

- `Ready`
- `AlreadyConverged`
- `ManualPrerequisite`
- `UnsupportedInTenant`
- `ContractConflict`

If a selected phase is not feasible, the workflow stops before mutation and
reports the exact prerequisite. A missing `prvCreateRole` is therefore found
before any schema operation when role creation is requested.

### 6.2 Demo schema authoring

The normal DEV authoring workflow runs only tenant-feasible scopes:

1. shared choices;
2. Account and Contact extensions;
3. one custom table at a time;
4. table publication;
5. relationship and column convergence;
6. alternate keys;
7. views and forms;
8. read-only full-contract validation.

Security-role creation is not part of this mutation path.

Each table phase must poll for the metadata it just created before dependent
components are submitted. Polling is condition-based and bounded. A timeout
reports `EventualConsistencyTimeout` with the table and missing component; it
does not rely on a new workflow run to continue.

### 6.3 Manual security bootstrap

The demo accepts a one-time authorized Power Platform administrator action:

1. create the two reviewed custom roles in `crmshow_Foundation`;
2. configure only the privileges defined by the reviewed contract;
3. publish the roles;
4. verify their solution membership;
5. rerun the read-only preflight.

The implementation plan must provide an idempotent runbook and verification
script. It must not require the administrator to expose credentials to GitHub.

If the tenant cannot support custom role creation at all, the fallback is:

- demonstrate schema and multilingual metadata in DEV;
- document security roles as not delivered in the demo;
- do not claim the Foundation package is complete;
- record the gap and target-state hypothesis in the ADR and issue evidence.

This fallback is a reduced showcase, not Sprint 3 completion.

### 6.4 Export gate

Export runs only after the full demo convergence check succeeds. It verifies
exactly:

- `crmshow_Foundation.zip`
- `crmshow_Foundation_managed.zip`
- `crmshow_DataModel.zip`
- `crmshow_DataModel_managed.zip`

The workflow uploads the four files as one immutable run artifact. Export does
not run after a partial authoring result.

### 6.5 Source-first steady state

After the first successful export:

1. unpack both unmanaged packages into `solution/`;
2. review and commit the actual Dataverse source;
3. stop reconstructing released metadata through live Web API authoring;
4. use package import for subsequent DEV and TEST deployment;
5. retain the authoring script only for initial environment bootstrap,
   diagnostics, and contract comparison.

This is the transition point from prototype authoring to normal ALM.

## 7. Component boundaries

The current `Publish-InsuranceFoundation.ps1 -Scope All` contract must be
split into independently invokable capabilities:

| Capability | Responsibility |
| --- | --- |
| `Test-InsuranceAuthoringPreflight` | Read-only identity, privilege, environment, solution, and contract checks |
| `Set-InsuranceFoundationChoices` | Shared choices only |
| `Set-InsuranceDataModel` | Native extensions, tables, relationships, keys, views, and forms |
| `Test-InsuranceSecurityRoles` | Read-only role existence, ownership, and privilege comparison |
| `Set-InsuranceSecurityRoles` | Privileged target-state/bootstrap operation; excluded from normal demo CI |
| `Test-InsuranceFoundationConvergence` | Full read-only semantic verification before export |
| `Export-InsuranceFoundationPackages` | Exact package export and verification |

Each capability has one privilege profile and one failure boundary. Consumers
do not need to understand its internal Web API calls.

## 8. Error handling and diagnostics

Failures are classified as:

| Classification | Meaning | Workflow behavior |
| --- | --- | --- |
| `Precondition` | Required input, language, solution, or role is missing | Stop before mutation and identify the prerequisite |
| `Authorization` | The identity lacks a required Dataverse privilege | Stop before mutation when detectable; never retry or elevate |
| `ContractConflict` | Existing metadata differs semantically from the reviewed contract | Fail closed with actual and expected structure |
| `PlatformNormalization` | Dataverse added or reordered platform-owned metadata | Compare canonical semantic structure |
| `EventualConsistencyTimeout` | Created metadata did not become readable within the bounded wait | Stop with component-specific recovery evidence |
| `Transport` | Authentication, OIDC assertion, PAC, or Web API request failed | Report the failed boundary and safe rerun point |
| `Export` | Package export or exact package verification failed | Preserve authored metadata and fail without publishing an incomplete artifact |

Every failure includes:

- phase;
- component;
- classification;
- identity and environment slot, without tokens;
- required capability or privilege;
- whether mutation occurred;
- safe next action.

## 9. Testing strategy

### Offline tests

- preflight capability and privilege mapping;
- workflow phase selection;
- security-role creation excluded from the normal demo scope;
- condition-based metadata polling and timeout;
- semantic XML normalization;
- alternate-key set comparison;
- exact package list;
- no mutation when preflight returns `ManualPrerequisite` or
  `UnsupportedInTenant`.

### Online DEV evidence

1. preflight reports the role prerequisite before mutation when roles are
   absent;
2. schema authoring converges in one workflow run without operator reruns;
3. the administrator-created roles pass read-only verification;
4. export produces exactly four packages;
5. a second run under `System Customizer` is idempotent and does not attempt
   role mutation.

### Negative evidence

- a role-create request under `System Customizer` is rejected by tests before
  reaching Dataverse;
- a contract conflict fails closed;
- an unavailable language or missing solution blocks mutation;
- a polling timeout names the unresolved component.

## 10. Demo acceptance criteria

Sprint 3 is demo-complete when:

- EN, DE, FR, and IT are provisioned and verified in DEV;
- all reviewed choices, native extensions, tables, lookups, relationships,
  keys, views, and forms converge;
- the two reviewed custom roles exist in `crmshow_Foundation`;
- the normal CI workflow does not require `prvCreateRole`;
- one clean run under the steady-state DEV identity reaches export;
- exactly four Foundation/DataModel packages are uploaded;
- a second run is idempotent;
- evidence is linked to issue #8;
- TEST promotion, fixtures, and persona security smoke tests remain separately
  scoped rather than being implied as complete.

## 11. Target-architecture hypothesis and review triggers

A new ADR must record the hypothesis that mature environments use:

- a dedicated bootstrap identity with environment approval;
- a separate least-privileged deployment identity;
- explicit privilege capability matrices;
- source-first managed solution promotion after bootstrap;
- automated removal or expiry of temporary bootstrap access.

Reopen the hypothesis when:

- the Power Platform Terraform provider can manage application users and role
  assignments;
- Power Platform exposes a supported environment bootstrap API that removes
  the manual prerequisite;
- the customer tenant provides privileged identity management or just-in-time
  environment administration;
- managed TEST promotion reveals permissions not covered by the proposed
  deployment role;
- solution imports can reliably create and update the reviewed security roles
  without a separate role-authoring identity.

The Enterprise Architect and SecDevOps owner decide whether new evidence moves
the target bootstrap from hypothesis to committed architecture.

## 12. Consequences

### Positive

- The demo becomes deliverable under known tenant restrictions.
- Expected authorization boundaries are discovered before mutation.
- The steady-state CI identity remains least-privileged.
- Workflow reruns are no longer the convergence mechanism.
- The target architecture remains documented without being falsely claimed as
  implemented.

### Trade-offs

- Initial custom-role creation remains a manual administrator prerequisite.
- The authoring workflow and script gain explicit phase boundaries.
- Full managed TEST promotion moves to the next sprint.
- The first exported source remains the bridge from prototype authoring to
  source-first ALM.

### Reversibility

The demo scoping is reversible. When the tenant supports a dedicated automated
bootstrap identity, the privileged security-role phase can move from the
runbook into an approved workflow without changing the schema contract or the
steady-state deployment path.
