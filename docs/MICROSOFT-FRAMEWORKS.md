# Microsoft Frameworks — how the showcase aligns

| Field | Value |
| --- | --- |
| Status | Draft 0.1 |
| Owners | `AG-E-03` Enterprise Architect · `AG-E-04` SecDevOps · `AG-E-06` Responsible-AI & Compliance |

The showcase is grounded in four Microsoft frameworks. This page names each
framework, maps the concrete artefacts in this repo that satisfy it, and
states the honest gaps.

We do not claim conformance — the showcase is a public demo. What we claim is
that our design decisions **align with** the framework's principles, and that
we can trace each principle to a specific file or ADR.

## Cloud Adoption Framework (CAF)

CAF is a structured roadmap for adopting Azure and integrating it into
existing IT.
[Reference](https://learn.microsoft.com/azure/cloud-adoption-framework/overview) ·
[seven methodologies](https://learn.microsoft.com/azure/cloud-adoption-framework/overview).

| CAF methodology | Where it lives in this repo |
| --- | --- |
| **Strategy** | [docs/PRD.md](./PRD.md) — outcomes, illustrated vertical. [docs/SD.md](./SD.md) — position. |
| **Plan** | [docs/BACKLOG.md](./BACKLOG.md) — epics and stories. [plan.md](./adr/) (session file) — milestones. |
| **Ready** | [docs/ENVIRONMENTS.md](./ENVIRONMENTS.md) — env slots. [infra/terraform/](../infra/terraform/) — IaC-ready tenant + envs. [docs/adr/ADR-0002](./adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md), [ADR-0003](./adr/ADR-0003-terraform-as-iac-toolchain.md), [ADR-0004](./adr/ADR-0004-ci-plane-app-registrations-and-github-environments.md), [ADR-0005](./adr/ADR-0005-power-platform-application-users-for-ci.md). |
| **Adopt** | [solution/](../solution/) — source-controlled Dataverse solution. [docs/COPILOT-BUILD-GUIDE.md](./COPILOT-BUILD-GUIDE.md) — how PRs move through. |
| **Govern** | [SUPERPOWERS_CONTRACT.md](../SUPERPOWERS_CONTRACT.md) — ten operating rules. [.github/CODEOWNERS](../.github/CODEOWNERS) — required reviewers. [docs/COMPLIANCE.md](./COMPLIANCE.md). [docs/SHARED-RESPONSIBILITY.md](./SHARED-RESPONSIBILITY.md) — RACI. |
| **Secure** | [docs/SECURITY.md](./SECURITY.md) — Zero Trust posture. [ADR-0002](./adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md) — OIDC. [ADR-0004](./adr/ADR-0004-ci-plane-app-registrations-and-github-environments.md) — least-privilege CI. |
| **Manage** | [docs/OPERATIONS.md](./OPERATIONS.md) — pipelines, rollback. [ADR-0017](./adr/ADR-0017-alm-everything-through-the-pipeline.md) — everything through the pipeline. |

**Honest gaps.** Strategy and Plan are shaped for a demo, not a customer
programme; a real engagement redoes both. Ready is fully executed for the
demo tenant only. Manage lacks live observability wiring (Application
Insights, cost dashboards) — flagged for a follow-up story.

## Azure Well-Architected Framework (WAF)

WAF drives architectural excellence across five pillars.
[Reference](https://learn.microsoft.com/azure/well-architected/pillars).

| WAF pillar | Where the showcase implements it |
| --- | --- |
| **Reliability** | [docs/OPERATIONS.md](./OPERATIONS.md) — env topology. [docs/TEST.md](./TEST.md) — layered testing, golden-thread regression. `[TBD]` for RPO/RTO on the demo tenant. |
| **Security** | [docs/SECURITY.md](./SECURITY.md), [ADR-0002](./adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md), [ADR-0004](./adr/ADR-0004-ci-plane-app-registrations-and-github-environments.md), [ADR-0005](./adr/ADR-0005-power-platform-application-users-for-ci.md). Zero Trust posture, no long-lived credentials, least-privilege CI apps. |
| **Cost Optimization** | Terraform lets us right-size and tear down. `[TBD]` — no cost dashboard yet; demo runs on shared MCAPS trial capacity. |
| **Operational Excellence** | [ADR-0017](./adr/ADR-0017-alm-everything-through-the-pipeline.md) — nothing reaches an environment except through the pipeline. Rollback is a pipeline action, not a manual repair. GitHub Actions workflow at [.github/workflows/cd-infra.yml](../.github/workflows/cd-infra.yml) proves the auth loop end-to-end. |
| **Performance Efficiency** | Native platform pillar for now. `[TBD]` — load characteristics unmeasured. |

**Honest gaps.** Cost Optimization and Performance Efficiency are the two
pillars where the showcase is thinnest; the demo tenant is shared MCAPS
capacity and we have no load model. Reliability lacks measured RTO/RPO.
These are the follow-up stories a real engagement would land first.

## Zero Trust

Zero Trust is a modern security approach — *never trust, always verify* —
built on three principles.
[Reference](https://learn.microsoft.com/security/zero-trust/zero-trust-overview).

| Zero Trust principle | Where the showcase implements it |
| --- | --- |
| **Verify explicitly** | Entra ID authentication on every service call. OIDC workload identity federation from GitHub Actions ([ADR-0002](./adr/ADR-0002-oidc-federation-for-github-actions-to-entra.md)) — each CI run presents a signed JWT with subject `repo:{owner}@{id}/{repo}@{id}:environment:{slot}` that Entra verifies before issuing a token. No shared secrets. Federated subject includes numeric IDs so a rename doesn't create a spoofable path. |
| **Use least privilege** | One Entra app registration per environment slot ([ADR-0004](./adr/ADR-0004-ci-plane-app-registrations-and-github-environments.md)). Dataverse app users assigned specific security roles per env ([ADR-0005](./adr/ADR-0005-power-platform-application-users-for-ci.md)) — System Customizer in dev, System Administrator scoped to test. No tenant-wide admin identity for CI. |
| **Assume breach** | No secret to leak — federation replaces client secrets. Each fed cred is scoped to a specific GitHub Environment and ref; a compromise of one repo cannot access another. `[TBD]` — no Sentinel / Defender wiring yet on the demo tenant, so detection is limited to platform-provided signals. |

**Reference architectures we align to:** identity is the control plane;
protection follows the asset; access is validated and monitored; security is
everyone's job. The maintainer's Global Admin sign-in is human-only,
MFA-enforced ([SECURITY.md](./SECURITY.md)).

**Honest gaps.** Data-in-use protection (Confidential Computing) and
end-to-end monitoring (Sentinel, Defender for Cloud) are not yet wired —
flagged for a follow-up ADR.

## Responsible AI (RAI)

The Microsoft Responsible AI Standard is built on six principles.
[Reference](https://learn.microsoft.com/azure/machine-learning/concept-responsible-ai).

| RAI principle | Where the showcase implements it |
| --- | --- |
| **Fairness** | [docs/AI.md](./AI.md) §7.3 — quality parity across at least two representative cohorts is a gate before a model ships. DP-12 in [DESIGN-PRINCIPLES.md](./DESIGN-PRINCIPLES.md). |
| **Reliability and safety** | Golden-set evals with a regression gate blocking merge ([AI.md](./AI.md) §7). Content Safety on customer-visible generation. Deterministic action layer between LLM proposal and CRM mutation ([DATA.md](./DATA.md) — DP-02). Fail-safe refusal patterns when context is insufficient. |
| **Privacy and security** | No real customer data anywhere in the repo ([SUPERPOWERS_CONTRACT.md](../SUPERPOWERS_CONTRACT.md) §1.3, DP-14). No customer PII sent to a model unless the story explicitly requires it. Consent-per-channel gate ([ADR-0010](./adr/ADR-0010-consent-per-contact-per-channel.md)). Grounded generation ([AI.md](./AI.md), DP-13). Tenant-isolated demo ([SECURITY.md](./SECURITY.md)). |
| **Inclusiveness** | Persona breadth in [PERSONAS-JOURNEY.md](./PERSONAS-JOURNEY.md) covers advisor, assistance agent, marketer, broker manager, IT/architect, data steward — not just one power user. `[TBD]` — accessibility review of the UI surface. |
| **Transparency** | Every AI-drafted customer-facing message is disclosed as AI-assisted (DP-11). Agent-touched rows carry a provenance marker ([AGENTS.md](../AGENTS.md), AG-F-04). Every model, prompt, tool schema and feature definition is versioned in Git ([SUPERPOWERS_CONTRACT.md](../SUPERPOWERS_CONTRACT.md) §1.9). Explainability required on every Next-Best-Action ([ADR-0014](./adr/ADR-0014-agents-advisory-by-design.md)). |
| **Accountability** | *Agents recommend; humans decide* ([ADR-0014](./adr/ADR-0014-agents-advisory-by-design.md)). Human approval before outbound send / record mutation. Required reviewers via [.github/CODEOWNERS](../.github/CODEOWNERS). Non-delegable decisions named in [.github/agents/NON_DELEGABLE_WORK.md](../.github/agents/NON_DELEGABLE_WORK.md). Model / prompt / eval changes go through PR review by `AG-E-06`. |

**Honest gaps.** No RAI dashboard integration yet (fairness, error analysis,
model interpretability, counterfactual what-if). No Responsible AI Scorecard.
Accessibility review of the UI is not started. These are follow-up stories
led by `AG-E-06`.

## How to use this page

- **Before opening an ADR** that touches security, identity, or AI, check
  the framework columns above and cite the principle you are advancing.
- **When answering a customer question** on any of the four frameworks, the
  answer is not "yes we do it" — it is the specific file, ADR or workflow
  that proves it, and the specific gap that we have not closed yet.
- **When a gap becomes a blocker**, it becomes a story in
  [BACKLOG.md](./BACKLOG.md).

## Authoritative references

- [Microsoft Cloud Adoption Framework overview](https://learn.microsoft.com/azure/cloud-adoption-framework/overview)
- [Azure Well-Architected Framework pillars](https://learn.microsoft.com/azure/well-architected/pillars)
- [Zero Trust overview](https://learn.microsoft.com/security/zero-trust/zero-trust-overview)
- [What is Responsible AI?](https://learn.microsoft.com/azure/machine-learning/concept-responsible-ai)
- [Microsoft Responsible AI Standard v2 (PDF)](https://blogs.microsoft.com/wp-content/uploads/prod/sites/5/2022/06/Microsoft-Responsible-AI-Standard-v2-General-Requirements-3.pdf)

## Frontier Firm operating model

Microsoft's Work Trend Index research describes the "Frontier Firm" — an organization that restructures how work gets done around human-agent teams, with AI agents taking on defined work alongside employees rather than merely assisting them. This repo's agentic delegated-sprint operating model (see `docs/FRONTIER-OPERATING-MODEL.md`) is a concrete, reduced-scope instantiation of that mental model, scoped to the Contoso Insurance Sales Advisory use case.

- Frontier Firm research and definition: https://www.microsoft.com/en-us/worklab/frontier-firm-resources
- Microsoft Work Trend Index: https://www.microsoft.com/en-us/worklab/work-trend-index
- This repo's adaptation: `docs/FRONTIER-OPERATING-MODEL.md`
- Design pattern walkthrough for stakeholder demos: `docs/design/00-frontier-firm-operating-model-for-insurance.md`
