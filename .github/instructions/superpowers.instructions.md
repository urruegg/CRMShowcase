---
applyTo: "**"
---

# CRM Showcase Superpowers — Path-Scoped Rules

Apply these rules to all edits in this repository.

1. Keep full traceability in PRs: user story (`US-###`) → change → tests → evidence.
2. Never introduce secrets in code, fixtures, logs, or config. Use Entra ID + Managed Identity + Key Vault.
3. Never introduce real customer data. Only synthetic / clearly-labelled sample data.
4. Never connect the demo to a customer production tenant. Demo tenant only.
5. Customer-visible generated output (emails, chat replies, summaries) must be grounded in retrieved CRM context and pass Content Safety.
6. Human approval is required before agents send external communication, change pricing/quotes, or close cases — unless a story's acceptance criteria explicitly scopes autonomy.
7. Architecture-impacting changes update or add an ADR under [docs/adr/](../../docs/adr/).
8. Models, prompts, and agent tool schemas are versioned in Git, PR-reviewed, and changelogged.
9. Run every sprint or multi-stream build through [docs/superpowers/SPRINT-OPERATING-MODEL.md](../../docs/superpowers/SPRINT-OPERATING-MODEL.md): brainstorm/design on the trunk → Sprint Charter issue + one handover packet per stream (with an autonomy class) → isolated `wt/` worktrees via `scripts/orchestration/*` → PR intake (never self-merge) → human merge. Do not improvise a milestone/epic/branch flow.

See [SUPERPOWERS_CONTRACT.md](../../SUPERPOWERS_CONTRACT.md) and
[copilot-instructions.md](../copilot-instructions.md) for the full policy.
