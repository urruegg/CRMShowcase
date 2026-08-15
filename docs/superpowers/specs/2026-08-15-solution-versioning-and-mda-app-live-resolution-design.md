# Solution versioning sync + Advisor Cockpit app live-authoring resolution

| Field | Value |
| --- | --- |
| **Status** | Draft — brainstormed live with the repo owner (real-time Q&A, not autonomous). Scope confirmed: both parts, in one pass. Owner confirmed comfortable with live CD-DEV dispatches as part of resolving this. |
| **Date** | 2026-08-15 |
| **Deciders** | Repo owner |
| **Related** | [2026-08-15-advisor-cockpit-mda-app-design.md](./2026-08-15-advisor-cockpit-mda-app-design.md) (open question #3 already flagged the `clienttype`/`formfactor` research gap resolved here) · [2026-08-15-advisor-cockpit-mda-app.md](../plans/2026-08-15-advisor-cockpit-mda-app.md) (implementation plan, Task 1) · [sprint-003 charter](../sprints/sprint-003-advisor-cockpit/sprint.md) (stream `mda-app`, issue #64) · [ADR-0017](../../adr/ADR-0017-alm-everything-through-the-pipeline.md) |
| **Licence** | 🧩 configuration / own build |
| **Upgrade impact** | Additive — a new version-sync step + a contract data fix. No existing schema or component is renamed/removed. |
| **Maturity** | Design only. No code changes in this document. |

## Why this document exists

The owner opened the DEV environment's Power Apps page and did not see the
Advisor Cockpit app — despite PR #110 (the full 10-task MDA app publisher
implementation) having merged to `main` earlier the same day. Asked to check
the evidence and plan the resolution end to end.

Investigation surfaced two distinct, confirmed problems — one explains the
immediate symptom, the other is a separate, systemic gap the owner flagged as
**critical** once found.

## Evidence (gathered empirically, not inferred)

### (A) Why the app isn't there

- `gh run list --workflow cd-solution-dev.yml`: the most recent run is
  `31805085480`, dated **2026-08-14** — before PR #110 merged
  (**2026-08-15**). The pipeline has not run since the new "Publish Advisor
  Cockpit app" step was added.
- `pac solution export --name crmshow_Sales` (live DEV, `pac` auth confirmed
  working via `pac org who` — this environment is `36c1c7c2-e090-e6a4-96e1-dd02ae894e0e`
  / `crmshowdev.crm.dynamics.com`, the same one the owner linked): the
  exported `customizations.xml` is completely empty — `<Entities></Entities>`,
  no `AppModules` node at all.
- **Conclusion: not a bug.** The code is correct and merged; it has simply
  never been executed against DEV.

### (B) Solution versions never reach Dataverse (owner: "this is critical")

- `solution/manifest.json` declares `crmshow_Foundation` 1.1.0.0,
  `crmshow_DataModel` 1.2.0.0, `crmshow_Sales` 1.1.0.0.
- `pac solution list` (live DEV) shows **all three still at 1.0.0.0** —
  confirmed independently via the exported `crmshow_Sales/solution.xml`'s
  `<Version>1.0.0.0</Version>`.
- `scripts/solution/Bump-Version.ps1` exists, has correct semver math, has
  its own passing Pester suite — but a repo-wide grep shows it is **only
  ever referenced by its own test file**. Neither `Publish-InsuranceFoundation.ps1`
  nor `Export-InsuranceFoundationPackages.ps1` nor any GitHub Actions
  workflow calls it, or touches a live solution's `version` attribute at all.
- `solution/manifest.json`'s own `"versioning"` section already documents
  the intended scheme: `"BUILD": "GitHub Actions run number
  ($env:GITHUB_RUN_NUMBER); source of uniqueness"` — i.e. this was already
  designed, just never wired into the pipeline.

### A key unlock discovered while reasoning through the fix

My **local** `az` CLI session has been broken all sprint (documented
blocker on Task 1 of the MDA app plan). But CD-DEV's `author` job
authenticates via a **completely different mechanism** — GitHub Actions OIDC
via `azure/login` — which has been working reliably all sprint (it is what
successfully authored tables, choices, and seed data live). **Task 1's
remaining research does not require fixing my local `az` at all** — it can
be resolved by a live CD-DEV-context query instead.

### Also discovered: one of Task 1's two placeholders was never a real blocker

The final code review of PR #110 already found that
`ConvertTo-ComponentTypeValue` / `$script:ComponentTypeValues` (which holds
the `CustomPage = -1` placeholder) is **dead code** — the real orchestrator
resolves component attachment via `Get-ComponentODataEntity`, which maps
`CustomPage` to an `@odata.type` string (`Microsoft.Dynamics.CRM.canvasapp`),
never a numeric `componenttype`. So the **only** genuine remaining blocker
for `Invoke-AdvisorCockpitAppPublish` to run without throwing is
`appModule.clientType` / `appModule.formFactor` in
`solution/schema/advisor-cockpit-app.json`.

