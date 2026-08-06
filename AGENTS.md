# Agent Registry — Runtime & Engineering Agents

| Field | Value |
| --- | --- |
| Product | CRM Frontier Firm Showcase |
| Document | Agent Registry (runtime `AG-F-##` + engineering `AG-E-##`) |
| Version | 0.3 (Draft) |
| Status | Draft |
| Classification | Public — anonymised demo |

**Related:** [docs/AI.md](./docs/AI.md) · [docs/DATA.md](./docs/DATA.md) ·
[docs/SD.md](./docs/SD.md) · [docs/COMPLIANCE.md](./docs/COMPLIANCE.md) ·
[SUPERPOWERS_CONTRACT.md](./SUPERPOWERS_CONTRACT.md) ·
[docs/PERSONAS-JOURNEY.md](./docs/PERSONAS-JOURNEY.md)

> **Two classes of agent.** This registry covers **(1) runtime / functional
> agents `AG-F-##`** — the CRM agents *inside* the showcase that an advisor,
> assistance agent or marketer collaborates with — and **(2) engineering /
> build-time agents `AG-E-##`** — the GitHub Copilot custom agents that
> *build* the showcase (files under [.github/agents/](./.github/agents/)).

Every runtime agent below carries a **Maturity** field
(productive-at-customers vs. roadmap) and a **Licence** flag. Answer both
honestly — blurring the maturity distinction is the fastest way to lose a
regulated buyer's trust.

---

## Non-negotiable principle — agents recommend, humans decide

Runtime agents are **advisory by design**. They score, propose and prepare; a
human accepts, edits or dismisses in the cockpit, and that decision feeds the
learning loop.

No `AG-F-##` agent performs an unattended customer-facing act — no autonomous
send, no autonomous policy change, no autonomous pricing commitment. This is
a deliberate design position for a regulated insurer
([ADR-0014](./docs/adr/ADR-0014-agents-advisory-by-design.md)), and it is what
keeps a named human accountable for every customer-facing decision.

Any proposal to make an agent act autonomously on a customer is a
**governance-changing event**: it requires an ADR and Responsible-AI review
(`AG-E-06`), not a configuration change.

---

## 1. Runtime / functional agents (`AG-F-##`)

Each agent lists **Purpose · Inputs → Outputs · Realizing service · Guardrails
· Side effects · HITL · Maturity · Licence.**

### AG-F-01 — Next-Best-Action Agent (book-wide scoring)

- **Purpose.** Score the whole book on a schedule and on lifecycle events, and
  emit explainable Next-Best-Actions into the advisor cockpit.
- **Inputs → Outputs.** Household / Contact / Policy / Claim / Interaction
  context → ranked, explainable NBA cards with a specific CTA.
- **Realizing service.** Copilot Studio agent / Power Automate + Dataverse;
  scoring grounded on one Dataverse.
- **Guardrails.** Explainability required on every card; consent checked
  before any outbound-capable CTA
  ([ADR-0010](./docs/adr/ADR-0010-consent-per-contact-per-channel.md));
  `LeadCluster` anti-over-contact bundling so one household is not approached
  five times.
- **Side effects.** Writes NBA records; never contacts the customer.
- **HITL.** Advisor accepts / edits / dismisses — the decision is the learning
  signal.
- **Maturity.** `[TBD]` · **Licence.** `[TBD]`

### AG-F-02 — Life-Event & Curveball Detection Agent

- **Purpose.** Detect a material change (address, household composition,
  vehicle, object) and open the cascade the golden thread is validated against.
- **Inputs → Outputs.** Change event on a governed attribute → typed domain
  event + affected-portfolio impact set.
- **Realizing service.** Dataverse change tracking → event → Power Automate /
  Azure integration layer.
- **Guardrails.** Effective dating mandatory
  ([ADR-0011](./docs/adr/ADR-0011-event-driven-cascade.md)); the agent
  identifies impact, it does **not** re-rate — rating stays in the engines of
  record ([ADR-0008](./docs/adr/ADR-0008-thin-crm-over-systems-of-record.md)).
- **Side effects.** Emits events consumed by downstream systems; raises tasks.
- **HITL.** Jurisdiction-changing outcomes always route to a human
  ([ADR-0012](./docs/adr/ADR-0012-jurisdiction-driven-eligibility.md)).
- **Maturity.** Design — implemented for the golden thread. · **Licence.** 🧩

### AG-F-03 — Case Management Agent (prefill)

- **Purpose.** Predict and populate case fields at conversation accept / end.
- **Realizing service.** Out-of-box D365 Case Management Agent.
- **Guardrails.** Prefill is a draft; the agent does not close cases.
- **HITL.** Agent-populated fields are visibly marked so the contribution is
  unmistakable.
- **Maturity.** Native product capability — `[confirm GA status]` · **Licence.** `[TBD]`

### AG-F-04 — Conversation Intelligence & Transcript Agent

- **Purpose.** Summarise the interaction, extract decisions and tasks, and
  write them back with a visible provenance badge.
- **Guardrails.** Every agent-touched row carries a provenance marker;
  records fill through actions rather than being pre-populated.
- **Constraint.** Live transcript + Copilot voice run on the **native voice
  channel only** — not while a third-party contact-centre platform owns the
  call ([ADR-0015](./docs/adr/ADR-0015-voice-channel-boundary.md)).
- **HITL.** Advisor edits before anything is committed.
- **Maturity.** `[TBD]` · **Licence.** `[TBD]`

