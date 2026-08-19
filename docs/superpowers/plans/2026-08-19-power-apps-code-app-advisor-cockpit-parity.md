# Power Apps Code Apps Advisor Cockpit Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish Power Apps Code Apps as the primary repository path for bespoke full-page CRM experiences and prove standalone B1 versus model-driven-hosted B2 with the complete Advisor Cockpit in DEV and TEST.

**Architecture:** Extract the reviewed Advisor Cockpit implementation into shared domain and UI workspace packages, then consume those packages from two independently initialized Code Apps. B1 runs in the Power Apps player and deep-links to native CRM records; B2 runs through a full-page model-driven sitemap web resource with an allowlisted navigation bridge. Both use app-local generated Dataverse services, one shared mapping/capability contract, environment-bound URLs, and the local fixture-backed PCF harness as the visual baseline.

**Tech Stack:** TypeScript, React 18, Fluent UI v9, Vite, Vitest, React Testing Library, axe, Playwright, npm workspaces, `@microsoft/power-apps`, `@microsoft/power-apps-vite`, Power Apps CLI (`pa`), Dataverse generated services, PowerShell 7, Pester 6, Power Platform solutions, model-driven apps, GitHub Actions, OIDC-based solution promotion.

**Spec:** [2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md](../specs/2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md)

**Traceability:** US-301 · UC-01 · ADR-0014 · ADR-0017 · ADR-0027 · ADR-0033 · new ADR-0041.

**Execution rule:** Commit after every task. Stage and commit only the task's explicit paths. Do not use `git add -A`. Design-sensitive streams run attended; autopilot is permitted only for execution-only packets after their dependencies have merged.

---

## Scope Check

This is one integrated parity proof, not independent products. The shared
extraction and capability contract must land before either host; B1 and B2 may
then proceed in parallel; comparison and TEST evidence require both. Keep one
plan and use isolated Sprint 005 worktrees per stream.

## Stream Map

| Stream | Autonomy | Tasks | Depends on | Allowed scope |
| --- | --- | --- | --- | --- |
| `governance` | DESIGN-SENSITIVE | 0–1 | Approved spec | `docs/**`, `.github/instructions/code-apps.instructions.md`, `.github/agents/ux-designer.agent.md`, governance Pester |
| `shared-foundation` | DESIGN-SENSITIVE | 2–4 | governance | `solution/apps/sales/package*.json`, `solution/apps/sales/tsconfig*`, shared packages, existing AdvisorCockpit harness/PCF imports/tests |
| `b1-standalone` | DESIGN-SENSITIVE | 5 | shared-foundation | `solution/apps/sales/code-apps/advisor-cockpit-b1/**` |
| `b2-embedded` | DESIGN-SENSITIVE | 6–7 | shared-foundation | B2 Code App, host web resource, app contract/publisher/tests |
| `quality-gates` | EXECUTION-ONLY | 8 | Tasks 5–7 | CI workflow, release-policy scripts/tests |
| `dev-proof` | DESIGN-SENSITIVE | 9 | Tasks 5–8 merged | attended DEV config, runbook, Sprint 005 evidence |
| `test-proof` | DESIGN-SENSITIVE | 10 | DEV proof | TEST workflow/smoke, attended advisor evidence |
| `decision-evidence` | DESIGN-SENSITIVE | 11 | DEV + TEST proof | scorecard, ADR-0033 evidence update, sprint close-out |

Do not dispatch `b1-standalone` and `b2-embedded` until `shared-foundation` is
merged. Do not allow either host stream to edit shared packages; shared defects
return to the `shared-foundation` stream.

## Target File Structure

```text
.github/
  instructions/code-apps.instructions.md
  workflows/ci-solution.yml
docs/
  adr/ADR-0041-code-apps-primary-for-bespoke-full-page-crm-ux.md
  superpowers/patterns/code-app-local-first-polish-loop.md
  superpowers/sprints/sprint-005-code-app-parity/
  testing/US-301-code-app-host-parity.md
scripts/solution/
  Publish-CodeAppsDev.ps1
  Test-CodeAppsRelease.ps1
  Get-CodeAppsPromotionFacts.ps1
  tests/CodeAppsGovernance.Tests.ps1
  tests/Publish-CodeAppsDev.Tests.ps1
  tests/Test-CodeAppsRelease.Tests.ps1
  tests/Get-CodeAppsPromotionFacts.Tests.ps1
solution/apps/sales/
  package.json
  package-lock.json
  tsconfig.base.json
  playwright.config.ts
  packages/
    advisor-cockpit-domain/
    advisor-cockpit-ui/
  code-apps/
    advisor-cockpit-b1/
    advisor-cockpit-b2/
  code-app-host/
    advisor-cockpit-code-app-host.html
    advisor-cockpit-code-app-host.js
  Controls/AdvisorCockpit/              # local baseline + thin PCF wrapper
solution/schema/
  advisor-cockpit-app.json
  advisor-cockpit-code-app-host.json
```

---

### Task 0: Create the Sprint 005 Control Plane

**Files:**

- Create: `docs/superpowers/sprints/sprint-005-code-app-parity/sprint.md`
- Create: `docs/superpowers/sprints/sprint-005-code-app-parity/STATUS.md`
- Create: `docs/superpowers/sprints/sprint-005-code-app-parity/streams/*.md`
- Modify: `docs/superpowers/sprints/README.md`

- [ ] **Step 1: Create the Sprint Charter issue**

Run from the trunk checkout:

```powershell
$sprintUrl = gh issue create `
  --title '[Sprint Charter] Sprint 005 - Power Apps Code Apps Advisor Cockpit parity' `
  --label 'sprint-charter' `
  --body 'Approved design: docs/superpowers/specs/2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md. Outcome: establish the Code Apps foundation, prove B1/B2 in DEV and TEST, and produce a human-reviewed recommendation. No B2E, Azure, or Dataverse schema extension.'
if ($LASTEXITCODE -ne 0) { throw 'Sprint Charter issue creation failed.' }
$sprintIssue = [int]($sprintUrl.Trim() -replace '^.*/', '')
$sprintIssue
```

Expected: one issue URL and a numeric `$sprintIssue`.

- [ ] **Step 2: Create one issue per stream and isolated worktrees**

```powershell
$streams = @(
  @{ Id='governance';        Class='DESIGN-SENSITIVE'; Title='S5: Code Apps governance and primary-build rule' },
  @{ Id='shared-foundation'; Class='DESIGN-SENSITIVE'; Title='S5: shared Advisor Cockpit workspace and parity baseline' },
  @{ Id='b1-standalone';     Class='DESIGN-SENSITIVE'; Title='S5: standalone B1 Code App proof' },
  @{ Id='b2-embedded';       Class='DESIGN-SENSITIVE'; Title='S5: embedded B2 Code App proof' },
  @{ Id='quality-gates';     Class='EXECUTION-ONLY';   Title='S5: Code Apps CI and release-policy gates' },
  @{ Id='dev-proof';         Class='DESIGN-SENSITIVE'; Title='S5: attended DEV parity proof' },
  @{ Id='test-proof';        Class='DESIGN-SENSITIVE'; Title='S5: managed TEST parity proof' },
  @{ Id='decision-evidence'; Class='DESIGN-SENSITIVE'; Title='S5: B1/B2 scorecard and recommendation' }
)
. ./scripts/orchestration/New-SprintWorktree.ps1
foreach ($stream in $streams) {
  $url = gh issue create --title $stream.Title --body "Parent Sprint Charter: #$sprintIssue`nApproved design: docs/superpowers/specs/2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md`nAutonomy: $($stream.Class)"
  if ($LASTEXITCODE -ne 0) { throw "Issue creation failed for $($stream.Id)." }
  $issue = [int]($url.Trim() -replace '^.*/', '')
  New-SprintWorktree -SprintId 'sprint-005' -StreamId $stream.Id -IssueNumber $issue -AutonomyClass $stream.Class
}
```

Expected: eight worktrees under `..\wt\` and eight packet files under the
Sprint 005 folder.

- [ ] **Step 3: Write the charter and status board**

The charter must copy the approved spec's Definition of Done verbatim and
include `## Live DEV + TEST evidence`. The initial status table contains one
row per stream with the issue number, autonomy class, branch, PR column, and
`not started` status.

- [ ] **Step 4: Validate orchestration metadata**

Run:

```powershell
Invoke-Pester -Path scripts/orchestration/tests -Output Detailed
. ./scripts/orchestration/Get-SprintStatus.ps1
Get-SprintStatus
```

Expected: all orchestration tests pass and all eight Sprint 005 worktrees are
listed.

- [ ] **Step 5: Commit only sprint control-plane files**

```powershell
git add docs/superpowers/sprints/sprint-005-code-app-parity docs/superpowers/sprints/README.md
git commit -m "docs(sprint-005): charter Code Apps parity proof (US-301)" -- docs/superpowers/sprints/sprint-005-code-app-parity docs/superpowers/sprints/README.md
```

---

### Task 1: Establish the Code Apps Governance Rule

**Files:**

