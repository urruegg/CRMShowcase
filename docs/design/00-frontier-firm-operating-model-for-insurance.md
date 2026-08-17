# Design Pattern 00: Frontier Firm operating model for insurance

**Audience:** EA / IT stakeholders of any insurer evaluating whether - and how - to establish a Frontier Firm-style agentic operating model.  
**Related doc:** `docs/FRONTIER-OPERATING-MODEL.md` (full detail for this showcase's own instantiation)

## 1. Why a Frontier Firm model for an insurer

Microsoft's 2025/2026 Work Trend Index frames the Frontier Firm around agents, human agency, and the opportunity for every organization, which makes the first insurance question an operating-model question, not an integration question. Before choosing any single API, UI, or data pattern, an insurer has to decide how customer-facing employees, copilots, approval points, engineering delivery, and the system of record will work together, because that is how a Frontier Company actually builds and operates a solution with Microsoft's current agentic stack. If that division of labor is unclear, every downstream pattern - Work IQ, GitHub, Dataverse, Copilot Studio, or core-system integration - will be implemented without a shared accountability model.

## 2. The five control planes, generically stated

| Control plane | Generic insurance meaning |
| --- | --- |
| Business / Teams | The coordination layer between customer-facing staff and the customers, brokers, partners, and internal colleagues they serve through the insurer's everyday workplace surfaces. |
| Interaction / Work IQ | The human-agent interaction surface layered over collaboration tools, where people ask for help, inspect context, delegate tasks, and stay in control of agent work. |
| Agent / Copilot Agent Mesh | The named roster of task-focused runtime and engineering agents, each with a clear purpose, owner, maturity, and handoff boundary. |
| Engineering / GitHub | The delivery toolchain that versions the agent mesh itself: prompts, ADRs, issues, pull requests, CI evidence, and the engineering agents that keep the mesh reviewable and releasable. |
| Operational / Dataverse + Power Platform | The operational system-of-record layer where customer-relationship processes, governed actions, audit, events, security, and CRM workflow live. |

> **In this showcase:** Business/Teams, Agent/Copilot Agent Mesh, Engineering/GitHub, and Operational/Dataverse are **built**. Interaction/Work IQ is **documented only** - see `docs/FRONTIER-OPERATING-MODEL.md` section 8 for why, and how a real engagement would wire it up.

## 8. A four-step establishment method

Any insurer's EA/IT team can follow this method to stand up their own version:

1. **Inventory your own control-plane equivalents.** Identify which existing products, portals, collaboration tools, engineering systems, and operational platforms already play each role. Many insurers already have all five planes in place, but under different names and with unclear ownership boundaries.
2. **Map the idea-doc's eight abstract roles onto your own org chart and agent registry.** Follow the pattern used in `docs/FRONTIER-OPERATING-MODEL.md` section 6: map the model onto your actual Enterprise Architects, UX Designers, Product Owners, Domain Experts, runtime agents, and compliance authorities rather than leaving the operating model at generic Frontier-role labels.
3. **Phase your roadmap.** Tag each phase the way `docs/FRONTIER-OPERATING-MODEL.md` section 9 does: **[Built]**, **[Demoed via docs]**, or **[Documented-only]**. That forces honest sequencing and prevents a future-state narrative from being mistaken for a delivered capability.
4. **Set HITL and governance guardrails before any agent is granted write access.** Use the same non-negotiable starting point expressed in `docs/FRONTIER-OPERATING-MODEL.md` section 7: agents recommend, a named human decides. Then bind that principle to concrete review authority, compliance controls, and approval points before any agent is allowed to mutate operational records.

## 9. Contoso Insurance as the worked example

This repo is the worked example of the method above, applied to the Contoso Insurance Advisory Cockpit use case:

- Vision and operating loop: section 2 above.
- What the model must deliver: section 3 above.
- Control-plane inventory: section 4 above, and `docs/FRONTIER-OPERATING-MODEL.md` section 5 for full detail.
- Agent roster and role mapping: section 5 above, and `docs/FRONTIER-OPERATING-MODEL.md` section 6 for full detail.
- HITL/governance guardrails: section 6 above, and `docs/FRONTIER-OPERATING-MODEL.md` section 7 for full detail.
- Work IQ <-> GitHub pattern (documented only, not covered in this doc): `docs/FRONTIER-OPERATING-MODEL.md` section 8.
- Roadmap phasing: section 7 above, and `docs/FRONTIER-OPERATING-MODEL.md` section 9 for full detail.
- The concrete artefacts this method produced: the 11 ADR-linked pattern docs in this same folder - see `docs/design/README.md` for the full index.

## Validate this live

During the demo, open `docs/FRONTIER-OPERATING-MODEL.md` and walk section by section (section 5 control planes -> section 6 role mapping -> section 7 governance -> section 8 Work IQ pattern -> section 9 roadmap) to show this is a real, repo-grounded method, not a slide-only framework. Then open `docs/superpowers/sprints/` to show the requirement -> ADR -> design-pattern -> deployed-evidence loop this repo actually runs.

## Decision

No final decision recorded here - this pattern doc is a method, not an ADR, and carries no accept/reject status. Selecting and adapting a target operating model for a real insurer deployment requires an EA/IT stakeholder workshop; see `docs/FRONTIER-OPERATING-MODEL.md` for full context to bring to that conversation.
