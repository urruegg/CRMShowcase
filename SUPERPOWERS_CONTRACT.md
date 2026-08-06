# SUPERPOWERS CONTRACT — Agent-Driven Build Governance

| Field | Value |
| --- | --- |
| Product | CRM Frontier Firm Showcase |
| Document | Superpowers Contract (agent operating rules) |
| Version | 0.2 (Draft) |
| Status | Draft |
| Classification | Public — anonymised demo |

**Related:**
[.github/copilot-instructions.md](./.github/copilot-instructions.md) ·
[AGENTS.md](./AGENTS.md) ·
[docs/COPILOT-BUILD-GUIDE.md](./docs/COPILOT-BUILD-GUIDE.md) ·
[docs/AI.md](./docs/AI.md) ·
[docs/SECURITY.md](./docs/SECURITY.md) ·
[docs/COMPLIANCE.md](./docs/COMPLIANCE.md)

> **Purpose.** This is the binding operating contract for **every GitHub
> Copilot agent** — the coding agent, the custom agents in
> [.github/agents/](./.github/agents/) (`AG-E-01`..`AG-E-10`), and any
> MCP-driven automation — working in this repository. It exists so the
> showcase gets the **speed of agent-driven engineering with the safety of
> governance-by-default**. If a request cannot be completed within these rules,
> the agent **stops and escalates** rather than working around them.

> **Why this document matters.** A4 asks what happens to extensions at the
> next release. A8 asks how complexity stays controllable after several
> release cycles. A9 asks how responsibility is split. Those are governance
> questions, and this is the governance — executable, in the repo, not a
> slide.

---

## 1. The ten operating rules

1. **Traceability is required.** No schema change, flow, plug-in, prompt or
   agent is added without the chain: topic area (`A#`) → use case → **ADR** →
   story (`US-###`) → PR → tests / evals → evidence. Every PR references its
   ADR in the description (see
   [docs/COPILOT-BUILD-GUIDE.md](./docs/COPILOT-BUILD-GUIDE.md)).

2. **The CRM stays thin.** Insurance-technical logic — policy, claims and
   quoting — stays in the systems of record. CRM orchestrates demand and
   relationships and holds **external reference keys**, not a second policy
   engine. Absorbing insurance logic into Dataverse is a **stop-and-escalate**
   event
   ([ADR-0008](./docs/adr/ADR-0008-thin-crm-over-systems-of-record.md)).

3. **No real customer data in the demo.** The showcase processes only synthetic
   or clearly-labelled sample data. Agents must never introduce real names,
   emails, contract values, or CRM exports into code, tests, fixtures, or
   config. The golden-thread fixture in
   [data/scenarios/](./data/scenarios/) is synthetic by construction.

4. **No secrets in code.** Credentials, keys, connection strings, and tokens
   never enter source, config, fixtures, or logs. Use **Microsoft Entra ID +
   Managed Identity**; store any secrets in **Azure Key Vault**. Secret
   scanning and push protection must stay green.

5. **Tenant isolation.** Demo workloads run in an isolated Microsoft 365 /
   Azure demo tenant. Agents must never create a network path, shared
   identity plane, shared data plane, or integration between the showcase and
   any customer production tenant.

6. **Consent is a hard gate, not a field.** Consent is modelled per contact
   **per channel** with source and capture date. No outbound path — flow,
   agent, template or custom button — may bypass the consent check. A code
   path that can send without evaluating consent is a **defect**, regardless
   of what the UI does
   ([ADR-0010](./docs/adr/ADR-0010-consent-per-contact-per-channel.md)).

7. **Agents recommend; humans decide.** No runtime agent performs an
   unattended customer-facing act. Making an agent autonomous on a customer
   requires an ADR plus Responsible-AI review (`AG-E-06`) — never a config
   change ([ADR-0014](./docs/adr/ADR-0014-agents-advisory-by-design.md)).

8. **Upgrade impact is declared, always.** Every extension states, in its ADR,
   whether it is configuration, low-code or pro-code, and what it costs at
   the next release. An extension with no declared upgrade impact does not
   merge. This is the executable form of the A4 answer.