- Create: `docs/adr/ADR-0041-code-apps-primary-for-bespoke-full-page-crm-ux.md`
- Create: `docs/superpowers/patterns/code-app-local-first-polish-loop.md`
- Create: `.github/instructions/code-apps.instructions.md`
- Create: `scripts/solution/tests/CodeAppsGovernance.Tests.ps1`
- Modify: `docs/adr/ADR-0017-alm-everything-through-the-pipeline.md`
- Modify: `docs/adr/ADR-0027-page-level-pcf-and-local-first-polish-loop.md`
- Modify: `docs/EXTENSIBILITY.md`
- Modify: `docs/COPILOT-BUILD-GUIDE.md`
- Modify: `.github/agents/ux-designer.agent.md`

- [ ] **Step 1: Write the failing governance test**

Create `scripts/solution/tests/CodeAppsGovernance.Tests.ps1`:

```powershell
BeforeAll {
    $root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $adr = Join-Path $root 'docs/adr/ADR-0041-code-apps-primary-for-bespoke-full-page-crm-ux.md'
    $pattern = Join-Path $root 'docs/superpowers/patterns/code-app-local-first-polish-loop.md'
    $instructions = Join-Path $root '.github/instructions/code-apps.instructions.md'
}

Describe 'Code Apps governance foundation' {
    It 'records the primary-build decision' {
        Test-Path $adr | Should -BeTrue
        Get-Content $adr -Raw | Should -Match 'Code Apps are primary for bespoke full-page CRM experiences'
    }

    It 'anchors the attended local-first loop' {
        Test-Path $pattern | Should -BeTrue
        $text = Get-Content $pattern -Raw
        $text | Should -Match 'npm run dev'
        $text | Should -Match 'pa app run'
        $text | Should -Match 'Visual Studio Code'
        $text | Should -Match 'DEV and TEST'
    }

    It 'scopes Code App source instructions' {
        Test-Path $instructions | Should -BeTrue
        $text = Get-Content $instructions -Raw
        $text | Should -Match 'power.config.json'
        $text | Should -Match 'generated Dataverse services'
        $text | Should -Match 'no fixture fallback'
    }
}
```

- [ ] **Step 2: Run the governance test and verify RED**

```powershell
Invoke-Pester -Path scripts/solution/tests/CodeAppsGovernance.Tests.ps1 -Output Detailed
```

Expected: FAIL because ADR-0041, the pattern, and instruction file do not exist.

- [ ] **Step 3: Write ADR-0041**

Use `docs/adr/ADR-TEMPLATE.md`. Record these exact committed decisions:

```markdown
## Decision or working hypothesis

Code Apps are primary for bespoke full-page CRM experiences. Model-driven
configuration remains primary for native forms, views, timelines and commands;
PCF remains the extension path for embedded controls requiring form, dataset or
field context. The Advisor Cockpit B1/B2 proof validates host placement without
changing that build rule.

DEV Code App creation and update use an attended maker `pa app push` because
the current noninteractive CLI requires secret-based service-principal
authentication. Git remains source of truth; TEST receives only the managed
solution artifact exported from DEV by the OIDC pipeline. No client secret is
introduced.
```

Options must compare: page-level PCF default; Code Apps for every CRM surface;
and the selected bounded rule above. Set status `Accepted`, decision mode
`Committed decision`, confidence `Medium`, license `🧩`, upgrade impact
`Medium`, and list the DEV/TEST parity evidence as the review trigger.

- [ ] **Step 4: Update existing governance documents**

Make these precise changes:

- ADR-0027 status becomes `Superseded by ADR-0041 for bespoke full-page
  experiences; retained for embedded PCF controls and its local polish method`.
- ADR-0017 gains a bounded exception subsection: attended `pa app push` to DEV,
  reviewed source/build evidence required, no direct TEST authoring, OIDC
  solution export/import unchanged.
- `EXTENSIBILITY.md` distinguishes low-code canvas/model-driven configuration
  from pro-code Code Apps and records the selected build order.
- `COPILOT-BUILD-GUIDE.md` points full-page bespoke work to the Code App loop.
- `ux-designer.agent.md` references the new pattern and keeps visual decisions
  attended.

- [ ] **Step 5: Add path-scoped Code App instructions**

Create `.github/instructions/code-apps.instructions.md`:

```markdown
---
description: Power Apps Code Apps architecture, local development, data access and ALM
applyTo: 'solution/apps/**/{code-apps,packages}/**/*.{ts,tsx,js,json,html,css}'
---

# Power Apps Code Apps

- Start from the current `microsoft/PowerAppsCodeApps` Vite template.
- Use `@microsoft/power-apps` and `@microsoft/power-apps-vite`; keep each app's
  generated `power.config.json`, models and services app-local.
- Use generated Dataverse services. Do not add raw Dataverse Web API calls,
  FetchXML, custom APIs or flows to conceal an unsupported SDK operation.
- Keep fixture adapters local-only. Authenticated and deployed apps have no
  fixture fallback and must show denied, failed, empty and unmapped states.
- Run one server at a time: fixture Vite first, stop it, then `pa app run`.
- Open visual refinement pages inside Visual Studio Code and keep UX decisions
  attended.
- Publish Code Apps into `crmshow_Sales`; promote the exact managed solution
  from DEV to TEST. Never hard-code DEV play URLs in source.
- Preserve agents-recommend/humans-decide and schema-validated writes.
```

- [ ] **Step 6: Run the governance test and full Pester suite**

```powershell
Invoke-Pester -Path scripts/solution/tests/CodeAppsGovernance.Tests.ps1 -Output Detailed
Invoke-Pester -Path scripts/solution/tests -Output Detailed
```

Expected: both invocations pass.

- [ ] **Step 7: Commit governance files**

```powershell
git add docs/adr/ADR-0041-code-apps-primary-for-bespoke-full-page-crm-ux.md docs/adr/ADR-0017-alm-everything-through-the-pipeline.md docs/adr/ADR-0027-page-level-pcf-and-local-first-polish-loop.md docs/EXTENSIBILITY.md docs/COPILOT-BUILD-GUIDE.md docs/superpowers/patterns/code-app-local-first-polish-loop.md .github/instructions/code-apps.instructions.md .github/agents/ux-designer.agent.md scripts/solution/tests/CodeAppsGovernance.Tests.ps1
git commit -m "docs(code-apps): establish primary full-page UX process (US-301)" -- docs/adr/ADR-0041-code-apps-primary-for-bespoke-full-page-crm-ux.md docs/adr/ADR-0017-alm-everything-through-the-pipeline.md docs/adr/ADR-0027-page-level-pcf-and-local-first-polish-loop.md docs/EXTENSIBILITY.md docs/COPILOT-BUILD-GUIDE.md docs/superpowers/patterns/code-app-local-first-polish-loop.md .github/instructions/code-apps.instructions.md .github/agents/ux-designer.agent.md scripts/solution/tests/CodeAppsGovernance.Tests.ps1
```

---

### Task 2: Extract the Shared Workspace Without Behavior Change

**Files:**

- Create: `solution/apps/sales/package.json`
- Create: `solution/apps/sales/package-lock.json`
- Create: `solution/apps/sales/tsconfig.base.json`
- Create: `solution/apps/sales/packages/advisor-cockpit-domain/package.json`
- Create: `solution/apps/sales/packages/advisor-cockpit-domain/tsconfig.json`
- Create: `solution/apps/sales/packages/advisor-cockpit-domain/src/index.ts`
- Create: `solution/apps/sales/packages/advisor-cockpit-ui/package.json`
- Create: `solution/apps/sales/packages/advisor-cockpit-ui/tsconfig.json`
- Create: `solution/apps/sales/packages/advisor-cockpit-ui/src/index.ts`
- Move: `solution/apps/sales/Controls/AdvisorCockpit/src/types.ts`
- Move: `solution/apps/sales/Controls/AdvisorCockpit/src/selectors.ts`
- Move: `solution/apps/sales/Controls/AdvisorCockpit/src/selectors.test.ts`
- Move: `solution/apps/sales/Controls/AdvisorCockpit/src/AdvisorCockpit.tsx`
- Move: `solution/apps/sales/Controls/AdvisorCockpit/src/kpis.ts`
- Move: `solution/apps/sales/Controls/AdvisorCockpit/src/tokens.ts`
- Modify: `solution/apps/sales/Controls/AdvisorCockpit/package.json`
- Modify: `solution/apps/sales/Controls/AdvisorCockpit/tsconfig.json`
- Modify: `solution/apps/sales/Controls/AdvisorCockpit/harness/main.tsx`
- Modify: `solution/apps/sales/Controls/AdvisorCockpit/src/fixtures.ts`
- Modify: `solution/apps/sales/Controls/AdvisorCockpit/src/AdvisorCockpit.test.tsx`
- Modify: `solution/apps/sales/Controls/AdvisorCockpit/pcf/package.json`
- Modify: `solution/apps/sales/Controls/AdvisorCockpit/pcf/package-lock.json`
- Modify: `solution/apps/sales/Controls/AdvisorCockpit/pcf/AdvisorCockpit/index.ts`

- [ ] **Step 1: Capture the pre-move green baseline**

```powershell
Push-Location solution/apps/sales/Controls/AdvisorCockpit
npm test
npm run build
Pop-Location
Push-Location solution/apps/sales/Controls/AdvisorCockpit/pcf
npm run build
Pop-Location
```

