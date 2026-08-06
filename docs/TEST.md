# Testing Strategy — CRM Frontier Firm Showcase

| Field | Value |
| --- | --- |
| Version | 0.1 (Draft) |
| Status | Draft |

## 1. Testing philosophy
- **Test the changed behaviour**, not the whole system.
- **AI paths get grounding tests** — the output must reference retrieved context
  or the test fails.
- **Deterministic action layer gets schema tests** — invalid inputs must be rejected.

## 2. Test types

| Type | Where | When it runs |
| --- | --- | --- |
| Unit tests | co-located with code | on every PR |
| Contract tests | at agent tool boundaries | on every PR |
| Grounding tests | for AI paths | on every PR that touches an AI path |
| Eval golden-set | [AI.md §7](./AI.md) | on every PR that touches a prompt / model / tool schema |
| Smoke tests | end-to-end demo happy path | on merge to main |

## 3. Data for tests
- Synthetic-only (DP-05).
- Fixtures live next to their tests, in a `fixtures/` subfolder.
- Fixtures must not reuse names/emails from a real customer.

## 4. What "green" means
- All unit + contract tests pass.
- All grounding tests pass.
- Eval gate is not regressed vs. baseline.
- CodeQL is clean.
- Secret scan is clean.
