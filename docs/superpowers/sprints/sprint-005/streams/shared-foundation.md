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
- PR [#150](https://github.com/urruegg/CRMShowcase/pull/150) was human-merged
	into `main` at `6459c8c` after CI `gate1` passed.

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
Set-Location C:\Users\urruegg\source\urruegg\wt\sprint-005-resume-checkpoint
git fetch origin
git log -1 --oneline origin/main
git status --short
```

1. Confirm `origin/main` contains merge commit `6459c8c`.
2. Rebase or recreate the B1 and B2 stream worktrees from merged `main`.
3. Run the shared workspace typecheck/tests in each refreshed host worktree.
4. Start Tasks 5-7; B1 and B2 may proceed in parallel without editing shared
	packages.
5. Leave the quality-gates stream blocked until both hosts are merged.