Expected: all existing Vitest tests pass, Vite build passes, PCF build passes.
Record the exact counts in Sprint 005 `STATUS.md`.

- [ ] **Step 2: Create the workspace root**

Create `solution/apps/sales/package.json`:

```json
{
  "name": "@crmshow/sales-apps",
  "private": true,
  "workspaces": [
    "packages/*",
    "code-apps/*",
    "Controls/AdvisorCockpit"
  ],
  "scripts": {
    "build": "npm run build --workspace @crmshow/advisor-cockpit-domain && npm run build --workspace @crmshow/advisor-cockpit-ui && npm run build --workspace @crmshow/advisor-cockpit-harness && npm --prefix Controls/AdvisorCockpit/pcf run build",
    "test": "npm run test --workspace @crmshow/advisor-cockpit-domain && npm run test --workspace @crmshow/advisor-cockpit-harness",
    "typecheck": "npm run typecheck --workspaces --if-present"
  },
  "devDependencies": {
    "typescript": "^5.5.4"
  }
}
```

Create `solution/apps/sales/tsconfig.base.json` with the existing strict compiler
options and `moduleResolution: "bundler"`.

- [ ] **Step 3: Create focused package manifests**

Domain package:

```json
{
  "name": "@crmshow/advisor-cockpit-domain",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "exports": { ".": "./src/index.ts" },
  "scripts": {
    "build": "tsc --noEmit",
    "typecheck": "tsc --noEmit",
    "test": "vitest run"
  },
  "devDependencies": {
    "typescript": "^5.5.4",
    "vitest": "^4.1.10"
  }
}
```

UI package:

```json
{
  "name": "@crmshow/advisor-cockpit-ui",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "exports": { ".": "./src/index.ts" },
  "scripts": {
    "build": "tsc --noEmit",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@crmshow/advisor-cockpit-domain": "0.1.0",
    "@fluentui/react-components": "^9.54.0",
    "@fluentui/react-icons": "^2.0.245"
  },
  "peerDependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  }
}
```

Each package `tsconfig.json` extends `../../tsconfig.base.json` and includes
only `src`.

- [ ] **Step 4: Move files mechanically**

```powershell
git mv solution/apps/sales/Controls/AdvisorCockpit/src/types.ts solution/apps/sales/packages/advisor-cockpit-domain/src/types.ts
git mv solution/apps/sales/Controls/AdvisorCockpit/src/selectors.ts solution/apps/sales/packages/advisor-cockpit-domain/src/selectors.ts
git mv solution/apps/sales/Controls/AdvisorCockpit/src/selectors.test.ts solution/apps/sales/packages/advisor-cockpit-domain/src/selectors.test.ts
git mv solution/apps/sales/Controls/AdvisorCockpit/src/AdvisorCockpit.tsx solution/apps/sales/packages/advisor-cockpit-ui/src/AdvisorCockpit.tsx
git mv solution/apps/sales/Controls/AdvisorCockpit/src/kpis.ts solution/apps/sales/packages/advisor-cockpit-ui/src/kpis.ts
git mv solution/apps/sales/Controls/AdvisorCockpit/src/tokens.ts solution/apps/sales/packages/advisor-cockpit-ui/src/tokens.ts
```

Create package barrels:

```ts
// packages/advisor-cockpit-domain/src/index.ts
export * from './types';
export * from './selectors';

// packages/advisor-cockpit-ui/src/index.ts
export * from './AdvisorCockpit';
export * from './tokens';
```

Update UI imports from `./types` and `./selectors` to
`@crmshow/advisor-cockpit-domain`. Update the harness, tests, fixture adapter,
and PCF wrapper to import `AdvisorCockpit` from
`@crmshow/advisor-cockpit-ui` and types from the domain package.

Rename the existing harness package and add the workspace dependencies:

```powershell
Push-Location solution/apps/sales/Controls/AdvisorCockpit
npm pkg set name='@crmshow/advisor-cockpit-harness'
npm pkg set dependencies.'@crmshow/advisor-cockpit-domain'='0.1.0'
npm pkg set dependencies.'@crmshow/advisor-cockpit-ui'='0.1.0'
Pop-Location
Push-Location solution/apps/sales/Controls/AdvisorCockpit/pcf
npm pkg set dependencies.'@crmshow/advisor-cockpit-domain'='file:../../../packages/advisor-cockpit-domain'
npm pkg set dependencies.'@crmshow/advisor-cockpit-ui'='file:../../../packages/advisor-cockpit-ui'
Pop-Location
```

The PCF package stays outside the npm workspace because nesting it inside the
harness workspace produces ambiguous npm ownership. It consumes the same
source packages through explicit local file dependencies and keeps its own
lockfile.

- [ ] **Step 5: Install once at the workspace root**

```powershell
Push-Location solution/apps/sales
npm install
Pop-Location
Push-Location solution/apps/sales/Controls/AdvisorCockpit/pcf
npm install
Pop-Location
```

Expected: `solution/apps/sales/package-lock.json` is generated and workspace
packages are linked. Do not create or modify a repository-root lockfile.

- [ ] **Step 6: Run post-move verification**

```powershell
Push-Location solution/apps/sales
npm test
npm run build
Pop-Location
```

Expected: the exact pre-move tests/builds remain green with no behavior change.

- [ ] **Step 7: Commit the extraction**

```powershell
git add solution/apps/sales/package.json solution/apps/sales/package-lock.json solution/apps/sales/tsconfig.base.json solution/apps/sales/packages solution/apps/sales/Controls/AdvisorCockpit
git commit -m "refactor(code-apps): extract shared Advisor Cockpit packages (US-301)" -- solution/apps/sales/package.json solution/apps/sales/package-lock.json solution/apps/sales/tsconfig.base.json solution/apps/sales/packages solution/apps/sales/Controls/AdvisorCockpit
```

---

### Task 3: Add the Minimal Host and Write-Capability Contract

**Files:**

- Create: `solution/apps/sales/packages/advisor-cockpit-domain/src/capabilities.ts`
- Create: `solution/apps/sales/packages/advisor-cockpit-domain/src/capabilities.test.ts`
- Create: `solution/apps/sales/packages/advisor-cockpit-domain/src/data-state.ts`
- Create: `solution/apps/sales/packages/advisor-cockpit-domain/src/gateway.ts`
- Create: `solution/apps/sales/packages/advisor-cockpit-domain/src/source-rows.ts`
- Create: `solution/apps/sales/packages/advisor-cockpit-domain/src/map-cockpit-rows.ts`
- Create: `solution/apps/sales/packages/advisor-cockpit-domain/src/map-cockpit-rows.test.ts`
- Create: `solution/apps/sales/packages/advisor-cockpit-domain/src/provenance.ts`
- Create: `solution/apps/sales/packages/advisor-cockpit-domain/src/write-capabilities.ts`
- Create: `solution/apps/sales/packages/advisor-cockpit-domain/src/write-capabilities.test.ts`
- Create: `solution/apps/sales/packages/advisor-cockpit-ui/src/CapabilityButton.tsx`
- Create: `solution/apps/sales/Controls/AdvisorCockpit/src/fixtureHost.ts`
- Modify: `solution/apps/sales/packages/advisor-cockpit-domain/src/index.ts`
- Modify: `solution/apps/sales/packages/advisor-cockpit-ui/src/AdvisorCockpit.tsx`
- Modify: `solution/apps/sales/packages/advisor-cockpit-ui/src/tokens.ts`
- Modify: `solution/apps/sales/Controls/AdvisorCockpit/src/AdvisorCockpit.test.tsx`
- Modify: `solution/apps/sales/Controls/AdvisorCockpit/harness/main.tsx`
- Modify: `solution/apps/sales/Controls/AdvisorCockpit/pcf/AdvisorCockpit/index.ts`

- [ ] **Step 1: Write failing contract tests**

Create tests that assert:

```ts
import { describe, expect, it } from 'vitest';
import { writeCapabilities } from './write-capabilities';

describe('writeCapabilities', () => {
  it('documents every visible write and never labels a blocked action supported', () => {
    expect(Object.keys(writeCapabilities).sort()).toEqual([
      'acceptNba', 'assignLead', 'bundleLeads', 'call', 'createAppointment', 'createTask',
      'dismissNba', 'editNba', 'savePersonalView', 'snoozeNba', 'splitLeads',
      'updateLeadQueueStatus',
    ]);
    expect(writeCapabilities.assignLead.availability).toBe('blocked');
    expect(writeCapabilities.createTask.availability).toBe('blocked');
    expect(writeCapabilities.dismissNba.availability).toBe('partial');
  });
});
```

Add a UI test proving a blocked `assignLead` command renders a disabled button
whose accessible description contains `polymorphic owner lookup`.

- [ ] **Step 2: Run tests and verify RED**

```powershell
Push-Location solution/apps/sales
npm test
Pop-Location
```

Expected: FAIL because the capability files and host prop do not exist.

- [ ] **Step 3: Add the closed capability types**

Create `capabilities.ts`:

```ts
export type HostKind = 'fixture-harness' | 'pcf-artifact' | 'standalone-code-app' | 'embedded-code-app';
export type CapabilityAvailability = 'supported' | 'partial' | 'blocked' | 'unverified';
export type CockpitWriteCommand =
  | { type: 'acceptNba'; nbaId: string }
  | { type: 'assignLead'; leadIds: string[]; ownerId: string }
  | { type: 'bundleLeads'; leadIds: string[]; clusterId: string }
  | { type: 'splitLeads'; leadIds: string[] }
  | { type: 'updateLeadQueueStatus'; leadId: string; status: string }
  | { type: 'dismissNba'; nbaId: string }
  | { type: 'snoozeNba'; nbaId: string }
  | { type: 'editNba'; nbaId: string; changes: Readonly<{ channel?: string; rank?: number }> }
  | { type: 'createAppointment'; accountId: string }
  | { type: 'createTask'; accountId: string }
  | { type: 'call'; phoneNumber: string }
  | { type: 'savePersonalView'; name: string };

export interface RuntimeContext {
  hostKind: HostKind;
  appId: string | null;
  environmentId: string | null;
  sessionId: string | null;
  userObjectId: string | null;
  locale: string;
}

export interface CommandCapability {
  availability: CapabilityAvailability;
  reason: string;
  target: string;
}

export interface CommandResult {
  ok: boolean;
  message: string;
}

export interface AdvisorCockpitHost {
  context: RuntimeContext;
  capability(command: CockpitWriteCommand['type']): CommandCapability;
  execute(command: CockpitWriteCommand): Promise<CommandResult>;
  navigate(table: 'account' | 'lead' | 'crmshow_claimprojection', id: string): Promise<void>;
}
```

Create `data-state.ts` with a closed union for `ready`, `empty`, `denied`,
`error`, `unsupported`, and `unmapped`. Create `provenance.ts` with
`'crm' | 'external' | 'unmapped'`; map CRM to normal, external to grey, and
unmapped to yellow. Rename internal `dbx` provenance usages to `external`, but
preserve the approved visible `Databricks (Mock)` legend wording for this parity
sprint; translated labels and a more generic external-source vocabulary are a
later requirement, not a parity change.

Create `gateway.ts` so both app-local generated adapters implement one exact
interface:

```ts
import type { CockpitData, LeadRecord, NbaRecord } from './types';
import type { DataState } from './data-state';

export interface NbaChanges {
  channel?: string;
  rank?: number;
}

export interface CockpitDataGateway {
  load(): Promise<DataState<CockpitData>>;
  updateNbaStatus(id: string, status: 'Accepted' | 'Planned' | 'Dismissed'): Promise<NbaRecord>;
  updateNba(id: string, changes: NbaChanges): Promise<NbaRecord>;
  updateLeadQueueStatus(id: string, status: string): Promise<LeadRecord>;
  setLeadCluster(id: string, clusterId: string | null): Promise<LeadRecord>;
}
```

`source-rows.ts` declares the canonical selected fields for each existing
table. `map-cockpit-rows.ts` accepts those canonical arrays, joins only by
primary GUID, and returns `CockpitData`; its tests cover missing lookups,
permission-denied regions, external provenance, and unmapped values. Generated
models never leak into the shared packages.

- [ ] **Step 4: Implement the initial write matrix**

`write-capabilities.ts` records the exact expectations approved by the spec:

```ts
export const writeCapabilities = {
  acceptNba: { availability: 'unverified', reason: 'Generated-service update and reread must pass live verification.', target: 'crmshow_nextbestaction.crmshow_status' },
  call: { availability: 'partial', reason: 'Phone launch only; activity logging is not supported.', target: 'tel:' },
  dismissNba: { availability: 'partial', reason: 'Status can be stored; no dismissal-reason field exists.', target: 'crmshow_nextbestaction.crmshow_status' },
  snoozeNba: { availability: 'partial', reason: 'Maps to Planned; no snooze-until field exists.', target: 'crmshow_nextbestaction.crmshow_status' },
  editNba: { availability: 'partial', reason: 'Only existing allowlisted NBA fields can change.', target: 'crmshow_nextbestaction' },
  updateLeadQueueStatus: { availability: 'unverified', reason: 'Generated-service update must pass live verification.', target: 'lead.crmshow_leadqueuestatus' },
  bundleLeads: { availability: 'unverified', reason: 'Lookup association must pass generated-service verification.', target: 'lead.crmshow_leadclusterid' },
  splitLeads: { availability: 'unverified', reason: 'Lookup disassociation must pass generated-service verification.', target: 'lead.crmshow_leadclusterid' },
  assignLead: { availability: 'blocked', reason: 'Generated services do not support the polymorphic owner lookup required here.', target: 'lead.ownerid' },
  createAppointment: { availability: 'blocked', reason: 'The regarding relationship is polymorphic.', target: 'appointment.regardingobjectid' },
  createTask: { availability: 'blocked', reason: 'The regarding relationship is polymorphic.', target: 'task.regardingobjectid' },
  savePersonalView: { availability: 'blocked', reason: 'No governed roaming preference contract exists.', target: 'user preference' },
} as const;
```

- [ ] **Step 5: Refactor the UI through one host prop**

Change the component signature at the current `AdvisorCockpitProps` seam:

```ts
export interface AdvisorCockpitProps {
  data: CockpitData;
  host: AdvisorCockpitHost;
}

export function AdvisorCockpit({ data, host }: AdvisorCockpitProps): JSX.Element {
```

Create `CapabilityButton.tsx` to wrap disabled Fluent buttons in a focusable
tooltip span. Use `aria-disabled="true"` plus click/keyboard interception rather
than the native `disabled` appearance so unsupported commands remain focusable,
explainable, and pixel-neutral against the approved harness. Replace
demo-success handlers for assign, bundle, split, create
task/appointment, NBA accept/dismiss/snooze/edit, and call with
`host.execute(...)`.
Local filters, sorting, tab changes, selection, and dialogs remain local UI
behavior. A command result is announced through the existing `aria-live`
region. Do not display success before the promise resolves.

This task must not move, resize, relabel, recolor, or add visible controls. Run
the existing component tests and inspect the local harness inside VS Code before
acceptance. Any visible drift is a defect and must be fixed before Task 4
captures the baseline.

- [ ] **Step 6: Add honest fixture/PCF hosts**

`fixtureHost.ts` returns the static capability matrix and rejects every write
with `ok: false`; it permits local UI operations and records no fake Dataverse
success. The PCF artifact uses the same fixture host because it remains a
non-user-visible fixture artifact.

- [ ] **Step 7: Run tests and builds**

```powershell
Push-Location solution/apps/sales
npm test
npm run build
Pop-Location
```

Expected: all prior interaction tests plus capability tests pass. Tests that
previously asserted demo success now assert disabled state and the documented
reason.

- [ ] **Step 8: Commit the host contract**

```powershell
git add solution/apps/sales/packages solution/apps/sales/Controls/AdvisorCockpit
git commit -m "feat(code-apps): add honest host capability contract (US-301)" -- solution/apps/sales/packages solution/apps/sales/Controls/AdvisorCockpit
```

---

### Task 4: Capture the Local Harness Visual Baseline

**Files:**

- Create: `solution/apps/sales/playwright.config.ts`
- Create: `solution/apps/sales/tests/visual/advisor-cockpit-parity.spec.ts`
- Create: `solution/apps/sales/tests/visual/advisor-cockpit-parity.spec.ts-snapshots/*`
- Modify: `solution/apps/sales/package.json`
- Modify: `solution/apps/sales/package-lock.json`
- Modify: `solution/apps/sales/Controls/AdvisorCockpit/vite.config.ts`
- Modify: `docs/superpowers/sprints/sprint-005-code-app-parity/STATUS.md`

- [ ] **Step 1: Add Playwright and write the missing-baseline test**

Install at the workspace root:

```powershell
Push-Location solution/apps/sales
npm install --save-dev @playwright/test@^1.55.0
npx playwright install chromium
Pop-Location
```

Create a test with fixed viewports:

```ts
import { expect, test } from '@playwright/test';

for (const viewport of [
  { name: 'desktop', width: 1440, height: 1000 },
  { name: 'mobile', width: 390, height: 844 },
]) {
  test(`fixture harness ${viewport.name}`, async ({ page }) => {
    await page.setViewportSize(viewport);
    await page.goto('/');
    await expect(page.getByText('Arbeitsvorrat & persönliche Ziele')).toBeVisible();
    await expect(page).toHaveScreenshot(`advisor-cockpit-${viewport.name}.png`, {
      fullPage: true,
      animations: 'disabled',
    });
  });
}
```

Configure `webServer.command` as
`npm run dev --workspace @crmshow/advisor-cockpit-harness -- --host 127.0.0.1`
and `baseURL` as `http://127.0.0.1:5173`.

- [ ] **Step 2: Run once and verify missing snapshots**

```powershell
Push-Location solution/apps/sales
npx playwright test tests/visual/advisor-cockpit-parity.spec.ts
Pop-Location
```

Expected: FAIL because approved baseline snapshots do not exist.

- [ ] **Step 3: Capture and review snapshots inside VS Code**

```powershell
Push-Location solution/apps/sales
npx playwright test tests/visual/advisor-cockpit-parity.spec.ts --update-snapshots
Pop-Location
```

