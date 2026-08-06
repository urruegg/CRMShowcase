# Test Strategy

| Field | Value |
| --- | --- |
| **Topic area** | **A4** · **A8** — Test automation |
| Status | Draft 0.2 · **Owner** `AG-E-04` SecDevOps |

## Principle

A change without a test does not merge. This is what makes the A4
upgrade-safety claim and the A8 controllability claim more than assertions.

## Layers

| Layer | What | Gate |
| --- | --- | --- |
| Solution checker | Platform-level static analysis | Blocks PR |
| Unit | Plugins, custom logic | Blocks PR |
| Integration contract | Schema compatibility in `api/` | Blocks PR on breaking change |
| Regression — golden thread | The eight curveballs (below) | Blocks PR |
| Agent evaluation | Grounding, explainability, guardrails | Blocks PR on regression |
| Deployment smoke | Post-deploy verification | Blocks promotion |

## Golden-thread regression cases

Each curveball is a test that a live end-to-end demo must survive without a
workaround:

1. **Cross-jurisdiction move** fans out to all affected policies with correct
   effective dating ([ADR-0011](./adr/ADR-0011-event-driven-cascade.md)).
2. **Building cover** is withdrawn/re-originated on a jurisdiction change,
   never silently re-priced
   ([ADR-0012](./adr/ADR-0012-jurisdiction-driven-eligibility.md)).
3. **GA reassignment** executes as a governed handover
   ([ADR-0013](./adr/ADR-0013-ga-ownership-and-territory.md)).
4. **Motor factor change** re-rates correctly; vehicle owner ≠ driver respected.
5. **Life event** reshapes household coverage relationships.
6. **Object change** triggers sum-insured re-evaluation.
7. **Policy cancellation** unwinds the portfolio discount on the remainder.
8. **Ambiguous inbound identity** raises a data-quality task, no silent merge.

Plus, always:

- **Consent:** no outbound path executes without evaluating consent
  ([ADR-0010](./adr/ADR-0010-consent-per-contact-per-channel.md)).
- **Failure path:** a failed downstream call dead-letters and replays cleanly.
- **Rollback:** the last deployment can be reversed by pipeline action.

## AI-path tests

- **Grounding.** Draft cites retrieved context that actually exists.
- **Refusal.** When context is insufficient, agent asks a clarifying question.
- **Fairness.** Quality parity across at least two representative cohorts.
- **Regression gate.** Evals run in CI; a regression blocks merge.

## Data

**Synthetic only.** See
[SUPERPOWERS_CONTRACT.md](../SUPERPOWERS_CONTRACT.md) §1 rule 3.

## What "green" means

- All unit + contract tests pass.
- All grounding tests pass.
- Eval gate is not regressed vs. baseline.
- CodeQL is clean.
- Secret scan is clean.
