# Runbook — Solution rollback

## When to use this

A `solution-deploy-test.yml` run left TEST in a bad state, or a manual test
of the DEV → TEST promotion failed and we need to return TEST to a known
good version.

DEV is fix-forward — this runbook does not apply to DEV.

## Symptoms → path

| Symptom | Path |
| --- | --- |
| Newer managed layer imported OK but broke a form | Path 1 — re-deploy an earlier tag |
| Newer managed layer failed to import cleanly | Path 2 — delete the layer, re-deploy earlier |
| Managed solution needs to be removed entirely | Path 3 — delete solution |

## Path 1 — Re-deploy an earlier tag

Prerequisites:

- The earlier tag exists under `deploy/test/*`.
- The Global Admin operator account for the demo tenant is signed in (see
  [docs/ENVIRONMENTS.md](../ENVIRONMENTS.md) for the operator UPN
  pattern — never commit the actual UPN to Git).

Steps:

1. Find the tag: `git tag -l 'deploy/test/*' | Select-Object -Last 10`
2. Note its commit SHA: `git rev-list -n 1 deploy/test/<tag>`
3. Trigger `solution-deploy-test.yml` with that SHA:

   ```powershell
   gh workflow run solution-deploy-test.yml -f commit_sha=<sha>
   ```

4. Approve the deployment in the `test` GitHub Environment.
5. Verify:

   ```powershell
   $runId = gh run list --workflow=solution-deploy-test.yml --limit 1 --json databaseId --jq '.[0].databaseId'
   gh run watch $runId --exit-status
   ```

## Path 2 — Delete the broken managed layer

When `pac solution import` refuses because the target has a newer version:

1. Sign in: `pac auth select --name crmshowtest`.
2. Delete the broken solution layer:

   ```powershell
   pac solution delete --solution-name <name>
   ```

3. Re-run Path 1 to re-deploy the earlier tag.

## Path 3 — Delete the entire managed solution

Only if the solution must be removed and there is no earlier version to
roll back to.

⚠️ **This deletes all data stored in the solution's custom tables and
columns.** Confirm with a maintainer before running.

1. Sign in: `pac auth select --name crmshowtest`.
2. `pac solution delete --solution-name <name>`.
3. Re-import via `solution-deploy-test.yml` if we still want it in TEST.

## Prevention

- The `version-bump:major` heuristic on
  [`solution-ci.yml`](../../.github/workflows/solution-ci.yml) catches most
  breaking changes before merge.
- Every `solution-deploy-test.yml` run creates a `deploy/test/*` tag —
  never delete these; they are our roll-back inventory.

## Related

- [ADR-0019 — Solution versioning strategy](../adr/ADR-0019-solution-versioning-strategy.md)
- [Sprint 1 spec](../superpowers/specs/2026-08-06-solution-containers-design.md)