Open both images inside VS Code. Start the harness in a new integrated terminal,
open `http://127.0.0.1:5173` inside VS Code, share it with Copilot, and obtain
explicit user approval before accepting the images. Record the approval and
viewport dimensions in `STATUS.md`.

- [ ] **Step 4: Run visual tests without update mode**

```powershell
Push-Location solution/apps/sales
npx playwright test tests/visual/advisor-cockpit-parity.spec.ts
Pop-Location
```

Expected: both screenshot comparisons pass.

- [ ] **Step 5: Commit the visual baseline**

```powershell
git add solution/apps/sales/package.json solution/apps/sales/package-lock.json solution/apps/sales/playwright.config.ts solution/apps/sales/tests/visual solution/apps/sales/Controls/AdvisorCockpit/vite.config.ts docs/superpowers/sprints/sprint-005-code-app-parity/STATUS.md
git commit -m "test(code-apps): capture approved cockpit visual baseline (US-301)" -- solution/apps/sales/package.json solution/apps/sales/package-lock.json solution/apps/sales/playwright.config.ts solution/apps/sales/tests/visual solution/apps/sales/Controls/AdvisorCockpit/vite.config.ts docs/superpowers/sprints/sprint-005-code-app-parity/STATUS.md
```

---

### Task 5: Build the Standalone B1 Code App

**Files:**

- Create: `solution/apps/sales/code-apps/advisor-cockpit-b1/**`
- Modify: `solution/apps/sales/package-lock.json`

- [ ] **Step 1: Scaffold from the official Vite template**

```powershell
npx degit github:microsoft/PowerAppsCodeApps/templates/vite solution/apps/sales/code-apps/advisor-cockpit-b1
Push-Location solution/apps/sales/code-apps/advisor-cockpit-b1
npm pkg set name='@crmshow/advisor-cockpit-b1'
npm pkg set private=true --json
npm pkg set dependencies.'@crmshow/advisor-cockpit-domain'='0.1.0'
npm pkg set dependencies.'@crmshow/advisor-cockpit-ui'='0.1.0'
npm pkg set dependencies.react='^18.3.1'
npm pkg set dependencies.react-dom='^18.3.1'
npm pkg set devDependencies.'@types/react'='^18.3.3'
npm pkg set devDependencies.'@types/react-dom'='^18.3.0'
npm pkg set devDependencies.vitest='^4.1.10'
npm pkg set devDependencies.jsdom='^24.1.1'
npm pkg set devDependencies.'@testing-library/react'='^16.0.1'
npm pkg set devDependencies.'@testing-library/jest-dom'='^6.4.8'
npm pkg set scripts.test='vitest run'
Pop-Location
Push-Location solution/apps/sales
npm install
Pop-Location
```

Verify `vite.config.ts` contains `react()` and `powerApps()` and `build` runs
`tsc -b && vite build`. The current Microsoft template starts on React 19;
the commands above intentionally normalize B1 to React 18.3.1 so PCF, the
shared UI and both Code Apps compare one React runtime rather than host plus
framework-version differences.

- [ ] **Step 2: Write a failing shell test**

Create `vitest.config.ts`:

```ts
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test-setup.ts'],
  },
});
```

Create `src/test-setup.ts` with
`import '@testing-library/jest-dom/vitest';`. Create `src/App.test.tsx`; render
B1 with an injected fake `CockpitDataGateway` and `RuntimeContext`, then assert:

```ts
expect(screen.getByText('Arbeitsvorrat & persönliche Ziele')).toBeInTheDocument();
expect(screen.getByTestId('host-kind')).toHaveTextContent('standalone-code-app');
expect(screen.queryByText(/fixture mode/i)).not.toBeInTheDocument();
```

Run `npm test --workspace @crmshow/advisor-cockpit-b1`; expect FAIL because the
B1 app shell does not exist.

- [ ] **Step 3: Add the pass-through provider and runtime context**

Keep SDK v1 initialization as a pass-through:

```tsx
export function PowerProvider({ children }: React.PropsWithChildren): JSX.Element {
  return <>{children}</>;
}
```

Use `getContext()` to map app, user, environment and session values into the
shared `RuntimeContext`. Render loading and explicit context failure states.

- [ ] **Step 4: Initialize B1 in DEV through an attended terminal**

Preflight:

```powershell
if (-not $env:POWER_PLATFORM_DEV_ENVIRONMENT_ID) { throw 'POWER_PLATFORM_DEV_ENVIRONMENT_ID is required.' }
pa auth status --json
Push-Location solution/apps/sales/code-apps/advisor-cockpit-b1
pa app init --display-name 'Advisor Cockpit - Standalone Proof' --environment-id $env:POWER_PLATFORM_DEV_ENVIRONMENT_ID --build-path dist
Pop-Location
```

Expected: B1 `power.config.json` is generated for the authenticated demo tenant.

- [ ] **Step 5: Add existing Dataverse tables**

```powershell
$tables = @(
  'account','contact','lead','appointment','task','systemuser','businessunit',
  'crmshow_leadcluster','crmshow_policyprojection','crmshow_claimprojection',
  'crmshow_nextbestaction','crmshow_nbaprovenance','crmshow_measuresnapshot'
)
Push-Location solution/apps/sales/code-apps/advisor-cockpit-b1
foreach ($table in $tables) {
  pa app add data-source --connector dataverse --table $table
  if ($LASTEXITCODE -ne 0) { throw "B1 data-source generation failed for $table." }
}
Pop-Location
```

Expected: generated model/service files exist under `src/generated`; no schema
is created or changed.

- [ ] **Step 6: Add the generated-service gateway and loader**

First create `src/data/generatedGateway.test.ts`. Mock the app-local binding
object and assert every `getAll` call supplies an explicit `select`, bounded
`top`, and where applicable `filter`/`orderBy`; assert the returned canonical
rows are passed to `mapCockpitRows`; assert a thrown service error returns the
`error` state and never imports fixtures. Run the focused test and expect FAIL.

Then create `src/data/generatedBindings.ts` with direct imports from the files
created under `src/generated/services` and expose only `{ get, getAll, update }`
methods needed by `GeneratedCockpitGateway`. Do not edit generated files. Create
`src/data/GeneratedCockpitGateway.ts` implementing the shared
`CockpitDataGateway`. Use narrow `select`, `filter`, `orderBy`, `top`, and
paging options; normalize generated models into the canonical source-row types;
call shared `mapCockpitRows` for all joins by primary GUID. It must never import
`fixtures.ts` or `data/scenarios`.

For NBA writes, allowlist `crmshow_status`, `crmshow_channel`, and fields already
declared in `insurance-foundation.json`; send only changed properties; reread
the NBA after update before returning success. `acceptNba`, `snoozeNba`, and
`dismissNba` map only to the existing status choices `Accepted`, `Planned`, and
`Dismissed`. Convert those semantic names through constants/types emitted by
B1's generated model; never hard-code Dataverse option integers. The gateway
test must assert all three mappings and fail if a generated option is absent.

- [ ] **Step 7: Implement standalone navigation**

Build native MDA links from `context.app.dataverseOrgUrl`, allowlisted table
logical name, and validated GUID. Use `window.open(url, '_blank',
'noopener,noreferrer')`. `call` may use a validated `tel:` link; it must not
claim activity logging.

- [ ] **Step 8: Run B1 tests, build and authenticated local host**

```powershell
Push-Location solution/apps/sales
npm test --workspace @crmshow/advisor-cockpit-b1
npm run build --workspace @crmshow/advisor-cockpit-b1
Pop-Location
Push-Location solution/apps/sales/code-apps/advisor-cockpit-b1
pa app run
```

Open the Local Play URL inside VS Code with the tenant profile. Verify live
reads, denied/error states, supported NBA status update+reread, and native
record links. Stop the server before any other local host starts.

- [ ] **Step 9: Commit B1**

```powershell
git add solution/apps/sales/code-apps/advisor-cockpit-b1 solution/apps/sales/package-lock.json
git commit -m "feat(code-apps): add standalone Advisor Cockpit B1 (US-301)" -- solution/apps/sales/code-apps/advisor-cockpit-b1 solution/apps/sales/package-lock.json
```

---

### Task 6: Build the Embedded B2 Code App

**Files:**

- Create: `solution/apps/sales/code-apps/advisor-cockpit-b2/**`
- Modify: `solution/apps/sales/package-lock.json`

- [ ] **Step 1: Scaffold an independent B2 identity**

```powershell
npx degit github:microsoft/PowerAppsCodeApps/templates/vite solution/apps/sales/code-apps/advisor-cockpit-b2
Push-Location solution/apps/sales/code-apps/advisor-cockpit-b2
npm pkg set name='@crmshow/advisor-cockpit-b2'
npm pkg set private=true --json
npm pkg set dependencies.'@crmshow/advisor-cockpit-domain'='0.1.0'
npm pkg set dependencies.'@crmshow/advisor-cockpit-ui'='0.1.0'
npm pkg set dependencies.react='^18.3.1'
npm pkg set dependencies.react-dom='^18.3.1'
npm pkg set devDependencies.'@types/react'='^18.3.3'
npm pkg set devDependencies.'@types/react-dom'='^18.3.0'
npm pkg set devDependencies.vitest='^4.1.10'
npm pkg set devDependencies.jsdom='^24.1.1'
npm pkg set devDependencies.'@testing-library/react'='^16.0.1'
npm pkg set devDependencies.'@testing-library/jest-dom'='^6.4.8'
npm pkg set scripts.test='vitest run'
Pop-Location
Push-Location solution/apps/sales
npm install
Pop-Location
```