## Part B — Solution versioning sync

### Approaches considered

**Approach B1 — New standalone script, wired near the end of `cd-solution-dev.yml`'s `author` job (recommended)**

A new `scripts/solution/Set-SolutionVersions.ps1`:

1. Loads `solution/manifest.json` via the existing `Get-Manifest` function
   (already validates shape/version format — no new parsing logic needed).
2. For each declared solution: `GET /solutions?$select=solutionid,version&$filter=uniquename eq '<name>'`.
3. Computes the target version via the existing `Bump-Version -Current <manifest version> -Kind build -Build $env:GITHUB_RUN_NUMBER` (keeps the PR author's declared MAJOR.MINOR.PATCH, stamps BUILD with the real CI run number — exactly what the manifest's own schema already documents as intended).
4. `PATCH /solutions(id)` with the new version **only if it differs** from
   the live value (idempotent, safe to run every time).
5. Runs for **all 6 solutions** in the manifest, not just Sales — this is a
   repo-wide gap, not an Advisor-Cockpit-specific one.

Wired as a new step **right before** "Export managed and unmanaged
solutions" — so it only fires once all authoring steps in that run have
already succeeded (a version bump should mean "this run's changes are
confirmed live", not "we attempted to apply changes"), and the exported
package picks up the correct, current version.

Testable offline via Pester using this repo's own established one-wrapper-
function mocking pattern (a new, small `Invoke-DataverseRequest`-style
wrapper local to this script, mocked in tests the same way
`Publish-InsuranceFoundation.Tests.ps1` and `PublishAdvisorCockpitApp.Tests.ps1`
already do).

**Approach B2 — Fold version-sync into `Publish-InsuranceFoundation.ps1`**

Trade-off: reuses that script's existing `Invoke-DataverseRequest` wrapper
directly (no new wrapper needed) — but that script is scoped to the
Foundation/DataModel domain (owner `AG-E-08`); versions for `Sales`/
`Service`/`Marketing`/`Integration` (owned by `AG-E-01`/`AG-E-09`) don't
naturally belong there. Would create an awkward cross-domain dependency.
**Not recommended** for that reason.

**Approach B3 — Stamp version only at export/package time, not authoring time**

Post-process the exported zip's `solution.xml` during
"Export managed and unmanaged solutions" instead of PATCHing the live
solution first. Trade-off: fixes what the *exported artifact* claims, but
**doesn't fix what the owner is actually looking at** — the live Maker
Portal / `pac solution list` would still show 1.0.0.0. Given the concern is
specifically about not being able to trust what's live, this alone doesn't
address it. **Not recommended as the primary fix**, though it's worth
confirming B1's live version bump is also reflected in exports (it will be,
since export happens after B1's step in the same job).

### Recommendation

**B1.** Small, standalone, reuses two already-correct-and-tested building
blocks (`Get-Manifest`, `Bump-Version`) that were simply never connected to
anything, fixes the problem where the owner is actually looking (live
Dataverse), and follows this repo's own established wrapper-function testing
pattern.

## Part A — Getting the Advisor Cockpit app live

### Approaches considered

**Approach A1 — Throwaway diagnostic dispatch, never merged (recommended)**

A minimal workflow file on a throwaway branch (copy the `author` job's
existing auth steps — `azure/login` + Power Platform CLI — from
`cd-solution-dev.yml`, replace the actual authoring steps with 1-2 read-only
`az rest` GETs against an existing app module, e.g. the native Sales Hub,
for real `clienttype`/`formfactor` values). Dispatch once via
`gh workflow run --ref <throwaway-branch>`, read the values from the job
log, then discard the branch entirely. Zero permanent footprint in `main`.
Mirrors this repo's own established practice of using throwaway,
never-committed scripts for one-off empirical verification.

**Approach A2 — Small, permanent diagnostic step**

Same queries, but committed as a reusable (always-available, manually
invoked) diagnostic step/script. Trade-off: slightly more permanent surface
area for a one-time need; **not recommended** unless we expect to need this
kind of live introspection again soon.

**Approach A3 — Ask the owner to check Maker Portal UI manually**

Since the owner already has the Apps page open, they could open an existing
app (Sales Hub) and read its Client Type / Form Factor from the UI
directly. Trade-off: zero engineering effort, but relies on the owner's own
time and the UI may not expose the raw numeric values as cleanly as the Web
API does. Offered as a fallback if A1 hits an unexpected snag.

### Recommendation

**A1**, with A3 as a fallback if the throwaway-dispatch approach runs into
trouble. **Superseded in practice:** the owner manually created the app
module directly (browser-shared session), giving real `clientType=4`/
`formFactor=1` values without needing either A1 or A3 — see the Update log
at the bottom of this document.

### Addendum — code-based Custom Pages (captured evidence, not yet actioned)

While verifying the custom page for this app, the owner used the "Describe
your page" AI-assisted flow, which produced a genuine, readable React
functional component (not a black-box artifact) using
`@fluentui/react-components` — the same Fluent v9 library this repo's PCF
controls already use — plus `Xrm.Utility.getGlobalContext()` and a
`dataApi.retrieveRow(...)` call. Captured verbatim at
[2026-08-15-generative-custom-page-captured-source.tsx](./2026-08-15-generative-custom-page-captured-source.tsx)
as primary evidence for a **separate, later-stage research question**: can a
Custom Page's content be authored/deployed as source (via GitHub Copilot,
outside the browser Studio), rather than only assembled through the Insert-
component picker? **Not yet verified** whether the "Code" tab is a two-way
editable/exportable format or a read-only generated preview. Explicitly
**not** pursued as part of closing out #64 — brainstormed and deliberately
deferred as its own future spike, since #64's own path (embedding the
already-built PCF control via the GA "Code components in custom pages"
mechanism) is proven and nearly complete.

