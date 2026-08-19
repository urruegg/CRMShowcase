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
- Publish Code Apps into `crmshow_Sales` with attended `pa app push` to DEV
  only. Promote the exact managed solution from DEV to TEST through the
  existing OIDC pipeline; never author directly in TEST or store a client
  secret.
- Resolve environment-specific host and play URLs through managed
  configuration. Never hard-code a DEV URL in source.
- Preserve agents-recommend/humans-decide. Use closed typed commands,
  schema-validated writes, explicit human confirmation and a post-write reread
  before reporting success.