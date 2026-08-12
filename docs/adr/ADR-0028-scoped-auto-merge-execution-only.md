# ADR-0028 — Scoped auto-merge for execution-only sprint streams

| Field | Value |
| --- | --- |
| **Status** | Accepted |
| **Date** | 2026-08-12 |
| **Decision mode** | Committed decision |
| **Confidence** | High — repo owner approved the scoped approach; preserves the non-delegable gates |
| **Deciders** | Business owner / repo owner (human) · SecDevOps (AG-E-04) · Enterprise Architect (AG-E-03) · Responsible-AI Officer (AG-E-06) |
| **Topic area** | A8 — ALM · versioning, deployment, delivery velocity |
| **Licence** | 🧩 configuration (GitHub Actions + branch protection) |
| **Upgrade impact** | None — CI/CD governance only; no Dataverse or app surface change |
| **CAF methodology** | Govern · Manage |
| **WAF pillar(s)** | Primary: Operational Excellence (faster, still-gated delivery). Trade-off: velocity vs. review depth — bounded to execution-only work. |
| **Zero Trust** | Auto-merge never bypasses branch protection; least-privilege workflow token; assumes-breach → guarded paths hard-blocked regardless of label. |
| **Responsible AI** | Accountability — any change to models, prompts, evals, consent, or personal-data flows stays human-reviewed (AG-E-06); auto-merge is denied on those paths. |

## Context

Every PR in this repo has been human-merged ("never self-merge"), enforced by a
protected `main` + the sprint operating model. That gate is essential for
architecture and Responsible-AI safety, but applying it to **every** PR —
including routine execution-only work (contract choices, seed fixtures, tests,
docs) — slows sprint velocity, with the human as a serial bottleneck.

The sprint operating model already classifies each stream as **EXECUTION-ONLY**
or **DESIGN-SENSITIVE**. The repo owner asked to speed up by allowing auto-merge
**within a sprint**, while keeping the safety-critical reviews.

Constraint discovered: [`.github/CODEOWNERS`](../../.github/CODEOWNERS) is a
single owner (`* @urruegg`) who is also the usual PR author, so CODEOWNERS does
**not** block self-authored PRs. Any auto-merge mechanism must therefore
**self-guard** the sensitive paths rather than rely on required reviewers.

## Options

### Option A — Keep human-merge on everything (status quo)
Safe, but the human gates every routine PR. Rejected: unnecessary drag on
execution-only work.

### Option B — Scoped auto-merge (execution-only on green CI) ✅ preferred
Auto-merge only PRs labelled `autonomy:execution-only` (and **not**
`autonomy:design-sensitive`) once required CI is green, via GitHub **native
auto-merge**, which never bypasses branch protection. Design-sensitive work and
the non-delegable authorities stay human.

### Option C — Blanket auto-merge of all sprint PRs
Rejected. Removes the architecture (AG-E-03) and Responsible-AI (AG-E-06) gates
the contract calls non-negotiable — unacceptable for a regulated-industry
showcase.

## Decision

Adopt **Option B**. Concretely:

- A label-driven workflow ([`.github/workflows/auto-merge-execution-only.yml`](../../.github/workflows/auto-merge-execution-only.yml))
  enables **native auto-merge** (`gh pr merge --auto --squash`) for a PR only when
  **all** hold: it is labelled `autonomy:execution-only`; it is **not** labelled
  `autonomy:design-sensitive`; it is a same-repo branch (not a fork); and it
  changes **no guarded path**.
- **Native auto-merge honours branch protection** — the PR still merges only when
  the required `gate1` check passes. The workflow adds speed, never a bypass.
- **Guarded paths (hard-blocked regardless of label)** — the non-delegable set:
  `docs/adr/**`, `SUPERPOWERS_CONTRACT.md`, `AGENTS.md`, `.github/**`
  (workflows, agents, instructions, CODEOWNERS, chatmodes), `docs/AI.md`,
  `docs/COMPLIANCE.md`, `docs/SECURITY.md`, `docs/SHARED-RESPONSIBILITY.md`,
  `copilot-studio/**`. A PR touching any of these is left for a human even if
  mislabelled.
- **Autonomy class is assigned by the PR author per stream.** Structural
  data-model / schema **table** changes MUST be `design-sensitive`; additive,
  low-risk contract changes (e.g. new choices) may be `execution-only`.
- **Admin prerequisite (human, once):** enable the repository setting **"Allow
  auto-merge"** (currently off). Until then the workflow logs a note and no-ops
  rather than failing the PR.

The two authorities in [AGENTS.md](../../AGENTS.md) — architecture approval
(AG-E-03) and RAI/compliance review (AG-E-06) — remain **human-only** and are
never auto-merged.

## Consequences

- **Faster:** execution-only streams merge on green CI without waiting on a human.
- **Still safe:** design-sensitive + all guarded paths keep the human gate; native
  auto-merge cannot bypass `gate1` or branch protection; the workflow token is
  least-privilege and restricted to same-repo PRs.
- **Auditable:** every auto-merge is a workflow run with the label + guard checks
  recorded.
- **Updates** the "never self-merge" absolute in
  [SUPERPOWERS_CONTRACT.md](../../SUPERPOWERS_CONTRACT.md) and the
  [Sprint Operating Model](../superpowers/SPRINT-OPERATING-MODEL.md) to
  "execution-only may auto-merge on green CI; design-sensitive and the
  non-delegable authorities stay human."
- Reversible: remove the label, delete the workflow, or disable the repo setting.
