# Advisor Cockpit — MDA app + custom pages authoring (#64)

| Field | Value |
| --- | --- |
| **Status** | Draft — produced autonomously via the `brainstorming` skill (user unavailable to answer clarifying questions live; see "Open questions"). Not yet implemented — implementation requires review per the skill's hard gate. |
| **Date** | 2026-08-15 |
| **Deciders** | Repo owner (async review pending) |
| **Related** | [2026-08-11-advisor-cockpit-design.md](./2026-08-11-advisor-cockpit-design.md) · [sprint-003 charter](../sprints/sprint-003-advisor-cockpit/sprint.md) (stream `mda-app`, issue #64) · [SPRINT-OPERATING-MODEL.md](../SPRINT-OPERATING-MODEL.md) · [ADR-0017](../../adr/ADR-0017-alm-everything-through-the-pipeline.md) |
| **Licence** | 🧩 configuration / own build |
| **Upgrade impact** | Additive — a new app module + sitemap + component associations; no existing component is changed |
| **Maturity** | Design only. No code changes in this document. |

## Why this document exists

Stream `mda-app` (#64) is the last piece of Sprint 3 that turns the two
already-merged, already-build-verified PCF controls
(`AdvisorCockpit`, `SalesLeaderDashboard` — PRs #70/#74, wrapped as real PCF
projects) into something a user can actually open: a Model-Driven App named
"Advisor Cockpit" with a sitemap and two custom pages hosting the controls.

This has been deferred all sprint for a concrete reason, not procrastination:
two earlier attempts to fetch the exact Web API contract for `appmodule`/
`sitemap` from Microsoft Learn **404'd**, and guessing at a live-mutating
Dataverse operation with an uncertain contract was judged too risky —
consistent with this repo's own caution around unverified live changes.

**This time the fetches succeeded** (the earlier 404s appear to have been
transient — the same class of URL resolved cleanly today), so this document
is grounded in the actual Dataverse Web API schema, not guesswork. One piece
remains genuinely uncertain (custom-page component registration — see "Open
questions") and is flagged rather than assumed.

## What's now confirmed (Microsoft Learn, fetched 2026-08-15)

### `appmodule` (Model-driven App)

- `EntitySetName: appmodules`, `POST /appmodules` to create, `PATCH /appmodules(id)` to update/upsert.
- Key writable columns: `name` (localizable), `uniquename`, `description`,
  `webresourceid` (icon), `url`, `clienttype` (Integer, `ApplicationRequired`,
  1–31), `formfactor` (Integer, `ApplicationRequired`, 1–8), `navigationtype`
  (Picklist: `0` Single session / `1` Multi session), `isdefault`,
  `isfeatured`, `publisherid` (Lookup → `publisher`, required),
  `welcomepageid`.
- `ValidateApp` message exists — a business app must be validated (and
  published) before it's usable; this is a Web API action, not just a
  `PublishAllXml`.
- `appmoduleroles_association` (many-to-many with `role`) controls which
  security roles can see the app in the app picker.

### `sitemap` (Site Map)

- `EntitySetName: sitemaps`, `POST /sitemaps` / `PATCH /sitemaps(id)`.
- Key writable columns: `sitemapname`, `sitemapnameunique`, `sitemapxml` (the
  actual navigation XML — areas/groups/subareas), `isappaware`, `showhome`,
  `showpinned`, `showrecents`, `enablecollapsiblegroups`.
- **No direct lookup from `sitemap` to `appmodule`** — the two are linked via
  `appmodulecomponent`, not a foreign key on either table.

### `appmodulecomponent` (how components attach to an app)

- `EntitySetName: appmodulecomponents`. Links `appmoduleidunique` (Lookup →
  `appmodule`) to `objectid` (the component's own GUID) via a `componenttype`
  picklist.
- **Confirmed `componenttype` values:** `1` Entities · `26` Views · `29`
  Business Process Flows · `48` Command (Ribbon) · `59` Charts · `60` Forms ·
  `62` **Sitemap**. (This list may not be exhaustive — see "Open questions.")
- `rootcomponentbehavior` (`0` Include Subcomponents / `1` Do not include
  subcomponents / `2` Include As Shell Only) controls whether adding e.g. an
  entity also pulls in its forms/views automatically.

### `AddAppComponents` action (the intended way to attach components)

- `POST /AddAppComponents` with body `{ "AppId": "<appmodule guid>",
  "Components": [ {"@odata.type": "Microsoft.Dynamics.CRM.sitemap",
  "sitemapid": "<guid>"}, ... ] }` — a single call that adds one or more
  components (sitemap, entities, views, forms, etc.) to an app module,
  rather than hand-crafting each `appmodulecomponent` row directly.

## Three approaches considered

### Approach A — Fully scripted, one deliberate manual step for custom-page content (recommended)

Custom pages are created **once, interactively, in the Maker Portal** (their
canvas layout/PCF-hosting content has no Web API/CLI authoring path — already
confirmed this sprint, and nothing in today's research contradicts that).
Everything else is scripted in this repo's existing style
(`Publish-InsuranceFoundation.ps1`-equivalent PowerShell + `az rest`, an
idempotent reconciliation function per component, its own Pester suite):

1. Author the sitemap (`sitemapxml` referencing the 2 custom pages + any
   native entities/dashboards the app needs) via `PATCH /sitemaps(key)`.
2. Author the app module (`name`, `uniquename`, `clienttype`, `formfactor`,
   `navigationtype`, `publisherid`) via `PATCH /appmodules(key)`.
3. Attach the sitemap + the 2 (already-existing, Maker-Portal-created)
   custom pages + any native entities to the app module via
   `POST /AddAppComponents`.
4. Assign the app to the appropriate security role(s) via
   `appmoduleroles_association`.
5. `ValidateApp` then `PublishAllXml`.

**Why recommended:** matches ADR-0017 ("everything reaches an environment
through the pipeline") and this repo's own established pattern for every
other component so far (choices, tables, roles, views, forms) — the app
module/sitemap/security wiring is genuinely reconcilable and testable
offline with mocks, exactly like `Publish-InsuranceFoundation.ps1`. The one
manual step (custom-page creation) is a **one-time, already-identified,
unavoidable** limitation of the platform, not a workaround — and it only
needs to happen once per environment tier (DEV, then re-created once in
TEST, or promoted as a solution component like everything else).

### Approach B — Fully manual (Maker Portal only), no scripting

A human builds the whole app — sitemap, app module, custom pages, security —
interactively. The pipeline's only role becomes exporting/promoting the
resulting solution component, the same way it already handles anything a
human customizes directly today.

**Trade-off:** simplest and lowest technical risk, but it's a step backward
from this repo's own "everything through the pipeline" position for the
*parts that are genuinely scriptable* (sitemap XML, app module metadata,
component wiring, security-role assignment) — those would become invisible,
unreviewable manual changes exactly like ADR-0017 says not to allow.

### Approach C — Minimal placeholder skeleton now, defer real wiring

Script just enough to get an empty app module + sitemap into source control
and DEV-authored (to unblock CD-DEV convergence reporting), and leave actual
navigation/component wiring for a later pass.

**Trade-off:** fastest to land something, but produces an app that doesn't
actually work yet — a half-measure that risks being mistaken for "done" in
a status board, which this sprint has been careful to avoid (see the
DEV+TEST evidence policy anchored earlier today).

## Recommendation

**Approach A.** It is the only option consistent with this repo's own
established pattern and ADR-0017, isolates the one truly-unavoidable manual
step to exactly where the platform requires it, and produces a genuinely
working, testable, reconcilable app — not a placeholder.

## Proposed shape (pending approval — not yet built)

- New PowerShell script (or a new section of the existing publish script,
  TBD — see "Open questions") with functions mirroring the established
  pattern: `ConvertTo-SitemapUpsertBody`, `ConvertTo-AppModuleUpsertBody`,
  `Invoke-AppComponentReconciliation` (wraps `AddAppComponents`,
  idempotent — checks existing `appmodulecomponent` rows before adding
  duplicates), `Invoke-AppRoleAssociationReconciliation`.
- A new JSON contract section (either a new file, e.g.
  `solution/schema/advisor-cockpit-app.json`, or an addition to
  `insurance-foundation.json` — **TBD, flagged below**) declaring the
  sitemap XML structure, the app module's metadata, and which components
  attach to it — so this is versioned, PR-reviewed, and diffable like
  every other schema change in this repo.
- Pester tests mocking `az rest`/`AddAppComponents`, following the exact
  TDD pattern already used for `Publish-InsuranceFoundation.ps1`.
- A new CD-DEV pipeline step (after table/choice authoring, since the
  sitemap needs the custom pages — which need the PCF-hosting `AdvisorCockpit`/
  `SalesLeaderDashboard` controls — to already exist).

## Open questions (flagged for owner review, not guessed at)

1. **Custom-page component-type registration is not yet confirmed.** The
   `appmodulecomponent.componenttype` values found today (`1/26/29/48/59/60/62`)
   do not include an obvious "Custom Page" or "Canvas Page" value. Two
   sub-fetches attempting to confirm this specifically both 404'd today
   (unlike the core `appmodule`/`sitemap`/`appmodulecomponent` fetches, which
   succeeded). **Before implementation starts, this needs either:** (a) one
   more successful research pass, (b) inspecting a real Dataverse
   environment's `appmodulecomponent` rows for an existing app that already
   has a custom page added (fastest, most reliable — a `GET` query against
   any environment with a custom-page-hosting app already in it), or (c) an
   explicit decision to find out empirically by adding one custom page
   through the Maker Portal UI once, then reading back what `componenttype`
   Dataverse itself assigned.
2. **Where does the new JSON contract live?** A new file (cleaner
   separation, but a second contract + reconciliation engine to maintain) vs.
   extending `insurance-foundation.json` (reuses the existing, well-tested
   engine, but that engine's `nativeExtensions`/`tables` schema has no
   concept of "app module"/"sitemap" today — would need its own schema
   extension, similar in size to the `Whole`/`Multiline` type-system
   extension done for stream #58). Recommend a **new, small, dedicated
   script** (not extending `Publish-InsuranceFoundation.ps1`) given app
   modules/sitemaps are a different governance shape (DESIGN-SENSITIVE UX,
   not a data-model change) — but this is genuinely a design choice, not a
   technical constraint, and should be confirmed before writing code.
3. **`clienttype` and `formfactor`'s exact required values** weren't fully
   enumerated in today's research (the docs show them as required integers
   with a range, not a labeled picklist) — needs one more lookup or an
   empirical read from an existing app module (e.g. the out-of-box Sales Hub)
   before authoring.
4. **Autonomy class for this stream stays DESIGN-SENSITIVE**, per the
   sprint charter — this document does not change that; it's UX-facing,
   user-visible work, not an execution-only mechanical change.

## Definition of done for this design (not the implementation)

- [x] Explored existing design spec + sprint charter context.
- [x] Grounded `appmodule`/`sitemap`/`appmodulecomponent`/`AddAppComponents`
      in real Microsoft Learn content (not guessed).
- [x] Proposed 3 approaches with trade-offs and a recommendation.
- [x] Flagged genuine open questions rather than guessing past them.
- [ ] **Owner review of this document** — required before invoking
      `writing-plans` or touching any code, per the brainstorming skill's
      hard gate.
