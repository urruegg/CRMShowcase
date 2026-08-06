# Copilot Build Guide — the live demonstration

| Field | Value |
| --- | --- |
| **Topic area** | **A4** — Configuration, extensibility, upgrade safety · Proven again at **A8** |
| Status | Draft 0.2 |

## Why this is the centre of the day

Every provider will show a finished Dynamics org. Only one can show **"here is
the repository, here are the agents, here is the ADR, here is the pull
request — and it is now running in your sandbox."**

Topic area A4 asks what extensions cost at the next release. A8 asks for
versioning, deployment, test automation and rollback. A9 asks who is
responsible for what. Those are the parts of an architecture review that
slides cannot win and a working pipeline wins easily.

## The loop

```
change request
  → AG-E-03 Enterprise Architect  → ADR: options · trade-offs · upgrade impact
  → AG-E-02 Developer             → solution change + test
  → AG-E-06 / AG-E-05 review      → guardrails, domain correctness
  → PR                            → CI: build · checker · tests · policy
  → protected environment         → deploy to sandbox
  → refresh                       → it is live
  → rollback                      → and it is gone again
```

## Story shape

Every story links to a use case in [PRD.md](./PRD.md) and one or more
principles in [DESIGN-PRINCIPLES.md](./DESIGN-PRINCIPLES.md).

## PR template (paste into every PR description)

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

## When to open an ADR

Add an ADR under [adr/](./adr/) when the change:

- Adds or changes an agent tool schema.
- Changes a model choice, a system prompt, or an eval baseline.
- Changes the data model (Dataverse tables, indexes).
- Changes the human/agent split in a workflow.
- Changes the identity or network posture.
- Changes the CI / IaC pipeline.

## When to refuse

Refuse and open a `governance-escalation` issue if the ask requires:

- Real customer data.
- A path into a customer production tenant.
- Autonomous customer-impacting action without a scoped story.
- Disabling a security or RAI gate.

## Rules for a live-build demonstration

1. **Never take a cold request on stage.** Offer pre-validated changes you have
   rehearsed. Framing it as a choice gives the same credibility with none of
   the risk.
2. **Rehearse three times, timed.** If it does not fit in the timebox calmly,
   cut its scope.
3. **Never debug live.** If it stalls, switch to the recorded fallback without
   apologising and keep talking. A visible recovery is fine; a visible flail
   is not.
4. **Do not skip the rollback.** It is the single most persuasive moment of the
   day, and it makes the ALM conversation a formality.
5. **Do not oversell.** This is an engineering workflow, not magic. An IT
   audience respects the former and distrusts the latter.

## The candidate changes

Selection criteria: touches the golden thread · pure configuration or low-code
· reversible · under 8 minutes of agent work · licensing flag is ✅ or 🧩.
`[TBD — select and validate before the next review.]`

## Fallback

`[TBD — record a clean run of the full flow and cue it. Test the playback on
the room's hardware.]`