Keep a distinct `power.config.json`, display name and generated directory. Pin
React 18.3.1 intentionally for the same parity reason as B1.

- [ ] **Step 2: Write failing B2 shell and message tests**

Create the same explicit `vitest.config.ts` and `src/test-setup.ts` content
shown in Task 5. The B2 test suite is independent and must not import B1 tests.
Assert host kind `embedded-code-app`. Test that navigation sends exactly:

```ts
{
  version: 1,
  type: 'crmshow.navigate',
  table: 'account',
  id: '11111111-1111-1111-1111-111111111111'
}
```

Assert unknown table names and non-GUID IDs are rejected before `postMessage`.
Run B2 tests and expect FAIL because the embedded adapter is absent.

- [ ] **Step 3: Add provider, context and exact-parent messaging**

Create B2's own pass-through provider:

```tsx
export function PowerProvider({ children }: React.PropsWithChildren): JSX.Element {
  return <>{children}</>;
}
```

Call `getContext()` in the B2 shell and map the returned app, user, environment,
session and locale values into the shared `RuntimeContext`. Derive the parent
target origin from `document.referrer`; require HTTPS and a
`.crm.dynamics.com` hostname. Send closed versioned messages only to that exact
origin, never `'*'`.

- [ ] **Step 4: Initialize B2 in DEV through an attended terminal**

```powershell
if (-not $env:POWER_PLATFORM_DEV_ENVIRONMENT_ID) { throw 'POWER_PLATFORM_DEV_ENVIRONMENT_ID is required.' }
pa auth status --json
Push-Location solution/apps/sales/code-apps/advisor-cockpit-b2
pa app init --display-name 'Advisor Cockpit - Embedded Proof' --environment-id $env:POWER_PLATFORM_DEV_ENVIRONMENT_ID --build-path dist
Pop-Location
```

- [ ] **Step 5: Generate the same existing Dataverse surfaces for B2**

```powershell
$tables = @(
  'account','contact','lead','appointment','task','systemuser','businessunit',
  'crmshow_leadcluster','crmshow_policyprojection','crmshow_claimprojection',
  'crmshow_nextbestaction','crmshow_nbaprovenance','crmshow_measuresnapshot'
)
Push-Location solution/apps/sales/code-apps/advisor-cockpit-b2
foreach ($table in $tables) {
  pa app add data-source --connector dataverse --table $table
  if ($LASTEXITCODE -ne 0) { throw "B2 data-source generation failed for $table." }
}
Pop-Location
```

Create B2-local `generatedBindings.ts`, `GeneratedCockpitGateway.ts`, and
`generatedGateway.test.ts` with the exact interfaces and assertions specified
in Task 5 Step 6, importing only B2's generated files. Normalize into the shared
canonical source-row types and call `mapCockpitRows`; do not import B1 source,
fixtures, or a copied domain mapper. Run the B2 gateway test RED before writing
the adapter, then GREEN after implementation. Repeat the generated-model
semantic-to-numeric NBA status mapping assertions independently in B2.

- [ ] **Step 6: Run B2 tests, build and authenticated local host**

```powershell
Push-Location solution/apps/sales
npm test --workspace @crmshow/advisor-cockpit-b2
npm run build --workspace @crmshow/advisor-cockpit-b2
Pop-Location
Push-Location solution/apps/sales/code-apps/advisor-cockpit-b2
pa app run
```

Open Local Play inside VS Code. This proves generated services and child-side
message validation only; record iframe/CSP/MDA behavior as unproven until Task 9.
Stop the server.

- [ ] **Step 7: Commit B2**

```powershell
git add solution/apps/sales/code-apps/advisor-cockpit-b2 solution/apps/sales/package-lock.json
git commit -m "feat(code-apps): add embedded Advisor Cockpit B2 shell (US-301)" -- solution/apps/sales/code-apps/advisor-cockpit-b2 solution/apps/sales/package-lock.json
```

---

### Task 7: Add the B2 MDA Sitemap Host and Environment Binding

**Files:**

- Create: `solution/apps/sales/code-app-host/advisor-cockpit-code-app-host.html`
- Create: `solution/apps/sales/code-app-host/advisor-cockpit-code-app-host.js`
- Create: `solution/schema/advisor-cockpit-code-app-host.json`
- Create: `scripts/solution/publish-advisor-cockpit-code-app-host.ps1`
- Create: `scripts/solution/Set-CodeAppsEnvironmentConfiguration.ps1`
- Create: `scripts/solution/tests/PublishAdvisorCockpitCodeAppHost.Tests.ps1`
- Create: `scripts/solution/tests/SetCodeAppsEnvironmentConfiguration.Tests.ps1`
- Modify: `solution/schema/advisor-cockpit-app.json`
- Modify: `scripts/solution/publish-advisor-cockpit-app.ps1`
- Modify: `scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1`

- [ ] **Step 1: Write failing host contract tests**

Assert the contract declares exactly these environment-variable schema names:

```text
crmshow_AdvisorCockpitB1PlayUrl
crmshow_AdvisorCockpitB2PlayUrl
crmshow_AdvisorCockpitB2AllowedOrigin
```

Assert the sitemap contains a `Beratercockpit (B2 Code App)` subarea whose URL
is `/WebResources/crmshow_advisorcockpitcodeapphost.html`. Assert the host source
contains no literal environment GUID, tenant URL, or wildcard `postMessage`.
Assert the configuration setter requires three HTTPS values, rejects a B2
allowed origin containing path/query content, updates only current-value rows,
redacts values from output, and honors `ShouldProcess`.

Run the two focused Pester files and expect FAIL.

- [ ] **Step 2: Write the host HTML and JavaScript**

The HTML contains a fixed-size responsive iframe, loading/error region and
script reference. The script must:

1. Use `parent.Xrm.WebApi.retrieveMultipleRecords` to resolve the B2 play URL
   and allowed child origin from environment-variable definition/value rows.
2. Require an HTTPS `https://apps.powerapps.com/play/` URL.
3. Append `hideNavBar=true` without discarding existing query parameters.
4. Set iframe `title="Advisor Cockpit"` and `allow="local-network-access"`
   only for local development; the deployed host omits device permissions.
5. Validate `event.origin` against `crmshow_AdvisorCockpitB2AllowedOrigin`.
6. Validate message version, type, table allowlist and GUID.
7. Call `parent.Xrm.Navigation.openForm({ entityName, entityId })`.
8. Render a visible configuration or navigation error without exposing data.

- [ ] **Step 3: Add idempotent web-resource publication**

`publish-advisor-cockpit-code-app-host.ps1` reads the two source files, inlines
the JavaScript into the HTML for one web-resource component, base64-encodes the
content, queries `webresourceset` by exact `name`, and POSTs or PATCHes as
required. It also reconciles the three environment-variable **definitions**
from the contract and adds the definitions plus web resource to
`crmshow_Sales`; it never writes an environment-specific value. All network
calls pass through one mockable function and honor `ShouldProcess`. Publish
changes only after every component is attached.

- [ ] **Step 4: Add environment-specific value reconciliation**

Create `Set-CodeAppsEnvironmentConfiguration.ps1` with mandatory
`EnvironmentUrl`, `B1PlayUrl`, `B2PlayUrl`, and `B2AllowedOrigin` parameters.
Require HTTPS; require each play URL to start with
`https://apps.powerapps.com/play/`; require `B2AllowedOrigin` to be a bare
origin. Query each definition by exact schema name, then POST or PATCH its
current-value row. Send requests through one injectable/mocked transport, honor
`ShouldProcess`, and output only schema names plus `Configured = $true`.

Run its focused Pester test RED before implementation and GREEN afterward.

- [ ] **Step 5: Extend the app contract without guessing custom-page types**

Extend sitemap subareas to support either `pageUniqueName` or `url`. Add
`WebResource = 61` to component types and resolve `webresourceid` by exact name.
Do not change the unresolved custom-page behavior. Add Pester coverage for URL
XML escaping, web-resource resolution, idempotent component attachment, and
missing-host failure.

- [ ] **Step 6: Run focused and full Pester suites**

```powershell
Invoke-Pester -Path @(
  'scripts/solution/tests/PublishAdvisorCockpitCodeAppHost.Tests.ps1',
  'scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1',
  'scripts/solution/tests/SetCodeAppsEnvironmentConfiguration.Tests.ps1'
) -Output Detailed
Invoke-Pester -Path scripts/solution/tests -Output Detailed
```

Expected: all tests pass without a live environment.

- [ ] **Step 7: Commit the B2 host**

