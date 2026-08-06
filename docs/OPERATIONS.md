# Operations, Lifecycle Management & Technical Governance

| Field | Value |
| --- | --- |
| **Topic area** | **A8** — Operations, lifecycle management, technical governance |
| Status | Draft 0.3 · **Owner** `AG-E-04` SecDevOps |

## Framing — CAF and WAF

Operations of the showcase align with:

- The **Manage**, **Govern**, and **Secure** methodologies of the
  [Cloud Adoption Framework](https://learn.microsoft.com/azure/cloud-adoption-framework/overview).
- The **Operational Excellence** and **Reliability** pillars of the
  [Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/pillars).

Full framework-to-artefact mapping in
[MICROSOFT-FRAMEWORKS.md](./MICROSOFT-FRAMEWORKS.md).

## What the customer asks

Transparency on lifecycle management for configurations, extensions and
integrations — **version control, deployment processes, test automation, and
rollback** — how responsibilities split between customer, implementation
partner and vendor long term, what operating and governance effort is
realistically expected, and **how complexity is reduced or controlled over
time so the platform stays manageable after several release cycles.**

## The answer

[ADR-0017](./adr/ADR-0017-alm-everything-through-the-pipeline.md): **nothing
reaches an environment except through the pipeline.**

```
change request
  → ADR (docs/adr/)
  → solution change + test (solution/)
  → PR — required reviewers via CODEOWNERS
  → CI: build · solution checker · regression · policy-as-code · security gates
  → protected environment approval
  → deploy
  → rollback available as a pipeline action
```

At the end of a review the pipeline history is the evidence: the morning's
change is sitting in it. The topic becomes a review of something the customer
saw, not a claim they have to believe.

## Environments

| Environment | Purpose | Data |
| --- | --- | --- |
| `crmshowdev` | Build | Synthetic |
| `crmshowtest` | Automated regression + demo | Synthetic |
| UAT | Business acceptance | `[TBD — anonymised?]` |
| Prod | Live | Real (customer-side; out of scope for the showcase) |

Detail on the two showcase environments and how they are provisioned:
[ENVIRONMENTS.md](./ENVIRONMENTS.md).

## Rollback

**Rollback must be demonstrable, not described.** If we cannot roll a live
change back in front of the customer, we do not make the claim. Rehearse it.

## Realistic effort — answer honestly

Customers often ask what operating and governance effort is *realistically*
expected. An understated answer is the fastest way to lose credibility with an
operations audience, and it will be tested in year two.

`[TBD — model the effort with the delivery team: platform ops, release
management, test maintenance, integration monitoring, agent evaluation upkeep.]`

## Local pac CLI setup

To work with the six Power Platform solutions locally (`solution/manifest.json`),
install the Power Platform CLI once:

```powershell
# One-off install (a specific stable version — the auto-selected 1.44.x had a
# broken NuGet package at the time of writing)
dotnet tool install --global Microsoft.PowerApps.CLI.Tool --version 1.43.6

# Sign in per environment (device-code, one browser prompt each)
pac auth create --name crmshowdev  --url https://crmshowdev.crm.dynamics.com  --deviceCode
pac auth create --name crmshowtest --url https://crmshowtest.crm.dynamics.com --deviceCode

# Switch between them
pac auth select --name crmshowdev
pac auth select --name crmshowtest

# Verify the active connection
pac org who
```

The auth session is cached in `%LOCALAPPDATA%\.PowerAppsCli` and is separate
from `az` — the `az login` context is NOT reused by `pac`, and vice-versa.

`--url` is deprecated in newer pac releases; `--environment <env-id-or-url>` is
the future-proof form. Both work on 1.43.x.

## How complexity stays controllable

- Every change traceable to an ADR — the estate is self-documenting.
- Extensions carry declared upgrade impact, so technical debt is visible before
  it accrues.
- Standard-first tiering ([EXTENSIBILITY.md](./EXTENSIBILITY.md)) keeps pro-code
  a deliberate, reviewed minority.
- No per-GA forks ([ADR-0013](./adr/ADR-0013-ga-ownership-and-territory.md)).
- **This requires discipline from the customer and the partner too, not only
  from us.** Say that out loud — it is the honest answer and it sets up the
  shared-responsibility conversation.
