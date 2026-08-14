# Handover Contract — the stream packet

| Field | Value |
| --- | --- |
| **Status** | Active contract |
| **Date** | 2026-08-11 |
| **Applies to** | Every delegated stream in the sprint operating model |
| **Machine-readable source** | [handover-packet.template.md](./handover-packet.template.md) |
| **Parsed by** | [Read-HandoverPacket.ps1](../../../scripts/orchestration/Read-HandoverPacket.ps1) |
| **Related** | [SPRINT-OPERATING-MODEL.md](../SPRINT-OPERATING-MODEL.md) · [INTAKE-CONTRACT.md](./INTAKE-CONTRACT.md) · [ADR-0023](../../adr/ADR-0023-delegated-sprint-operating-model.md) · [design spec](../specs/2026-08-11-delegated-sprint-operating-model-design.md) · [SUPERPOWERS_CONTRACT.md](../../../SUPERPOWERS_CONTRACT.md) |

---

## Purpose

A stream is dispatched to a delegated Copilot CLI session **only** with a
complete handover packet. The packet is the executable form of the statement
*"design is done, execution may begin"*: it names the approved design, the
autonomy class, the exact scope, and the verification the stream must pass
before it is allowed back to the trunk.

The packet is authored from [handover-packet.template.md](./handover-packet.template.md).
That template is the single machine-readable source of truth — the scaffolder
[New-SprintWorktree.ps1](../../../scripts/orchestration/New-SprintWorktree.ps1)
writes it and the parser
[Read-HandoverPacket.ps1](../../../scripts/orchestration/Read-HandoverPacket.ps1)
reads it, so both agree on the field syntax `- **Field:** value`. Never
hand-edit the field syntax away from that shape or the parser will not see it.

## Packet schema

Each field below is mandatory unless noted. The left column is the field name
exactly as it appears on the `- **Field:** value` line the parser matches.

| Field | Purpose |
| --- | --- |
| `Sprint` | Sprint ID, e.g. `sprint-001` — the traceability anchor for the whole run. |
| `Stream` | Stream ID within the sprint, e.g. `toolchain` — one delegated build stream. |
| `GitHub issue` | `#N` — mandatory. The per-stream issue number carried through packet → branch → PR → status board. |
| `Autonomy class` | `EXECUTION-ONLY` or `DESIGN-SENSITIVE`. Determines whether the dispatch wrapper may run headless. Any other value is rejected by the parser. |
| `Branch` | `feat/sprint-NNN-<stream>` — the isolated branch the stream builds on. |
| `Worktree` | Absolute path of the git worktree the stream runs inside, e.g. `C:\Users\urruegg\source\urruegg\wt\sprint-001-toolchain`. |
| `Approved design ref` | The ADR + spec link. The design is already human-approved on the trunk; this reference **is the autopilot gate** — no approved design, no packet. |
| `Goal / Definition of Done` | A single, testable outcome the stream must reach. |
| `Allowed scope (paths)` | The files the stream may touch. Bounds parallel streams so they do not collide on shared files. |
| `Verification commands` | The build / test / policy commands the stream must pass locally before intake. |
| `Guardrails` | Inherited [SUPERPOWERS_CONTRACT.md](../../../SUPERPOWERS_CONTRACT.md) §1, plus the explicit headless deny-list (`shell(git push)`, `shell(rm)`, `shell(git reset)`). |
| `Escalation rule` | *"If a new design decision is needed → STOP, write `BLOCKED: needs design`, surface the question to the control-plane chat. Never self-approve."* |

## Autonomy classes

There are exactly two classes. The dispatch wrapper
[Invoke-StreamDelegation.ps1](../../../scripts/orchestration/Invoke-StreamDelegation.ps1)
branches on this field and nothing else.

- **`EXECUTION-ONLY`** — the design is fully settled. The stream only builds,
  tests and commits within `Allowed scope (paths)`. It is eligible for
  **headless autopilot**: `copilot -p ... --allow-all-tools` with the
  `git push` / `rm` / `git reset` deny-list, so it can produce commits but can
  never integrate itself or rewrite history.
