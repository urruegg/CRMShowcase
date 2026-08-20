---
description: Power Apps Code Apps architecture, local development, data access and ALM
applyTo: 'solution/apps/**/{code-apps,packages}/**/*.{ts,tsx,js,json,html,css}'
---

# Power Apps Code Apps

- Start from the official current `microsoft/PowerAppsCodeApps` Vite template.
- Use `@microsoft/power-apps` and `@microsoft/power-apps-vite`; keep each app's
  generated `power.config.json`, models and services app-local.
- Use generated Dataverse services only. Do not add raw Dataverse Web API
  calls, FetchXML, custom APIs or flow workarounds to conceal an unsupported
  SDK operation.
- Keep fixture adapters local-only. Authenticated and deployed apps have
  no fixture fallback and must show denied, failed, empty and unmapped states.
- Run one server at a time: fixture Vite first, stop it, then `pa app run`.
- Start each server in a new Visual Studio Code integrated terminal. Open
  visual refinement pages inside Visual Studio Code, share them with Copilot,
  and keep visual choices attended.
- Support EN/DE/FR/IT. Dataverse/MDA metadata labels use native localization.
  Code App-owned strings use versioned app-local catalogs. Resolve locale
  identically in B1 and B2 from `navigator.languages` in preference order and
  canonicalize candidates with `Intl.getCanonicalLocales`. Map `de`, `fr`, and
  `it` to their catalogs and fallback to `en`. `getContext()` does not expose a
  locale; never hard-code user-facing strings or infer locale from it.
- Publish to DEV only from a clean reviewed checkout at the reviewed commit.
  Verify each app's `power.config.json` is bound to the approved DEV
  environment ID. Build and test immediately before publication. Create a
  sorted per-file SHA-256 manifest of `dist` using normalized relative paths,
  serialize it as a BOM-free UTF-8 manifest, and hash the manifest. Leave
  `dist` unchanged between hashing and push, then use attended
  `pa app push --solution-id <crmshow_Sales GUID>`.
- Capture the returned play URL, open the published app, and verify
  `getContext().app.environmentId` equals the approved DEV environment ID.
- Publication evidence records the commit, manifest hash, successful build and
  test evidence, CLI version, app identity, solution identity, approved DEV
  environment ID, returned play URL, runtime environment ID, operator,
  timestamp and result. No client secret is introduced or stored.
- TEST receives the exact managed artifact through the existing OIDC pipeline.
  Direct TEST authoring is prohibited.
- Resolve environment-specific host and play URLs through managed
  configuration. Never hard-code a DEV URL in source.
- Preserve agents-recommend/humans-decide. Use closed typed commands,
  schema-validated writes, explicit human confirmation and a post-write reread
  before reporting success.
