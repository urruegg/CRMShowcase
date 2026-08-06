# Copilot Build Guide — How PRs Move Through This Repo

| Field | Value |
| --- | --- |
| Version | 0.1 (Draft) |
| Status | Draft |

## 1. The loop

```
Story (US-###)
   └── in docs/PRD.md
       │
       ▼
Branch  feat/US-###-<slug>  or  fix/US-###-<slug>
       │
       ▼
PR  ── title starts with US-###
       │
       ▼
Reviewers per .github/CODEOWNERS
       │
       ▼
Green CI  ─── evals / grounding tests / CodeQL / secret scan
       │
       ▼
Merge (squash)
       │
       ▼
Update the changelog section of docs/AI.md if AI behaviour changed.
```

## 2. Story shape
Every story links to a use case in [PRD.md](./PRD.md) and one or more principles in
[DESIGN-PRINCIPLES.md](./DESIGN-PRINCIPLES.md).

## 3. PR template (paste into every PR description)

```
### What
<one-line summary>

### Story
- US-### — <link or title>

### Design principle / ADR advanced
- DP-## / ADR-####

### Evidence
- [ ] Tests for changed behaviour
- [ ] Grounding tests (if AI path touched)
- [ ] Eval run link (if prompt / model / schema touched)
- [ ] No secrets committed
- [ ] No real customer data introduced

### Governance
- [ ] I read SUPERPOWERS_CONTRACT.md §1 and this PR does not break any rule.
- [ ] Non-delegable decisions in this PR are approved by the right human role.
```

## 4. When to open an ADR
Add an ADR under [adr/](./adr/) when the change:
- Adds or changes an agent tool schema.
- Changes a model choice, a system prompt, or an eval baseline.
- Changes the data model (Dataverse tables, indexes).
- Changes the human/agent split in a workflow.
- Changes the identity or network posture.

## 5. When to refuse
Refuse and open a `governance-escalation` issue if the ask requires:
- Real customer data.
- A path into a customer production tenant.
- Autonomous customer-impacting action without a scoped story.
- Disabling a security or RAI gate.