### End-to-end sequence

1. Implement + Pester-test Part B (`Set-SolutionVersions.ps1` + wiring).
2. Dispatch the A1 throwaway diagnostic workflow; read confirmed
   `clientType`/`formFactor` values from the job log.
3. Update `solution/schema/advisor-cockpit-app.json`, replacing both
   `"<CONFIRM-IN-TASK-1>"` placeholders with the confirmed values.
4. Remove the now-confirmed-dead `ConvertTo-ComponentTypeValue` /
   `$script:ComponentTypeValues` (`CustomPage = -1`) code and its two tests
   from `publish-advisor-cockpit-app.ps1` — closes that follow-up from
   PR #110's final review cleanly, since it's confirmed unreachable from the
   real orchestrator path.
5. Commit both fixes together (or as two small PRs — TBD in the
   implementation plan), open PR(s), merge after review (never self-merge).
6. Dispatch `cd-solution-dev.yml` against DEV for real.
   - **If the 2 custom pages don't exist yet**: the run fails cleanly inside
     `Get-CustomPageIdMap`, naming exactly which page is missing — this is
     the one already-known, unavoidable manual step (Maker Portal has no
     Web API/CLI path for canvas-page content). Owner creates them, then we
     dispatch again.
   - **If they already exist**: the app should be authored, versions synced,
     done.
7. Verify via a fresh `pac solution export` (or the Maker Portal Apps page
   directly) that the app now appears and all 6 solution versions match
   their manifest-declared values (build-stamped).

## Non-negotiables carried into implementation

- Never self-merge; `gate1` CI + human review, per the Sprint Operating
  Model.
- The throwaway diagnostic workflow (A1) is read-only (GET only) and is
  never merged to `main`.
- No number gets invented — `clientType`/`formFactor` come from a live,
  confirmed query, not a guess; if the diagnostic query is inconclusive,
  fall back to A3 (ask the owner) rather than guessing.
- Version-sync (B1) never *decreases* a live version — the manifest is
  always treated as the source of truth going forward for MAJOR.MINOR.PATCH.

## Open questions

1. **Does Part B need its own tracking issue?** It's a repo-wide ALM gap
   discovered while investigating #64, not originally scoped to any
   existing issue. Recommend opening a new issue (e.g. "Solution versions
   never sync to live Dataverse") once this design is approved, rather than
   overloading #64 with unrelated scope.
2. **Should B1's version-sync step run unconditionally every CD-DEV run, or
   only when something changed?** Recommendation in this doc is
   unconditional (idempotent PATCH, no change-detection complexity) — flag
   if a lighter-touch approach is preferred.

## Definition of done for this design (not the implementation)

- [x] Evidence gathered empirically (GitHub Actions run history, live
      solution export, repo-wide grep for version-sync logic).
- [x] Two problems clearly separated, scope confirmed live with the owner
      ("both, in one pass").
- [x] Live-dispatch comfort confirmed live with the owner ("yes please").
- [x] Proposed approaches with trade-offs and a recommendation for both
      parts.
- [x] Key blocker re-assessed (`CustomPage` placeholder confirmed dead code,
      not a real blocker) rather than left stale.
- [ ] **Owner review of this document** — required before invoking
      `writing-plans`, per the brainstorming skill's hard gate.