### AG-F-05 — Data-Quality & Identity-Resolution Agent

- **Purpose.** Detect duplicates and ambiguous identity (e.g. one inbound
  number resolving to several households) and raise closed-loop remediation
  tasks.
- **Guardrails.** Never silently merges a golden record; a merge is a
  human-approved act.
- **HITL.** Agent proposes the match; a steward confirms.
- **Maturity.** Design · **Licence.** 🧩

### AG-F-06 — Campaign & Content Assist Agent

- **Purpose.** Natural-language segment building, content generation and
  channel optimisation for marketing.
- **Guardrails.** Consent per contact per channel enforced as a hard gate
  ([ADR-0010](./docs/adr/ADR-0010-consent-per-contact-per-channel.md));
  central templates and CI/CD rules bind decentral GA campaigns.
- **HITL.** Approval workflow before any activation.
- **Maturity.** Native — `[confirm which sub-capabilities are GA]` · **Licence.** `[TBD]`

> **Not-native, be explicit.** Paid Meta / Google is **not** a native send
> channel — audience activation runs via export connectors. Look-alike
> modelling is not native — it goes to Azure ML. Budget / ROI / CPL is a
> custom table plus Power BI. Say this plainly rather than letting it be
> discovered.

### 1.1 Summary

| Agent | Purpose | Input → Output | Advisory? | Maturity |
| --- | --- | --- | --- | --- |
| AG-F-01 | NBA at scale | context → ranked NBA cards | ✅ | `[TBD]` |
| AG-F-02 | Life-event / curveball cascade | attribute change → domain event | ✅ | Design |
| AG-F-03 | Case prefill | conversation → populated case | ✅ | Native |
| AG-F-04 | Transcript → decisions & tasks | conversation → summary + tasks | ✅ | `[TBD]` |
| AG-F-05 | Identity & data quality | ambiguity → remediation task | ✅ | Design |
| AG-F-06 | Campaign & content assist | brief → segment + content | ✅ | Native |

---

## 2. Engineering / build-time agents (`AG-E-##`)

These are the GitHub Copilot custom agents in [.github/agents/](./.github/agents/).
Each has a matching chatmode in [.github/chatmodes/](./.github/chatmodes/).

| Agent | Role | File |
| --- | --- | --- |
| **AG-E-01** Product Owner | Backlog, use-case framing, acceptance criteria | [product-owner.agent.md](./.github/agents/product-owner.agent.md) |
| **AG-E-02** Developer | Generalist implementation (code, tests, IaC, Power Platform) | [developer.agent.md](./.github/agents/developer.agent.md) |
| **AG-E-03** Enterprise Architect | ADRs, boundaries, integration contracts | [enterprise-architect.agent.md](./.github/agents/enterprise-architect.agent.md) |
| **AG-E-04** SecDevOps | Pipelines, environments, IaC, identity, secrets | [secdevops.agent.md](./.github/agents/secdevops.agent.md) |
| **AG-E-05** CRM Domain Expert | Generic sales / service / marketing practice | [crm-domain-expert.agent.md](./.github/agents/crm-domain-expert.agent.md) |
| **AG-E-06** Responsible-AI & Compliance | RAI, evals, consent, personal-data flows | [responsible-ai-officer.agent.md](./.github/agents/responsible-ai-officer.agent.md) |
| **AG-E-07** Data Engineer & Scientist | Data, signals, features, models, Frontier Firm loop | [data-engineer-scientist.agent.md](./.github/agents/data-engineer-scientist.agent.md) |
| **AG-E-08** Dataverse Modeler | Schema, forms, business rules, solution changes | [dataverse-modeler.agent.md](./.github/agents/dataverse-modeler.agent.md) |
| **AG-E-09** Integration Engineer | API contracts, events, error handling, versioning | [integration-engineer.agent.md](./.github/agents/integration-engineer.agent.md) |
| **AG-E-10** Insurance Domain Expert | Insurance-vertical challenger; complements AG-E-05 | [insurance-domain-expert.agent.md](./.github/agents/insurance-domain-expert.agent.md) |

### Authority

Two decisions cannot be made by an agent alone:

1. **Architecture approval (`AG-E-03`)** — any change to system boundaries, the
   integration contract, the data model core, or the thin-CRM position.
2. **RAI / compliance review (`AG-E-06`)** — any change to models, prompts,
   evaluations, consent handling, or personal-data flows.

Both are enforced as required reviewers via `CODEOWNERS` — see
[SUPERPOWERS_CONTRACT.md](./SUPERPOWERS_CONTRACT.md) §3.

See [.github/agents/AGENT_WORKFLOW.md](./.github/agents/AGENT_WORKFLOW.md)
for the handoff pattern and
[.github/agents/NON_DELEGABLE_WORK.md](./.github/agents/NON_DELEGABLE_WORK.md)
for the decisions no agent may make alone.

---

## 3. End-to-end traceability

```
Requirement (topic area A#)
   → Use case (UC-…)              docs/ideas/
   → ADR                          docs/adr/ADR-####-*.md
   → Solution change              solution/
   → Test                         docs/TEST.md + automated checks
   → Evidence in PR               green pipeline run
   → Deployed to sandbox          the customer sees it running
```

This chain is the answer to A8 (versioning, deployment, test automation,
rollback). It is also the answer to A4's harder question — *what happens to
this extension at the next release?* — because every change carries a recorded
upgrade impact.
