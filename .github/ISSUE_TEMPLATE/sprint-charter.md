---
name: Sprint charter
about: Log a sprint designed on the trunk, ready to delegate into streams.
labels: sprint-charter
---

**Sprint ID:** sprint-###

**Design spec:** docs/superpowers/specs/YYYY-MM-DD-…-design.md
**Plan:** docs/superpowers/plans/YYYY-MM-DD-….md
**ADR(s):**

## Outcome

## Streams (each becomes a stream-handover issue)

| Stream | Autonomy class | Goal |
| --- | --- | --- |
| stream-A | EXECUTION-ONLY / DESIGN-SENSITIVE | |

## Definition of done (sprint)

- [ ] All streams merged to main via PR
- [ ] Evidence captured in the sprint STATUS.md
- [ ] DEV evidence: authoring/convergence pipeline green against live DEV,
      linked run + offline test pass/fail counts, in `STATUS.md` under
      `## Live DEV + TEST evidence`
- [ ] TEST evidence: promoted to TEST, linked run + step-by-step result table
      + TEST-side test/smoke counts — **or**, if this sprint's scope does not
      reach TEST, an explicit stated reason (never a silent omission)
      — see [Sprint Operating Model — "Sprint closing"](../../docs/superpowers/SPRINT-OPERATING-MODEL.md#sprint-closing--required-dev--test-evidence)
