# Pattern - Code App Local-First Polish Loop

> Anchored by
> [ADR-0041](../../adr/ADR-0041-code-apps-primary-for-bespoke-full-page-crm-ux.md)
> and the approved
> [US-301 Advisor Cockpit parity design](../specs/2026-08-19-power-apps-code-app-advisor-cockpit-parity-design.md).

A sequential, attended method for refining a bespoke full-page Power Apps Code
App against synthetic fixtures, validating its authenticated local host, and
then proving the same reviewed source with live data in DEV and TEST.

## When to use

Use this pattern for a bespoke full-page CRM experience after model-driven
forms, views, timelines and commands have been ruled insufficient. Use PCF
instead when a control needs form, dataset or field context. Record any
exception to this placement rule through architecture review.

This pattern does not build or simulate B2E, add Azure services, replace native
CRM work, or permit a deployed fixture fallback.

## Preconditions

- Initialize each app from the official current `microsoft/PowerAppsCodeApps`
  Vite template and use `@microsoft/power-apps` with
  `@microsoft/power-apps-vite`.
- Keep each app's `power.config.json`, generated models and generated Dataverse
  services app-local.
- Use only synthetic, typed fixtures in the local Vite adapter.
- Keep runtime commands closed and typed; Dataverse writes remain
  schema-validated and human-approved.
- Validate Power Apps Premium and applicable Dynamics 365 / Copilot Studio
  rights for each test persona before making a rollout commitment.

## Sequential loop

Run one server at a time. Every gate starts in a new Visual Studio Code
integrated terminal, and every visual page opens inside Visual Studio Code so
the user can share it with Copilot. Visual choices remain attended.

### Gate 1 - fixture-backed Vite polish

1. Start the fixture harness with `npm run dev`.
2. Open the local page inside Visual Studio Code and share it with Copilot.
3. Compare the complete experience with the approved visual baseline at fixed
   desktop and mobile viewports.
4. Let the user review each change to layout, hierarchy, typography, tokens,
   interaction and responsive behavior; do not infer visual approval.
5. Run component, interaction, accessibility and visual-regression checks for
   the accepted refinement batch.
6. Capture the approved screenshots and findings, then stop the Vite server.

Fixture mode is local-only. It must never be imported into `pa app run`, DEV,
TEST or a production bundle.

### Gate 2 - authenticated local Code App host

1. In a fresh integrated terminal, start the app with `pa app run`.
2. Open its Local Play URL inside Visual Studio Code using the tenant browser
   profile.
3. Verify host context, generated Dataverse services, least-privilege identity,
   native navigation and all loading, empty, denied, failed and unmapped states.
4. Exercise supported writes only after explicit human confirmation, then
   reread the Dataverse record before reporting success.
5. Confirm the authenticated build has no fixture fallback and fails visibly
   when live data or configuration is unavailable.
6. Stop the server before starting another app or returning to Vite.

A local pass proves the generated-service contract. It does not prove live
embedding, environment sharing, CSP, managed promotion or TEST parity.

### Gate 3 - live DEV and TEST evidence

1. Start from a clean reviewed checkout at the reviewed Git commit and verify
   each app's `power.config.json` is bound to the approved DEV environment ID.
   Build and test immediately before publication.
2. Create a sorted per-file SHA-256 manifest of `dist` using normalized relative
   paths, serialize it as a BOM-free UTF-8 manifest, and hash the manifest.
   Leave `dist` unchanged between hashing and push.
3. A maker/admin performs attended
   `pa app push --solution-id <crmshow_Sales GUID>` to DEV only. Publication
   evidence records the commit, manifest hash, successful build and test
   evidence, CLI version, app identity, solution identity, approved DEV
   environment ID, returned play URL, runtime environment ID, operator,
   timestamp and result. No client secret is introduced or stored.
4. Validate the live DEV host with the least-privilege advisor and synthetic
   scenario, including `getContext().app.environmentId` against the approved DEV
   environment ID.
5. TEST receives the exact managed artifact through the existing OIDC pipeline.
   Direct TEST authoring is prohibited.
6. Apply environment-specific configuration without hard-coding a DEV play URL
   in source.
7. Repeat the same advisor journey in TEST and compare the evidence with DEV.

Only live DEV and TEST evidence can support a host-placement decision. B1 and
B2 remain unselected until both have completed the approved parity scorecard.

## Accessibility matrix

For every view and dialog, record evidence for:

| Area | Required evidence |
| --- | --- |
| Keyboard | Logical tab order, complete keyboard operation, no focus trap |
| Focus | Visible focus, restored focus after dialogs, useful initial focus |
| Semantics | Landmarks, headings, names, roles, states and error association |
| Visual | Token contrast, zoom, 320px reflow and 400% zoom without lost work |
| Locale | EN/DE/FR/IT smoke and locale-aware values without clipped text |

## Provenance matrix

Every data-bearing region classifies authoritative origin and provides a text
cue; color is never the only signal.

| State | Presentation and behavior |
| --- | --- |
| CRM-native/mastered | Normal presentation with an accessible source name |
| External or projected | Grey treatment plus an accessible source name |
| Unmapped | Yellow treatment plus an explicit unmapped label |
| Empty | Neutral empty state, never yellow |
| Permission denied | Explicit denied state, never fixture data |
| Load failure | Explicit error and retry path, never fixture data |

Agent-authored content retains visible provenance and AI-assisted disclosure.

## Write-capability matrix

Every visible command records:

| Field | Required content |
| --- | --- |
| Action | Stable command identifier and user-facing label |
| Intended effect | Local, read, navigate or write |
| Target | Table, column, relationship or destination |
| Host support | Supported, partial, blocked or unverified for each host |
| Limitation | Missing schema, lookup, permission or SDK capability |
| Runtime treatment | Enabled, partially enabled or disabled with a reason |
| Evidence | Automated test or live run proving the result |
| Remediation | Deferred requirement outside the approved sprint scope |

Unsupported commands remain visible and disabled with a reason; they never
simulate success. Supported writes use generated Dataverse services, a closed
typed command, explicit human approval, schema validation and a post-write
reread. Free-text model output never mutates Dataverse directly.

## Exit evidence

- Fixture, authenticated local, live DEV and live TEST results are clearly
  separated.
- The same synthetic scenario and least-privilege persona are used in DEV and
  TEST.
- Screenshots, accessibility results, provenance checks, command results,
  timings, session IDs and known limitations are linked to the reviewed commit.
- No Azure dependency, B2E artifact, fixture fallback, real customer data,
  hard-coded DEV URL or direct TEST authoring is present.
- Rollback restores the previous managed solution and host configuration.
