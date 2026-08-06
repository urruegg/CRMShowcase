# Licensing position — per capability

| Field | Value |
| --- | --- |
| Status | **Draft — every `[TBD]` must be resolved before a customer commitment** |
| Rule | Every flag traces to the offer. **Never guess in the room.** |

Customers typically ask: *"is each capability discussed already covered by the
proposed licence model?"* Answer **per topic**.

| Flag | Meaning |
| --- | --- |
| ✅ | in the offer |
| ➕ | additional licence required |
| 🧩 | configuration / own build — no additional licence |
| 🗺️ | roadmap — not yet productive |

## Capability register

| Topic | Capability | Flag | Source in the offer |
| --- | --- | --- | --- |
| A2 | Core CRM / Dataverse platform | `[TBD]` | `[TBD]` |
| A2 | Custom entities & schema extension | 🧩 | — |
| A3 | Standard connectors | `[TBD]` | `[TBD]` |
| A3 | Custom integration development | 🧩 | — |
| A5 | Business process flows, flows | `[TBD]` | `[TBD]` |
| A6 | Copilot / assistance in-app | `[TBD]` | `[TBD]` |
| A6 | Copilot Studio agents | `[TBD]` | `[TBD]` |
| A6 | Case Management Agent (prefill) | `[TBD]` | `[TBD]` |
| A6 | Predictive lead scoring | `[TBD]` | `[TBD]` |
| A6 | Paid-media activation (Meta/Google) | ➕ / 🧩 | not a native send channel — export connectors |
| A6 | Look-alike modelling | ➕ / 🧩 | not native — Azure ML |
| A6 | Campaign budget / ROI / CPL | 🧩 | custom table + Power BI |
| A6 | Live transcript & Copilot voice | `[TBD]` | native voice channel only — [ADR-0015](./adr/ADR-0015-voice-channel-boundary.md) |
| A7 | Power BI | `[TBD]` | `[TBD]` |
| A7 | Analytics-platform provisioning | `[TBD]` | customer-side |
| A8 | Pipelines / ALM tooling | `[TBD]` | `[TBD]` |

**Every `[TBD]` above is a pre-flight blocker for a customer commitment.** For
anything genuinely unresolved, the honest answer is *"we will provide the
relevant information as a follow-up"* — use it, and log it in
[reviews/](./reviews/).
