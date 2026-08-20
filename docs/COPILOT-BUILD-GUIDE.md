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

```text
change request
  → AG-E-03 Enterprise Architect  → ADR: options · trade-offs · upgrade impact
  → AG-E-02 Developer             → solution change + test
  → AG-E-06 / AG-E-05 review      → guardrails, domain correctness
  → PR                            → CI: build · checker · tests · policy
  → protected environment         → deploy to sandbox
  → refresh                       → it is live
  → rollback                      → and it is gone again
```

## Route CRM UX work before building

Use the placement rule committed by
[ADR-0041](./adr/ADR-0041-code-apps-primary-for-bespoke-full-page-crm-ux.md):

1. Model-driven configuration for native forms, views, timelines and commands.
2. Power Apps Code Apps for bespoke full-page CRM experiences.
3. PCF for embedded controls requiring form, dataset or field context.

Code Apps are a pro-code own-build extension even though Power Apps supplies
the managed host. Validate Power Apps Premium and applicable Dynamics 365 /
Copilot Studio rights per persona before rollout.

For bespoke full-page work, use the attended
[Code App Local-First Polish Loop](./superpowers/patterns/code-app-local-first-polish-loop.md):
fixture-backed `npm run dev`, stop the Vite server, authenticated `pa app run`,
then live DEV and TEST evidence. Start each server in a new Visual Studio Code
integrated terminal, open the page inside Visual Studio Code and keep visual
choices attended.

Git remains the source of truth. While noninteractive Code App publication
requires secret-based service-principal authentication, a maker/admin may run
attended `pa app push` in DEV only with reviewed build evidence. No client
secret is stored. TEST receives only the exact managed solution exported from
DEV through the existing OIDC pipeline; direct TEST authoring is prohibited.

The Advisor Cockpit B1 and B2 hosts remain unselected until both produce the
approved live DEV/TEST parity evidence and a human reviews the scorecard.

## Story shape

Every story links to a use case in [PRD.md](./PRD.md) and one or more
principles in [DESIGN-PRINCIPLES.md](./DESIGN-PRINCIPLES.md).

## PR template (paste into every PR description)

```markdown
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
- Introduces a bespoke full-page CRM surface or changes the Code App / PCF /
   model-driven placement rule.

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
The active candidate is named and validated in the approved sprint charter and
handover packet before the demonstration. A substitute is not introduced live.

Pro-code Code App or PCF changes use an attended engineering session rather
than the under-eight-minute configuration/low-code demonstration path.

## Fallback

Use the clean recorded run linked from the sprint evidence when a live service
or environment is unavailable. Verify playback on the room hardware before the
session and state clearly that the recording, not a live deployment, is shown.
