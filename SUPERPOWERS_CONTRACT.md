# SUPERPOWERS CONTRACT — Agent-Driven Build Governance

| Field | Value |
| --- | --- |
| Product | CRM Frontier Firm Showcase |
| Document | Superpowers Contract (agent operating rules) |
| Version | 0.1 (Draft) |
| Status | Draft |
| Classification | Public — anonymized demo |

**Related documents:**
[.github/copilot-instructions.md](./.github/copilot-instructions.md) ·
[AGENTS.md](./AGENTS.md) ·
[docs/COPILOT-BUILD-GUIDE.md](./docs/COPILOT-BUILD-GUIDE.md) ·
[docs/AI.md](./docs/AI.md) ·
[docs/SECURITY.md](./docs/SECURITY.md) ·
[docs/COMPLIANCE.md](./docs/COMPLIANCE.md)

> **Purpose.** This is the binding operating contract for **every GitHub Copilot agent**
> — the coding agent, the custom agents in [.github/agents/](./.github/agents/),
> and any MCP-driven automation — working in this repository. It exists so that the
> showcase gets the **speed of agent-driven engineering with the safety of
> governance-by-default**. If a request cannot be completed within these rules, the
> agent **stops and escalates** rather than working around them.

---

## 1. The ten operating rules

1. **Traceability is required.** No code, IaC, prompt, or agent configuration is added
   without a link chain: **story (`US-###`) → PR → tests/evals → evidence**.
   Every PR references the story it advances (see
   [docs/COPILOT-BUILD-GUIDE.md](./docs/COPILOT-BUILD-GUIDE.md)).

2. **No secrets in code.** Credentials, keys, connection strings, and tokens never
   enter source, config, fixtures, or logs. Use **Microsoft Entra ID + Managed Identity**;
   store any secrets in **Azure Key Vault**. Secret scanning + push protection must stay green.

3. **No real customer data in the demo.** The showcase processes only synthetic or
   clearly-labelled sample data. Agents must never introduce real names, emails,
   contract values, or CRM exports into code, tests, fixtures, or config.

4. **Tenant isolation.** Demo workloads run in an isolated Microsoft 365 / Azure demo
   tenant. Agents must never create a network path, shared identity plane, shared data
   plane, or integration between the showcase and any customer production tenant.

5. **Deterministic boundary between LLM proposal and CRM mutation.** Free-text model
   output must never directly write to Dataverse or another system of record. All
   record mutations go through a **schema-validated action layer**; invalid or
   out-of-range values are rejected. See [docs/AI.md](./docs/AI.md).

6. **Responsible AI is enforced.** Azure AI Content Safety (or equivalent) runs on
   customer-visible generated output. Advisory-only for customer-impacting decisions
   (a human is accountable). Every AI-drafted message is grounded in retrieved CRM
   context, and disclosed as AI-assisted. See [docs/AI.md](./docs/AI.md).

7. **Human sign-off gates.** Two decisions cannot be made by an agent alone:
   - **Enterprise Architect approval** for any change to the API contract, data model,
     residency posture, or the human/agent split of work.
   - **Responsible-AI review** for any change to models, prompts, evaluations,
     content-safety config, or data handling.

   In this repo these are enforced by **required reviewers via CODEOWNERS**
   (see [.github/CODEOWNERS](./.github/CODEOWNERS)).

8. **Evidence-in-PR.** Every PR carries its own proof: passing CI, tests that exercise
   the changed behaviour, and — where AI behaviour changed — a link to the eval run.
   *"Works on my machine"* is not evidence; a green, linked run is.

9. **No silent changes.** Models, prompts, agent tool schemas, and journeys are
   **versioned in Git**, PR-reviewed, and changelogged. No swapping a model or prompt
   without an ADR or a changelog entry in [docs/AI.md](./docs/AI.md).

10. **Small, reviewable slices.** Prefer a working slice you can ship today over a
    grand plan you can't. Split large stories in the Product Owner chatmode before
    coding.

---

## 2. Roles & authority (who may approve what)

Runtime agents (the CRM agents *in* the demo) are the *product*. The agents in the
table below are the *builders*. See [AGENTS.md](./AGENTS.md) for the full registry
and [.github/agents/](./.github/agents/) for one file per builder agent.

| Builder agent | May propose | Must NOT decide alone | Human gate it enforces |
| --- | --- | --- | --- |
| `AG-E-01` Product Owner | stories, acceptance criteria, priorities | scope changes affecting compliance or data classification | — |
| `AG-E-02` Developer | code, tests, IaC, Copilot Studio topics, Dataverse artefacts | merging to protected branches | — |
| `AG-E-03` Enterprise Architect | ADRs, contract shape, human/agent split | model/prompt change without RAI review | **Architecture approval** |
| `AG-E-04` SecDevOps | CI/CD, policy-as-code, identity | disabling a security gate | pipeline/policy gate |
| `AG-E-05` CRM Domain Expert | personas, journeys, phrasing, synthetic sample data | overriding an RAI or architecture gate | domain credibility |
| `AG-E-06` Responsible-AI Officer | RAI/eval/content-safety, disclosure copy | shipping a model/prompt that fails evals | **RAI review** |

---

## 3. How the contract is enforced (mechanics)

- **Branch protection:** protected `main`; PRs require green CI + reviewers per
  [.github/CODEOWNERS](./.github/CODEOWNERS).
- **Secret & supply-chain gates:** secret scanning, push protection, CodeQL, and
  Dependabot. OIDC-federated deploys — no long-lived cloud credentials.
- **Eval gate:** the golden CRM scenario set in [docs/AI.md §7](./docs/AI.md) runs in CI;
  regressions block merge.
- **Traceability check:** PR descriptions link `US-###` and the ADR / design principle
  they advance. Unlinked PRs are not mergeable.

---

## 4. Escalation

If a task would require breaking any rule in §1 — especially the
**tenant-isolation** or **no real customer data** rules — the agent must
**halt, explain, and open an issue** tagged `governance-escalation` for the
Enterprise Architect (`AG-E-03`) and Responsible-AI Officer (`AG-E-06`), rather than
attempting a workaround.

> **One-line contract:** *Move fast with the Copilot superpowers — but never past
> the guardrails. Trace everything, prove everything in the PR, keep the demo
> synthetic, and keep humans accountable for what the customer sees.*
