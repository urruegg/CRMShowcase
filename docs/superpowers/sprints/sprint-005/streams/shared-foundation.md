# Handover Packet - shared-foundation

- **Sprint:** sprint-005
- **Stream:** shared-foundation
- **GitHub issue:** #141
- **Autonomy class:** DESIGN-SENSITIVE
- **Branch:** feat/sprint-005-shared-foundation
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-005-shared-foundation
- **Approved design ref:** ADR-0033; docs/superpowers/specs/2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md; docs/superpowers/plans/2026-08-19-power-apps-code-app-advisor-cockpit-parity.md

## Goal / Definition of Done

- Extract shared domain/UI packages without behavior or pixel drift.
- Add the minimal typed host and write-capability contract.
- Capture approved desktop/mobile visual baselines from the local harness.

## Allowed scope (paths)

- `solution/apps/sales/package*.json`
- `solution/apps/sales/tsconfig*`
- `solution/apps/sales/packages/**`
- `solution/apps/sales/Controls/AdvisorCockpit/**`
- `solution/apps/sales/tests/visual/**`
- `solution/apps/sales/playwright.config.ts`

## Verification commands

```powershell
Push-Location solution/apps/sales
npm test
npm run build
npm run test:visual
Pop-Location
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. Headless streams additionally deny
`shell(git push)`, `shell(rm)`, `shell(git reset)`.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.

## Pause / restart checkpoint - 2026-08-21

### Completed today

- `0353642` extracts the shared npm workspace, domain package, and UI package.
- `29a8578` adds the honest host, data-state, mapping, provenance, and write-
	capability contracts.
- `cd4dafd` adds the user-approved Win32 desktop/mobile Playwright baseline and
	responsive reflow coverage.
- PR [#150](https://github.com/urruegg/CRMShowcase/pull/150) targets `main` and
	is open for human review.

### Final evidence

- `npm audit`: 0 vulnerabilities.
- TypeScript checks: passed for domain, UI, and harness workspaces.
- Vitest: 13 domain tests and 23 harness tests passed.
- Playwright: desktop and mobile comparisons passed without update mode.
- Vite production build and PCF build passed.
- Known non-blocking signal: the fixture harness emits a 520 kB chunk warning.
- Linux visual baselines remain a Task 8 quality-gates responsibility because
	CI uses `ubuntu-latest`; Docker and WSL were unavailable in this session.

### Resume tomorrow

```powershell
Set-Location C:\Users\urruegg\source\urruegg\wt\sprint-005-shared-foundation
gh pr view 150 --json state,mergeStateStatus,statusCheckRollup,reviews,url
git status --short
```

1. Address PR #150 review findings on this branch and rerun the affected gates.
2. Wait for a human to merge PR #150; never self-merge.
3. Refresh `main` and the Sprint 005 status board after merge.
4. Rebase or recreate the B1 and B2 stream worktrees from merged `main`.
5. Start Tasks 5-7 only after the shared-foundation merge is verified.
