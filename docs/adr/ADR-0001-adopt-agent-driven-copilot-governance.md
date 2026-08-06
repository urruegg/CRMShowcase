# ADR-0001 — Adopt agent-driven Copilot governance for this repo

| Field | Value |
| --- | --- |
| Status | Accepted |
| Date | 2026-08-06 |
| Deciders | Repo owner |

## Context

CRMShowcase is a public reference implementation of a CRM Frontier Firm — a CRM where
humans and agents work as a team. Copilot (chat, coding agent, custom agents) will be a
first-class contributor to this repo from the start.

Without an explicit contract, agent-driven contributions risk drifting into:
- Ungrounded, plausible-sounding "solutions" that do not match the demo's intent.
- Real customer data leaking into fixtures.
- Silent model, prompt, or tool-schema changes.
- Autonomous customer-impacting actions with no human accountability.

The ATC-LMS repo owned by the same maintainer already runs a mature version of this
pattern (`SUPERPOWERS_CONTRACT.md` + `AGENTS.md` + `.github/agents/` + `.github/instructions/`).
That pattern is proven; the domain content is not reusable here.

## Decision

Adopt the **same governance pattern**, adapted to the CRM Frontier Firm domain:

1. A repo-wide Copilot custom instructions file at `.github/copilot-instructions.md`.
2. A path-scoped superpowers rule file at `.github/instructions/superpowers.instructions.md`.
3. A binding operating contract at `SUPERPOWERS_CONTRACT.md`.
4. A registry of engineering and runtime agents at `AGENTS.md`.
5. One Copilot custom agent per role in `.github/agents/`, with matching chat modes
   in `.github/chatmodes/`.
6. A `docs/` folder holding product, design, AI, security, compliance, and test
   templates the agents reason over.
7. `docs/adr/` for architectural decisions from here on.

## Consequences

**Positive**
- Every contribution — human or agent — is traceable to a story and a principle.
- Non-delegable decisions are named and enforced via CODEOWNERS.
- The showcase itself becomes an example of governed agent-driven engineering.

**Negative / cost**
- Overhead on trivial changes (mitigated by "small slices" principle DP-08).
- The repo owner is currently the sole approver on every path (see CODEOWNERS);
  this should be widened once collaborators exist.

**Follow-ups**
- Enable branch protection on `main` with required reviewers per CODEOWNERS
  once at least one collaborator exists.
- Wire up CI (CodeQL, secret scanning, eval gate) as runtime AI paths land.
- Add an ADR for the first concrete model / prompt choice.