```powershell
git add solution/apps/sales/code-app-host solution/schema/advisor-cockpit-code-app-host.json solution/schema/advisor-cockpit-app.json scripts/solution/publish-advisor-cockpit-code-app-host.ps1 scripts/solution/Set-CodeAppsEnvironmentConfiguration.ps1 scripts/solution/publish-advisor-cockpit-app.ps1 scripts/solution/tests/PublishAdvisorCockpitCodeAppHost.Tests.ps1 scripts/solution/tests/SetCodeAppsEnvironmentConfiguration.Tests.ps1 scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1
git commit -m "feat(sales): add environment-bound B2 sitemap host (US-301)" -- solution/apps/sales/code-app-host solution/schema/advisor-cockpit-code-app-host.json solution/schema/advisor-cockpit-app.json scripts/solution/publish-advisor-cockpit-code-app-host.ps1 scripts/solution/Set-CodeAppsEnvironmentConfiguration.ps1 scripts/solution/publish-advisor-cockpit-app.ps1 scripts/solution/tests/PublishAdvisorCockpitCodeAppHost.Tests.ps1 scripts/solution/tests/SetCodeAppsEnvironmentConfiguration.Tests.ps1 scripts/solution/tests/PublishAdvisorCockpitApp.Tests.ps1
```

---

### Task 8: Add CI and Release-Policy Gates

**Files:**

- Create: `scripts/solution/Test-CodeAppsRelease.ps1`
- Create: `scripts/solution/tests/Test-CodeAppsRelease.Tests.ps1`
- Modify: `.github/workflows/ci-solution.yml`
- Modify: `solution/apps/sales/package.json`
- Modify: `solution/apps/sales/package-lock.json`

- [ ] **Step 1: Write failing release-policy tests**

The pure evaluator accepts an injected file map and fails when:

- B1/B2 custom source imports `fixtures` or `data/scenarios`.
- custom TS/HTML contains `.crm.dynamics.com` or a literal
  `apps.powerapps.com/play/e/` URL.
- B1/B2 lacks `power.config.json`.
- either app omits `@microsoft/power-apps-vite`.
- the B2 host uses wildcard `postMessage` or accepts an unlisted table.

Run the test and expect RED before the evaluator exists.

- [ ] **Step 2: Implement `Test-CodeAppsRelease.ps1`**

Return a structured object with `Overall` and checks named
`NoFixtureFallback`, `NoEnvironmentUrls`, `PowerConfigPresent`,
`PowerAppsPluginPresent`, and `B2MessageBoundary`. The live script exits nonzero
when `Overall` is false and prints relative paths only.

- [ ] **Step 3: Add workspace quality scripts**

At the Sales workspace root add:

```json
{
  "scripts": {
    "test:visual": "playwright test tests/visual/advisor-cockpit-parity.spec.ts",
    "test:a11y": "vitest run --testNamePattern accessibility",
    "release:check": "pwsh ../../../scripts/solution/Test-CodeAppsRelease.ps1 -Root ."
  }
}
```

Add `vitest-axe` to the harness dev dependencies and tests for no critical axe
violations, keyboard focus return, and 320px reflow.

- [ ] **Step 4: Extend CI with one deterministic workspace step**

After Pester and before solution packing, add:

```yaml
      - name: Build and test Sales Code Apps workspace
        shell: pwsh
        run: |
          $node = [version]((node --version).TrimStart('v'))
          if ($node -lt [version]'20.19.0') { throw "Node 20.19+ required; found $node" }
          Push-Location solution/apps/sales
          npm ci
          npm test
          npm run build
          npx playwright install --with-deps chromium
          npm run test:visual
          npm run release:check
          Pop-Location
```

Update workflow path filters to include the new workspace, governance
instruction, and Code App scripts/tests. Do not add cloud credentials to CI.

- [ ] **Step 5: Run the full local gate**

```powershell
Push-Location solution/apps/sales
npm ci
npm test
npm run build
npm run test:visual
npm run release:check
Pop-Location
Invoke-Pester -Path scripts/solution/tests -Output Detailed
```

Expected: all commands exit 0.

- [ ] **Step 6: Commit quality gates**

```powershell
git add scripts/solution/Test-CodeAppsRelease.ps1 scripts/solution/tests/Test-CodeAppsRelease.Tests.ps1 .github/workflows/ci-solution.yml solution/apps/sales/package.json solution/apps/sales/package-lock.json solution/apps/sales/Controls/AdvisorCockpit/src/AdvisorCockpit.test.tsx
git commit -m "ci(code-apps): gate builds parity accessibility and release safety (US-301)" -- scripts/solution/Test-CodeAppsRelease.ps1 scripts/solution/tests/Test-CodeAppsRelease.Tests.ps1 .github/workflows/ci-solution.yml solution/apps/sales/package.json solution/apps/sales/package-lock.json solution/apps/sales/Controls/AdvisorCockpit/src/AdvisorCockpit.test.tsx
```

---

### Task 9: Publish and Prove B1/B2 in DEV

**Files:**

- Create: `scripts/solution/Publish-CodeAppsDev.ps1`
- Create: `scripts/solution/tests/Publish-CodeAppsDev.Tests.ps1`
- Create: `docs/runbooks/publish-code-apps-dev.md`
- Modify: `.github/workflows/cd-solution-dev.yml`
- Modify: `docs/superpowers/sprints/sprint-005-code-app-parity/STATUS.md`

- [ ] **Step 1: Write failing wrapper tests**

Mock all process execution. Assert the wrapper:

- refuses missing environment/solution GUIDs;
- checks `pa auth status --json` before build/push;
- runs B1 then B2 builds and `pa app push --solution-id`;
- never sets `PA_CLI_USE_SP_AUTH`, `SP_CLIENT_SECRET`, or calls TEST;
- writes evidence containing commit SHA, CLI version, app name, timestamp and
  exit code, but no token or credential.

Run focused Pester and expect RED.

- [ ] **Step 2: Implement the attended DEV wrapper**

Parameters are `EnvironmentId`, `SolutionId`, and `EvidencePath`, each required.
Validate GUIDs. Require an interactive active account returned by `pa auth
status --json`. Build and push each app sequentially, stop on first failure,
and write BOM-free UTF-8 evidence JSON.

- [ ] **Step 3: Write the attended runbook**

The runbook includes:

```powershell
pa auth login
pa auth status --json
./scripts/solution/Publish-CodeAppsDev.ps1 `
  -EnvironmentId $env:POWER_PLATFORM_DEV_ENVIRONMENT_ID `
  -SolutionId $env:CRM_SHOWCASE_SALES_SOLUTION_ID `
  -EvidencePath ./artifacts/code-apps-dev-publish.json
```

Then instruct the maker to:

1. Share play access for B1/B2 with the advisor user.
2. Sign in with `az login --allow-no-subscriptions` and run:

  ```powershell
  ./scripts/solution/Set-CodeAppsEnvironmentConfiguration.ps1 `
    -EnvironmentUrl $env:POWER_PLATFORM_DEV_ENV_URL `
    -B1PlayUrl $env:ADVISOR_COCKPIT_B1_PLAY_URL `
    -B2PlayUrl $env:ADVISOR_COCKPIT_B2_PLAY_URL `
    -B2AllowedOrigin $env:ADVISOR_COCKPIT_B2_ALLOWED_ORIGIN `
    -Confirm:$false
  ```

  Store those values in the local shell or approved operator configuration;
  do not commit them.
3. Publish the B2 web resource and app contract through the DEV authoring step.
4. Configure Code Apps CSP `frame-ancestors` with the exact DEV Dynamics origin.
5. Wait for propagation and verify the browser console has no CSP violation.

- [ ] **Step 4: Add DEV authoring after attended app publication**

The CD-DEV workflow must not run `pa app push`. It may publish the source-driven
B2 host, reconcile the MDA sitemap, and export the solution only after a
preflight proves both Code Apps and environment variables exist in DEV. Add a
clear failure that points to the attended runbook when preflight is missing.

- [ ] **Step 5: Run offline tests**

```powershell
Invoke-Pester -Path scripts/solution/tests/Publish-CodeAppsDev.Tests.ps1 -Output Detailed
Invoke-Pester -Path scripts/solution/tests -Output Detailed
```

Expected: all tests pass.

- [ ] **Step 6: Execute the attended DEV publication**

Run the runbook as maker/admin. Do not transmit credentials through chat.
Record sanitized evidence and app IDs in the Sprint 005 issue/STATUS; do not
commit tenant IDs or full play URLs.

- [ ] **Step 7: Run least-privilege DEV journeys**

As the advisor user, run B1 and B2 with the same synthetic seed:

- all tabs/views/filters/dialogs;
- normal/grey/yellow provenance and accessible legend;
- NBA supported update followed by reread;
- every blocked action disabled with the matrix reason;
- B1 native record deep link;
- B2 sitemap, iframe, CSP, message validation and native navigation;
- screenshot, session ID, browser timing, Power Platform Monitor evidence.

Record failures as `Concern` or `Blocker`; do not change host UX without
returning to attended design review.

- [ ] **Step 8: Commit source/runbook changes and DEV evidence references**

