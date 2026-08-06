# Dataverse solution

The unmanaged solution, unpacked and source-controlled.

**Nothing reaches an environment except through the pipeline**
([ADR-0017](../docs/adr/ADR-0017-alm-everything-through-the-pipeline.md)). A
change that exists in an environment but not here is invisible, unreviewed and
unreproducible — and it is the single largest driver of a platform becoming
unmaintainable after a few release cycles.

Owner: [AG-E-08 Dataverse Modeler](../.github/agents/dataverse-modeler.agent.md).

`[TBD — unpack the solution from the sandbox and commit it as the first PR that
touches Dataverse.]`

## What lives here

- The solution `.zip` (managed and unmanaged) is under version control on
  branches / tags; a mirror of the unpacked solution structure lives here so
  every table, form, business rule, security role, plug-in and Copilot Studio
  topic is diff-able in a PR.
- No secrets. No connection references with real values.

## What does not

- Environment-specific configuration. That lives in
  [infra/terraform/](../infra/terraform/) and in GitHub Environments.