9. **No silent changes.** Models, prompts, tool schemas, feature definitions,
   flows and solution components are **versioned in Git**, PR-reviewed, and
   changelogged. No swapping a model, prompt, feature or entity shape without
   an ADR ([docs/AI.md](./docs/AI.md)).

10. **Evidence-in-PR.** Every PR carries its own proof: passing CI, tests that
    exercise the changed behaviour, and — where AI behaviour changed — a link
    to the eval run. *"Works on my machine"* is not evidence; a green, linked
    run is.

---

## 2. Roles & authority (who may approve what)

Runtime agents (the CRM agents *in* the demo) are the *product*. The agents in
the table below are the *builders*. See [AGENTS.md](./AGENTS.md) for the full
registry and [.github/agents/](./.github/agents/) for one file per builder
agent.

| Builder agent | May propose | Must NOT decide alone | Human gate it enforces |
| --- | --- | --- | --- |
| `AG-E-01` Product Owner | stories, acceptance criteria, priorities | scope affecting consent / compliance / maturity | — |
| `AG-E-02` Developer | code, tests, IaC, Copilot Studio topics, Dataverse artefacts | merging to protected branches | — |
| `AG-E-03` Enterprise Architect | ADRs, boundaries, contracts | breaching the thin-CRM position, model-plane change without RAI review | **Architecture approval** |
| `AG-E-04` SecDevOps | CI/CD, policy-as-code, identity | disabling a security or test gate | pipeline / policy gate |
| `AG-E-05` CRM Domain Expert | personas, journeys, phrasing, synthetic sample data | overriding an RAI or architecture gate | domain credibility |
| `AG-E-06` Responsible-AI & Compliance | RAI, evals, consent, personal-data flows | shipping a model / prompt that fails evals | **RAI review** |
| `AG-E-07` Data Engineer & Scientist | signals, features, models, monitoring plans | shipping a model without an eval + monitoring plan | Data-plane review |
| `AG-E-08` Dataverse Modeler | schema, forms, business rules | core data-model change without ADR | EA approval |
| `AG-E-09` Integration Engineer | contracts, events, error handling | breaking-change to a published contract | EA approval |
| `AG-E-10` Insurance Domain Expert | domain rules, terminology, curveballs, test cases | overriding a compliance gate | Domain correctness |

---

## 3. How the contract is enforced (mechanics)

- **Branch protection.** Protected `main`; PRs require green CI and the
  correct required reviewers per [.github/CODEOWNERS](./.github/CODEOWNERS).
- **Protected environments.** Deploy jobs target GitHub Environments with
  required approvals ([ADR-0004](./docs/adr/ADR-0004-ci-plane-app-registrations-and-github-environments.md)).
- **Policy-as-code.** Solution checker and environment policy run in CI; a
  violation fails the PR.
- **Eval gate.** The golden CRM scenario set in
  [docs/AI.md](./docs/AI.md) runs in CI; regressions block merge.
- **Test gate.** Regression suite over the golden thread runs on every PR
  ([docs/TEST.md](./docs/TEST.md)).
- **Secret & supply-chain gates:** secret scanning, push protection, CodeQL,
  Dependabot, OIDC-federated deploys.
- **Traceability check.** The PR template requires an ADR link and an
  evidence link; unlinked PRs are not mergeable.

---

## 4. Escalation

If a task would require breaking any rule in §1 — especially rule 2 (thin
CRM), rule 3 (real customer data), rule 5 (tenant isolation), rule 6 (consent)
or rule 7 (agent autonomy) — the agent must **halt, explain, and open an
issue** using
[the governance-escalation template](./.github/ISSUE_TEMPLATE/governance-escalation.md)
rather than attempting a workaround.

> **One-line contract:** *Move fast with the Copilot superpowers — but never
> past the guardrails. Trace everything, prove everything in the PR, keep the
> CRM thin, keep consent enforced, keep the demo synthetic, and keep a human
> accountable for every customer-facing decision.*
