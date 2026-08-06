# UC-02 — Power Platform → Git integration (Preview)

| Field | Value |
| --- | --- |
| Status | Deferred idea |
| Owner | AG-E-01 Product Owner |

## What it is

Microsoft's built-in feature that syncs Dataverse solutions ↔ Git directly
from `make.powerapps.com`. Documented in Microsoft Learn under Power
Platform ALM → Git integration.

## Why we didn't adopt it this sprint

- It's Preview — no SLA.
- It requires specific Dev-environment regions / licence tiers the demo
  tenant may not have.
- Its opinions on folder shape may not match our `solution/core/*` +
  `solution/apps/*` layout; retrofitting could churn the whole `solution/`
  folder.

Our current approach — pac CLI + GitHub Actions + on-demand and drift
intake workflows — is boring, well-supported, and covers the same ground.

## Revisit when

- The feature GAs.
- Our maker discipline is proven with the two intake paths (on-demand,
  drift check).
- We hit a scaling limit (>10 solutions or >5 makers) that our current
  intake pattern doesn't handle gracefully.

## Tracking

- GitHub issue: [#5](https://github.com/urruegg/CRMShowcase/issues/5)

## Related

- [Sprint 1 spec](../../superpowers/specs/2026-08-06-solution-containers-design.md)
- [Solution intake workflows](../../../.github/workflows/) — `solution-intake-on-demand.yml`, `solution-intake-drift.yml`