```powershell
git add scripts/solution/Publish-CodeAppsDev.ps1 scripts/solution/tests/Publish-CodeAppsDev.Tests.ps1 docs/runbooks/publish-code-apps-dev.md .github/workflows/cd-solution-dev.yml docs/superpowers/sprints/sprint-005-code-app-parity/STATUS.md
git commit -m "feat(code-apps): add attended DEV publication and proof gate (US-301)" -- scripts/solution/Publish-CodeAppsDev.ps1 scripts/solution/tests/Publish-CodeAppsDev.Tests.ps1 docs/runbooks/publish-code-apps-dev.md .github/workflows/cd-solution-dev.yml docs/superpowers/sprints/sprint-005-code-app-parity/STATUS.md
```

---

### Task 10: Promote and Prove the Managed Apps in TEST

**Files:**

- Create: `scripts/solution/Get-CodeAppsPromotionFacts.ps1`
- Create: `scripts/solution/tests/Get-CodeAppsPromotionFacts.Tests.ps1`
- Modify: `scripts/solution/Get-PromotionSmokeResult.ps1`
- Modify: `scripts/solution/tests/Get-PromotionSmokeResult.Tests.ps1`
- Modify: `.github/workflows/cd-solution-test.yml`
- Modify: `docs/superpowers/sprints/sprint-005-code-app-parity/STATUS.md`

- [ ] **Step 1: Write failing promotion-fact tests**

Given mocked Dataverse responses, assert the gatherer returns:

```powershell
[pscustomobject]@{
    CodeApps = @('Advisor Cockpit - Standalone Proof','Advisor Cockpit - Embedded Proof')
    WebResources = @('crmshow_advisorcockpitcodeapphost.html')
    EnvironmentVariables = @(
        'crmshow_AdvisorCockpitB1PlayUrl',
        'crmshow_AdvisorCockpitB2PlayUrl',
        'crmshow_AdvisorCockpitB2AllowedOrigin'
    )
    ContainsDevUrl = $false
}
```

Extend smoke-result tests so missing app, host, variable, managed Sales solution,
or a DEV URL makes `Overall` false.

- [ ] **Step 2: Implement fact gathering and pure smoke checks**

Use OIDC-authenticated `az rest` only to query app, web-resource,
environment-variable and solution facts. Redact values from output; report
only names and boolean checks. Keep the evaluator transport-free and fully
unit-tested.

- [ ] **Step 3: Complete TEST workflow steps**

After managed import:

1. Read `ADVISOR_COCKPIT_B1_PLAY_URL`, `ADVISOR_COCKPIT_B2_PLAY_URL`, and
  `ADVISOR_COCKPIT_B2_ALLOWED_ORIGIN` from TEST GitHub Environment **variables**
  and call `Set-CodeAppsEnvironmentConfiguration.ps1`. Fail before smoke when
  any value is absent; never echo values.
2. Seed the synthetic Advisor Cockpit scenario with the existing idempotent
   script.
3. Gather facts and run `Get-PromotionSmokeResult` with expected Foundation,
   DataModel, Integration and Sales solutions.
4. Fail on missing B1/B2, host, variables, unmanaged Sales, or DEV URL.
5. Upload a redacted smoke JSON artifact.

The workflow does not run `pa app push` and does not store user credentials.

- [ ] **Step 4: Run offline promotion tests**

```powershell
Invoke-Pester -Path @(
  'scripts/solution/tests/Get-CodeAppsPromotionFacts.Tests.ps1',
  'scripts/solution/tests/Get-PromotionSmokeResult.Tests.ps1'
) -Output Detailed
```

Expected: all tests pass.

- [ ] **Step 5: Dispatch managed TEST promotion**

Dispatch `cd-solution-test.yml`, approve the TEST environment, and verify the
exact `crmshow_Sales` artifact exported from DEV is imported. Apply TEST app
sharing and exact TEST CSP as attended environment configuration; do not author
app code directly in TEST.

- [ ] **Step 6: Run least-privilege TEST journeys**

Repeat the DEV B1/B2 script unchanged as the TEST advisor. Capture pipeline URL,
step table, test counts, screenshots, session IDs, timings, Monitor evidence,
supported write+reread, blocked actions, and defects fixed.

- [ ] **Step 7: Demonstrate rollback**

Reinstall the prior managed `crmshow_Sales` version and restore prior sitemap
and environment configuration. Verify proof entries are absent/reverted. Then
reinstall the candidate managed package and rerun smoke. Do not claim the
deployed PCF as a fallback.

- [ ] **Step 8: Commit TEST pipeline and evidence references**

```powershell
git add scripts/solution/Get-CodeAppsPromotionFacts.ps1 scripts/solution/tests/Get-CodeAppsPromotionFacts.Tests.ps1 scripts/solution/Get-PromotionSmokeResult.ps1 scripts/solution/tests/Get-PromotionSmokeResult.Tests.ps1 .github/workflows/cd-solution-test.yml docs/superpowers/sprints/sprint-005-code-app-parity/STATUS.md
git commit -m "ci(code-apps): prove managed B1 and B2 in TEST (US-301)" -- scripts/solution/Get-CodeAppsPromotionFacts.ps1 scripts/solution/tests/Get-CodeAppsPromotionFacts.Tests.ps1 scripts/solution/Get-PromotionSmokeResult.ps1 scripts/solution/tests/Get-PromotionSmokeResult.Tests.ps1 .github/workflows/cd-solution-test.yml docs/superpowers/sprints/sprint-005-code-app-parity/STATUS.md
```

---

### Task 11: Produce the Comparative Recommendation and Close the Sprint

**Files:**

- Create: `docs/testing/US-301-code-app-host-parity.md`
- Modify: `docs/adr/ADR-0033-crm-ux-placement-in-b2e-landscape.md`
- Modify: `docs/superpowers/sprints/sprint-005-code-app-parity/STATUS.md`
- Modify: `docs/superpowers/sprints/README.md`

- [ ] **Step 1: Write the evidence scorecard**

For B1 and B2, record `Pass`, `Concern`, `Blocker`, or `Not applicable`, an
evidence link, and a concise finding for:

- visual/functional parity;
- advisor workflow/navigation;
- responsive behavior/accessibility;
- load/interaction performance;
- identity/sharing/least privilege;
- CSP/embedding complexity;
- ALM/configuration/rollback;
- failure visibility/resilience;
- Monitor supportability;
- developer polish speed;
- maintenance/controlled divergence;
- licensing/platform constraints.

Do not calculate a weighted winner.

- [ ] **Step 2: Reconcile the write-capability matrix with live evidence**

Every visible command receives final B1/B2 status, exact limitation, runtime
treatment, evidence, and a named follow-up requirement. Verify no disabled
command reported success and no missing write was silently dropped.

- [ ] **Step 3: Add evidence to ADR-0033 without selecting an option**

Append the DEV/TEST proof links, scorecard link, recommendation, remaining
blockers, and decision-owner review trigger. Keep ADR-0033 unselected until a
separate human approval explicitly chooses B1 or B2.

- [ ] **Step 4: Close Sprint 005 evidence**

`STATUS.md` must include:

- green DEV pipeline URL and offline test counts;
- TEST promotion URL and per-step result table;
- B1/B2 advisor journey results;
- defects found/fixed;
- rollback proof;
- unresolved concerns/blockers;
- explicit statement that the PCF local harness was the visual baseline and
  the deployed PCF was not a user-visible comparator or fallback.

- [ ] **Step 5: Run final repository validation**

```powershell
Push-Location solution/apps/sales
npm ci
npm test
npm run build
npm run test:visual
npm run release:check
Pop-Location
Invoke-Pester -Path scripts/solution/tests -Output Detailed
Invoke-Pester -Path scripts/orchestration/tests -Output Detailed
git diff --check
```

Expected: every command exits 0.

- [ ] **Step 6: Commit the recommendation package**

```powershell
git add docs/testing/US-301-code-app-host-parity.md docs/adr/ADR-0033-crm-ux-placement-in-b2e-landscape.md docs/superpowers/sprints/sprint-005-code-app-parity/STATUS.md docs/superpowers/sprints/README.md
git commit -m "docs(code-apps): recommend Advisor Cockpit host from live evidence (US-301)" -- docs/testing/US-301-code-app-host-parity.md docs/adr/ADR-0033-crm-ux-placement-in-b2e-landscape.md docs/superpowers/sprints/sprint-005-code-app-parity/STATUS.md docs/superpowers/sprints/README.md
```

The named human then reviews the recommendation. Selecting B1/B2 and retiring
or repurposing the PCF artifact requires a separate ADR decision and is not part
of this implementation plan.

---

## Final Definition of Done

- ADR-0041 and the Code App local-first pattern are accepted and enforced.
- Shared domain/UI packages build once and feed the harness, PCF artifact, B1
  and B2 without copied business rules.
- The approved local fixture harness is the visual baseline.
- B1 and B2 have separate identities, generated services and host adapters.
- Provenance and error states remain honest and accessible.
- Every visible write is implemented or visibly disabled and documented.
- No B2E, Azure, schema extension, raw Web API, custom API, flow, secret-based
  CI, DEV URL literal, or deployed fixture fallback is introduced.
- B1 and B2 pass least-privilege journeys in DEV and TEST.
- Managed promotion and previous-version rollback are demonstrated.
- The scorecard makes an evidence-backed recommendation without automatically
  choosing a winner.
