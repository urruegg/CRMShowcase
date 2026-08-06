# Scenario fixtures

**Synthetic data only.** No real customer identity, policy or claims data
enters this repository, the sandbox, or any test — see
[SUPERPOWERS_CONTRACT.md](../../SUPERPOWERS_CONTRACT.md) §1 rule 3.

Owner (data plane): [AG-E-07 Data Engineer & Scientist](../../.github/agents/data-engineer-scientist.agent.md).
Owner (domain correctness): [AG-E-10 Insurance Domain Expert](../../.github/agents/insurance-domain-expert.agent.md).

| Fixture | Purpose |
| --- | --- |
| `smith-household.json` | The golden thread — cross-jurisdiction move. `[TBD — to be generated]` |

Names, addresses, policy numbers and amounts in fixtures are invented. They are
chosen to exercise the curveballs in [TEST.md](../../docs/TEST.md), not to
resemble any real household. Company names use the canonical Microsoft demo
set (Contoso, Fabrikam, Adventure Works).

## Generation rules

- Generators are deterministic given a seed, so the same fixture produces the
  same records every time.
- Every generated field is documented with a distribution and, where relevant,
  a fairness note (the AG-F-05 Data-Quality Agent evaluates outputs on cohorts,
  not aggregates).
- No PII pattern that could accidentally collide with a real person: postal
  codes and jurisdictions are chosen from the illustrated example set, phone
  numbers use documented reserved ranges.