- **`DESIGN-SENSITIVE`** — the work may surface design choices. It **may never
  be launched headless.** The wrapper refuses a headless launch and prints an
  attended, interactive plan-mode command instead, preserving the human review
  and clarification loop. This is the enforced form of *"design is never
  autopilot-approved"* ([ADR-0023](../../adr/ADR-0023-delegated-sprint-operating-model.md)).

**Rule:** a `DESIGN-SENSITIVE` packet is never launched headless. Choosing the
class is a control-plane decision made when the stream issue is written, not
something a stream may change about itself.

## Worked example — `EXECUTION-ONLY`

A settled, scope-bounded build stream (the toolchain stream that built this
pattern). Fields use the `- **Field:** value` syntax the parser matches.

````markdown
# Handover Packet - toolchain

- **Sprint:** sprint-001
- **Stream:** toolchain
- **GitHub issue:** #12
- **Autonomy class:** EXECUTION-ONLY
- **Branch:** feat/sprint-001-toolchain
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-001-toolchain
- **Approved design ref:** ADR-0023 + docs/superpowers/specs/2026-08-11-delegated-sprint-operating-model-design.md

## Goal / Definition of Done

The sprint operating-model docs, handover/intake contracts, GitHub issue
templates and the sprint-001 charter exist, cross-link correctly, and the
orchestration Pester suite stays green.

## Allowed scope (paths)

- docs/superpowers/**
- .github/ISSUE_TEMPLATE/sprint-charter.md
- .github/ISSUE_TEMPLATE/stream-handover.md
- docs/sprints/README.md
- docs/plans/README.md

## Verification commands

```
Invoke-Pester -Path scripts/orchestration/tests -Output Detailed
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. Headless streams additionally deny
`shell(git push)`, `shell(rm)`, `shell(git reset)`.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
````

## Worked example — `DESIGN-SENSITIVE`

A stream whose work could still surface a design choice (an Insurance Foundation
schema-shape stream in proof #2). The class forces an attended session; the
wrapper refuses to run it headless.

````markdown
# Handover Packet - schema-shape

- **Sprint:** sprint-002
- **Stream:** schema-shape
- **GitHub issue:** #15
- **Autonomy class:** DESIGN-SENSITIVE
- **Branch:** feat/sprint-002-schema-shape
- **Worktree:** C:\Users\urruegg\source\urruegg\wt\sprint-002-schema-shape
- **Approved design ref:** ADR-0019 + docs/superpowers/specs/2026-08-08-insurance-foundation-design.md

## Goal / Definition of Done

Author the provisional insurance entity shape in the Dataverse solution so it
matches the approved design, with all lookups declared in a single create call.

## Allowed scope (paths)

- solution/schema/**

## Verification commands

```
pwsh scripts/solution/Test-Manifest.ps1
```

## Guardrails

Inherit SUPERPOWERS_CONTRACT.md section 1. This stream is DESIGN-SENSITIVE and
must run attended — it is never launched headless.

## Escalation rule

If a new design decision is needed -> STOP, write `BLOCKED: needs design`,
surface the question to the control-plane chat. Never self-approve.
````

## Where the packet comes from and where it goes

- **Authored from** [handover-packet.template.md](./handover-packet.template.md)
  by [New-SprintWorktree.ps1](../../../scripts/orchestration/New-SprintWorktree.ps1),
  which substitutes the `{{PLACEHOLDER}}` tokens for real values.
- **Parsed by** [Read-HandoverPacket.ps1](../../../scripts/orchestration/Read-HandoverPacket.ps1)
  into a structured object; an unknown or missing `Autonomy class` throws.
- **Consumed by** [Invoke-StreamDelegation.ps1](../../../scripts/orchestration/Invoke-StreamDelegation.ps1)
  to choose headless vs attended dispatch.

When the stream is done, it returns to the trunk under the
[Intake Contract](./INTAKE-CONTRACT.md).
