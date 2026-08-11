# Handover Packet - smoke

- **Sprint:** sprint-001
- **Stream:** smoke
- **GitHub issue:** #44
- **Autonomy class:** EXECUTION-ONLY
- **Branch:** feat/sprint-001-smoke
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-001-smoke
- **Approved design ref:** ADR-0023

## Goal / Definition of Done

You are running as a delegated EXECUTION-ONLY build stream inside the git
worktree `wt/sprint-001-smoke` (branch `feat/sprint-001-smoke`). Do exactly
this and nothing else:

1. Open `docs/superpowers/sprints/sprint-001/STATUS.md`.
2. Under the `## Run log` heading, append exactly ONE new bullet line:
   `- smoke stream executed via real headless copilot dispatch on 2026-08-11 (issue #44).`
3. Stage and commit that single change with the message:
   `test(sprint-001): smoke stream evidence via headless copilot`
4. Do NOT run `git push`. Do NOT modify any other file.

This proves the delegation mechanism end to end. When done, stop.

## Allowed scope (paths)

- `docs/superpowers/sprints/sprint-001/STATUS.md`

## Verification commands

```
git log --oneline -1
git status --porcelain
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. Headless streams additionally deny
`shell(git push)`, `shell(rm)`, `shell(git reset)`.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.

