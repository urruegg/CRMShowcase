# CRM Showcase — GitHub Copilot Custom Instructions

| Field | Value |
| --- | --- |
| Product | CRM Frontier Firm Showcase |
| Document | Repo-wide Copilot Custom Instructions |
| Version | 0.2 (Draft) |
| Status | Draft |
| Classification | Public — anonymised demo |

<!--
Repository-wide instructions for GitHub Copilot (chat, coding agent, code completion).
Keep them concise and imperative. They are ALWAYS in context — do not bloat.
Deeper detail lives in ../docs/ and ../SUPERPOWERS_CONTRACT.md.
Related: ../AGENTS.md · ../SUPERPOWERS_CONTRACT.md · ./agents/*.agent.md · ./instructions/superpowers.instructions.md
-->

You are helping build the **CRM Frontier Firm Showcase**: a reference
implementation of a modern **human-agent CRM** on top of a CRM data plane
(Dynamics 365 / Dataverse / Power Platform / Copilot Studio / Azure AI Foundry).
The illustrated vertical is **insurance**; the architecture patterns generalise
to any regulated B2C/B2B CRM.

Follow these instructions for every suggestion, chat answer, and coding-agent
task in this repo.

## 1. Project context (read first)

- **Product**: CRM Frontier Firm Showcase — a demo, not a production system.
- **Frontier Firm framing**: humans and agents work as a team; agents are
  teammates that reason, act, and hand off, while humans stay accountable for
  customer-facing decisions.
- **Illustrated customer**: **Contoso Insurance** (fictional). Illustrated
  household: **the Smith family**. Illustrated golden thread: the household
  relocates across a jurisdiction boundary — see
  [docs/ideas/UC-01-relocation-across-jurisdictions/](../docs/ideas/UC-01-relocation-across-jurisdictions/).
- **Primary personas** (see [docs/PERSONAS-JOURNEY.md](../docs/PERSONAS-JOURNEY.md)):
  Advisor / GA (`P-01`), Assistance agent (`P-03`), Marketer (`P-04`), Broker
  manager (`P-05`), IT / Architect (`P-06`), Business owner / Data steward
  (`P-07`).
- Start every design decision from
  [docs/DESIGN-PRINCIPLES.md](../docs/DESIGN-PRINCIPLES.md) and the guardrails
  below.

## 2. Non-negotiable positions (do not relitigate without an ADR)

1. **Thin CRM over the systems of record.** Policy, claim and quote data carry
   *external reference keys* to the systems of record. Never propose absorbing
   rating, underwriting or policy administration into Dataverse
   ([ADR-0008](../docs/adr/ADR-0008-thin-crm-over-systems-of-record.md)).
2. **Account is the centre of gravity.** One `Account` entity with an
   `accountType` discriminator (`Household` · `Business` · `Broker`). For B2C
   the container *is* the household. Do not propose a Person-Account split
   ([ADR-0006](../docs/adr/ADR-0006-account-centre-of-gravity.md)).
3. **Portfolio hangs off the Account, not the Contact.** `Contact` connects
   through `ContactRole`; it never owns the portfolio
   ([ADR-0007](../docs/adr/ADR-0007-portfolio-at-account.md)).
4. **A Lead is an expression of interest on a person who already exists.**
   Keep the native `lead` table but always set `parentcontactid` /
   `parentaccountid`; never use the lead-as-person-stub pattern; group with
   `LeadCluster` to prevent over-contacting. Qualification converts to
   Opportunity **only**
   ([ADR-0009](../docs/adr/ADR-0009-lead-as-interest-on-existing-person.md)).
5. **Consent is per contact, per channel**, with source and capture date,
   enforced as a gate
   ([ADR-0010](../docs/adr/ADR-0010-consent-per-contact-per-channel.md)).
6. **Agents recommend; humans decide**
   ([ADR-0014](../docs/adr/ADR-0014-agents-advisory-by-design.md)).

## 3. Mandatory guardrails (never violate)

The guardrails below are grounded in four Microsoft frameworks. The
concrete framework-to-artefact mapping is in
[docs/MICROSOFT-FRAMEWORKS.md](../docs/MICROSOFT-FRAMEWORKS.md); do not
repeat the mapping here, but do cite the relevant framework in ADRs and PRs.

- **Cloud Adoption Framework** — [overview](https://learn.microsoft.com/azure/cloud-adoption-framework/overview). Every environment-shaping decision (Strategy, Plan, Ready, Adopt, Govern, Secure, Manage) traces to a CAF methodology.
- **Well-Architected Framework** — [pillars](https://learn.microsoft.com/azure/well-architected/pillars). Every material change names which pillars it advances or trades off (Reliability, Security, Cost Optimization, Operational Excellence, Performance Efficiency).
- **Zero Trust** — [overview](https://learn.microsoft.com/security/zero-trust/zero-trust-overview). Every access decision verifies explicitly, uses least privilege, and assumes breach.
- **Responsible AI** — [Microsoft standard](https://learn.microsoft.com/azure/machine-learning/concept-responsible-ai). Every AI capability has a named enforcement mechanism for each of the six principles: fairness · reliability and safety · privacy and security · inclusiveness · transparency · accountability.

Non-negotiables:

1. **No real customer data in the demo.** Use only synthetic or
   clearly-labelled sample data. Never introduce real names, emails, phone
   numbers, contract values, or CRM exports into fixtures, tests, seed
   scripts, or config.
2. **No secrets in code.** Credentials, keys, connection strings, and tokens
   never enter source, config, fixtures, or logs. Prefer **Entra ID +
   Managed Identity**; store any secrets in **Azure Key Vault**. Secret
   scanning and push protection must stay green.
3. **Tenant isolation.** Demo workloads run in an isolated demo tenant. Do not
   add code paths, connections, or configuration that reach into a customer's
   production tenant.
4. **Deterministic boundary between LLM proposal and CRM mutation.** Free-text
   model output must never directly write to Dataverse. All record mutations
   go through a schema-validated action layer
   ([docs/AI.md](../docs/AI.md)).
5. **Responsible AI is enforced.** Content Safety on customer-visible
   generated output. Advisory-only for customer-impacting decisions. Every
   AI-drafted message is grounded in retrieved context, disclosed as
   AI-assisted, and cites what it retrieved.
6. **Traceability in PRs.** Every PR links to a story (`US-###`) and an ADR.
7. **Evidence-in-PR.** Every PR carries green CI, tests for the changed
   behaviour, and — where AI behaviour changed — a link to the eval run.
8. **No silent changes to models, prompts, or agent tool schemas.** Version
   them in Git, review them in a PR, and record architectural decisions in
   [docs/adr/](../docs/adr/).

## 4. Domain rules that change answers (illustrated Swiss insurance example)

- **Building cover is a coverage-existence question**, not a pricing
  question: some jurisdictions have a monopoly building insurer. Crossing
  that boundary can mean the insurer may not write the cover at all
  ([ADR-0012](../docs/adr/ADR-0012-jurisdiction-driven-eligibility.md)).
- **Location is a shared, governed attribute** that drives rating factors
  across several products (motor, contents / burglary, natural hazards).
  One address change fans out
  ([ADR-0011](../docs/adr/ADR-0011-event-driven-cascade.md)).
- **Vehicle owner ≠ driver.** Object-bound and subject-bound coverage logic
  are different.
- **Discounts are portfolio-aware**: cancelling one policy can force
  recalculation of the remaining ones.

## 5. Writing rules

- **Never invent** a number, a customer name, a licensing statement or a GA
  name. Use `[TBD — …]`.
- Every capability statement carries a **licensing flag** (see
  [docs/LICENSING.md](../docs/LICENSING.md)).
- Every AI capability carries a **maturity** flag: productive-at-customers
  vs. roadmap. Do not blur this.
- Every extension declares its **upgrade impact** in its ADR.
- Prefer **configuration → low-code → pro-code**, in that order, and say
  which one you chose and why.

## 6. Known platform gotchas — do not rediscover these

Treat as constraints:

- Define **all lookups in a single `create_table` call**. Create/delete/recreate
  produces duplicate physical columns and corrupts the table.
- The predictive-scoring navigation property `msdyn_predictivescoreid` is
  **not provisioned** — `$expand` returns 400. Read `msdyn_leadscore` /
  `msdyn_leadgrade` / `msdyn_leadscoretrend` off the lead directly.
- `@odata.bind` navigation-property names are **case-sensitive**. Capitalising
  the entity segment silently rejects the whole `createRecord`. Use the
  lowercase schema name.
- There is **no native "compose new SMS/WhatsApp"** cold-start. Outbound
  digital routes through message template → Outbound Configuration → flow →
  `msdyn_InvokeOutboundAPI`. Outbound **voice** is the exception — ad-hoc
  from the dialpad
  ([ADR-0016](../docs/adr/ADR-0016-governed-outbound.md)).
- Outside the WhatsApp 24-hour service window only pre-approved templates
  may be sent. This is Meta's rule, not a D365 limit — say so.
- Live transcript + Copilot voice require the **native voice channel**; they
  are unavailable while a third-party contact-centre platform owns the call
  ([ADR-0015](../docs/adr/ADR-0015-voice-channel-boundary.md)).

## 7. Where to look for deeper detail

- [SUPERPOWERS_CONTRACT.md](../SUPERPOWERS_CONTRACT.md) — the binding
  operating contract.
- [docs/superpowers/SPRINT-OPERATING-MODEL.md](../docs/superpowers/SPRINT-OPERATING-MODEL.md)
  — **the default way to run any sprint or multi-stream build**: brainstorm and
  design on the trunk → Sprint Charter issue + one handover packet per stream
  (each with an autonomy class) → isolated `wt/` worktrees via
  `scripts/orchestration/*` → PR intake (never self-merge) → human merge. Do
  **not** improvise a milestone/epic/branch flow. Sprint index + live status:
  [docs/superpowers/sprints/](../docs/superpowers/sprints/).
- [AGENTS.md](../AGENTS.md) — 6 runtime agents (`AG-F-##`) + 10 engineering
  agents (`AG-E-##`).
- [.github/agents/](./agents/) — one Markdown file per custom agent Copilot
  can adopt.
- [.github/chatmodes/](./chatmodes/) — the same personas as chat modes.
- [.github/instructions/superpowers.instructions.md](./instructions/superpowers.instructions.md)
  — path-scoped rules loaded automatically.
- [docs/](../docs/) — product, design, AI, security, compliance, test, and
  ADR templates.
- [CONTRIBUTING.md](../CONTRIBUTING.md) — ground rules and workflow.

## 8. Definition of done

A change is done when: it has an ADR · it is in `solution/` under source
control (if it touches Dataverse) · it has a test · its upgrade impact is
declared · its licensing flag is set · the pipeline is green · and it is
deployed to the sandbox.
