# Handover Packet - {{STREAM_ID}}

- **Sprint:** {{SPRINT_ID}}
- **Stream:** {{STREAM_ID}}
- **GitHub issue:** #{{ISSUE}}
- **Autonomy class:** {{CLASS}}
- **Branch:** {{BRANCH}}
- **Worktree:** {{WORKTREE}}
- **Approved design ref:** {{DESIGN_REF}}

## Goal / Definition of Done

{{GOAL}}

## Allowed scope (paths)

{{SCOPE}}

## Verification commands

```
{{VERIFY}}
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. Headless streams additionally deny
`shell(git push)`, `shell(rm)`, `shell(git reset)`.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
