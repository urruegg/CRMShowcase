# Frontier Operating Model — Design Pattern 00 Expansion — Design Spec

| Field | Value |
| --- | --- |
| Status | Draft — pending user review |
| Date | 2026-08-17 |
| Author | AG-E-12 Frontier Firm Guide (drafted via Copilot CLI, brainstorming skill) |
| Related | [docs/design/00-frontier-firm-operating-model-for-insurance.md](../../design/00-frontier-firm-operating-model-for-insurance.md) · [docs/FRONTIER-OPERATING-MODEL.md](../../FRONTIER-OPERATING-MODEL.md) · `docs/ideas/frontier-operating-system/` (00–05) · [docs/PERSONAS-JOURNEY.md](../../PERSONAS-JOURNEY.md) · [ADR-0014](../../adr/ADR-0014-agents-advisory-by-design.md) · [ADR-0038](../../adr/ADR-0038-purview-power-platform-dynamics365-compliance.md) · prior spec [2026-08-16-frontier-operating-model-design.md](./2026-08-16-frontier-operating-model-design.md) |
| Licence | Documentation only — no runtime capability, no agent behaviour change |
| Upgrade impact | Additive edit to one existing file (`docs/design/00-frontier-firm-operating-model-for-insurance.md`). No rename, no ADR change, no other file touched. |

## 1. Purpose and scope

This is step one of a broader, step-by-step wording-and-diagram polish pass across the repo's documentation (later steps, out of scope here, will apply the same treatment to other docs). This step expands
`docs/design/00-frontier-firm-operating-model-for-insurance.md` ("Design
Pattern 00") from its current short 4-section "method" doc into a full
narrative that walks an EA/IT stakeholder through all six parts of the
source idea-doc package (`docs/ideas/frontier-operating-system/00`–`05`),
reworded for Contoso Insurance, each illustrated with a Mermaid diagram.
`docs/FRONTIER-OPERATING-MODEL.md` remains the canonical full-detail
reference — no content is forked or duplicated; condensed sections in
Design Pattern 00 cross-link down to it for depth.

## 2. Why this matters now

- A prior initiative (PR #116, merged 2026-08-16) translated the idea-doc
  package into `FRONTIER-OPERATING-MODEL.md` (full reference, §1–12) and
  created Design Pattern 00 as a short "method" doc pointing at it.
- Design Pattern 00 today only thinly reflects the idea docs: it has the
  five-control-planes table and the four-step method, but nothing
  resembling the north-star vision/loop (idea 00), the PRD's problem
  statement/audiences/non-goals (idea 01), a control-plane architecture
  diagram (idea 02), the agent roster (idea 03), HITL data classes/
  redaction pattern (idea 04), or the phased roadmap (idea 05). Several of
  those (idea 01's PRD framing, idea 02's diagram, idea 04's data-class/
  redaction detail) don't live anywhere yet, even in condensed form.
- `docs/design/README.md` already instructs demo presenters to "start with
  pattern 00 to set the Frontier Firm mental model" — so it should actually
  deliver that mental model, not just point elsewhere for all of it.

## 3. Decisions already made (brainstorming Q&A, 2026-08-17)

| Question | Decision |
| --- | --- |
| Target shape | Expand to a full 6-part narrative — one insurance-reworded subsection + diagram per idea doc (00–05) |
| Overlap with `FRONTIER-OPERATING-MODEL.md` | Condensed + cross-link — no content forked in two places |
| Working branch | Continue on `docs/s3-test-evidence-e2e-verify` (no new branch). Flag: this branch carries an active, unrelated PR #119 (sprint-003 test evidence) — this change will land in its own clean, separately-scoped commit so it can be split out later if needed. |

## 4. Approaches considered

**Approach A — expand Design Pattern 00 in place, condensed-with-cross-links (chosen).**
Delivers the full mental model in the doc that's supposed to set it, with
no duplication. Trade-off: the doc grows roughly 6–8× in length (~50 →
~300–400 lines) — still single-purpose, but a longer read.

**Approach B — keep Design Pattern 00 short, push all depth into
`FRONTIER-OPERATING-MODEL.md` only (rejected by user).** Smaller diff,
stays skimmable, but doesn't fulfil the "start with pattern 00 to set the
mental model" promise — the reader has to jump elsewhere for almost
everything.

**Approach C — merge Design Pattern 00 and `FRONTIER-OPERATING-MODEL.md`
into one doc (rejected).** Zero duplication risk, but conflates two
different audiences/purposes: Design Pattern 00 is a demo-ready
walkthrough; `FRONTIER-OPERATING-MODEL.md` is a full reference that also
carries spec-style bookkeeping sections (§10 Deliverables, §11 Out of
scope, §12 Open validation triggers). `docs/design/README.md`'s whole
premise is a library of short, demo-ready pattern docs distinct from deep
reference docs — merging breaks that premise.

## 5. Detailed design — new section-by-section structure

Final structure, in order (titles are final; renumbered sections keep
their existing content unchanged except for the number):

1. **Why a Frontier Firm model for an insurer** — unchanged, wording
   tightened only.
2. **NEW — Vision and the operating loop** *(from idea 00)*
   - Vision statement, adapted:
     > Every relevant interaction with a customer, employee, or system
     > automatically strengthens Contoso Insurance's advice, product, and
     > processes.
     >
     > Contoso Insurance becomes a Human-led, Agent-operated advisory
     > practice, where the B2E/Work IQ layer steers human-agent
     > interaction, GitHub orchestrates the digital delivery, and
     > Dataverse reflects the operational reality.
   - Frontier-Firm principles (6, reworded and tied to existing ADRs):
     Human-led (ADR-0014) · Agent-operated (`AG-F-##`/`AG-E-##`) ·
     HITL-controlled (ADR-0014) · GitHub-driven (`AGENTS.md` §3) ·
     Dataverse-backed (ADR-0008) · Teams/B2E-visible (ADR-0033).
   - Diagram (draft, illustrative):
     ```mermaid
     flowchart LR
         classDef stage fill:#ffffff,stroke:#333333,stroke-width:1px,color:#111111
         I[Insight]:::stage --> D[Decision]:::stage --> DL[Delivery]:::stage --> O[Outcome]:::stage --> L[Learning]:::stage --> I

         subgraph Sources["Where insight comes from"]
             direction TB
             S1[Advisory conversations]
             S2[Service and claims cases]
             S3[Teams / B2E reviews]
             S4[Product usage]
             S5[Customer feedback]
             S6[Sprint reviews]
         end
         Sources --> I
     ```
   - Cross-link: `FRONTIER-OPERATING-MODEL.md` §4 (North-star loop and
     existing traceability) for the stage-by-mechanism mapping table.
3. **NEW — What the operating model must deliver** *(condensed PRD, from
   idea 01)*
   - Problem statement, adapted: insight today lives in silos (Teams/B2E
     discussions, advisory notes, meeting transcripts, GitHub issues,
     sprint reviews, product usage, customer feedback, operational
     Dataverse data) — without a standardized loop it risks going
     uncaptured, unprioritized, undelivered, or unmeasured.
   - Audiences — mapped to this repo's **real personas**
     (`docs/PERSONAS-JOURNEY.md`), not generic labels: primary =
     P-01 Advisor/GA, P-02 General Agent lead, P-03 Assistance agent,
     P-04 Marketer, P-05 Broker manager; secondary = P-06 IT/Architect,
     P-07 Business owner/Data steward, plus the engineering agents
     (`AG-E-01` Product Owner et al.) as the "build it" audience.
   - Non-goals (from idea 01 §8, reworded, tied to ADR-0014/ADR-0038): no
     fully autonomous prioritization without human sign-off; no autonomous
     PROD deployment without review; no unreviewed processing of sensitive
     customer data (health, financial exposure, claims) by an arbitrary
     agent; no wholesale replacement of existing advisory or engineering
     processes; no autonomously issued binding recommendations, quotes, or
     policy changes.
   - No diagram for this section — a short table is clearer than a
     diagram here, consistent with the "condensed" decision (no
     diagram-for-diagram's-sake).
   - Cross-link: none exists in `FRONTIER-OPERATING-MODEL.md` today — this
     is genuinely net-new content, not a duplicate.
4. **The five control planes and how they connect** — keep the existing
   table verbatim; **add** a Mermaid diagram (draft):
   ```mermaid
   flowchart TB
       classDef msft fill:#ffffff,stroke:#333333,stroke-width:1px,color:#111111
       classDef contoso fill:#fde8e8,stroke:#b91c1c,stroke-width:1px,color:#111111
       classDef shared fill:#e5e5e5,stroke:#666666,stroke-width:1px,color:#111111

       CE["Customers and Employees"]:::shared
       BP["Business / Teams and B2E"]:::shared
       IP["Interaction / Work IQ (documented only)"]:::msft
       AP["Agent / Copilot Agent Mesh"]:::msft
       EP["Engineering / GitHub"]:::msft
       OP["Operational / Dataverse and Power Platform"]:::shared
       TL["Teams / B2E transparency loop"]:::shared

       CE --> BP --> IP --> AP --> EP --> OP --> TL --> BP
   ```
   This reuses the existing `msft`/`contoso`/`shared` ownership colour
   convention from `FRONTIER-OPERATING-MODEL.md`'s Solution Context
   diagrams, because this diagram genuinely encodes the same dimension
   (who owns/builds each plane). Cross-link: `FRONTIER-OPERATING-MODEL.md`
   §5 (adapted table with Built/Documented-only status) + the Solution
   Context diagrams for full Contoso-specific architecture.
5. **NEW — The agent roster behind the planes** *(from idea 03, reusing
   `FRONTIER-OPERATING-MODEL.md` §6's table rather than re-deriving from
   the German original)*
   - Short intro: agents are advisory; they recommend, never decide
     (ADR-0014).
   - Reuse `FRONTIER-OPERATING-MODEL.md` §6's role-mapping table as-is
     (idea-doc role → existing agent(s) → notes).
   - Diagram (draft) visualizing the runtime-vs-engineering agent split
     that `AGENTS.md` draws (its "two classes of agent" framing) but that
     isn't diagrammed anywhere yet:
     ```mermaid
     flowchart LR
         classDef stage fill:#ffffff,stroke:#333333,stroke-width:1px,color:#111111
         SIG["Customer / employee signal"]:::stage --> RUN["Runtime agent (AG-F-##)\nadvisory only"]:::stage
         RUN --> HUM{"Human decision:\naccept / edit / dismiss"}
         HUM -- "becomes a product change" --> ENG["Engineering agent (AG-E-##)"]:::stage
         ENG --> GH["GitHub issue / PR"]:::stage
         HUM -- "no change needed" --> END[No further action]
     ```
   - Cross-link: `FRONTIER-OPERATING-MODEL.md` §6 (full table + rationale),
     `AGENTS.md` (full agent registry + non-delegable authority rules).
6. **NEW — HITL governance and data sensitivity** *(from idea 04)*
   - Governance principles (5, reworded): agents produce proposals, not
     final decisions, in critical processes; sensitive customer data is
     minimized/redacted before reaching GitHub; every relevant publication
     or handoff has a named owner; every agent action is traceable;
     automation may increase transparency but never replaces
     accountability.
   - Data classes reworded for insurance (4 classes, each with examples +
     processing rule): public/non-critical; internal business data;
     personal customer data/PII (redaction + purpose limitation + human
     review); sensitive data — health for life/health lines, financial
     exposure, claims specifics (highest protection class, no unreviewed
     GitHub handoff, only abstracted requirements or anonymized patterns).
   - One insurance-flavored redaction-pattern example (raw signal → GitHub-
     safe version → proper user story), e.g.:
     - Raw: "Customer Jane Doe mentioned during her claim follow-up that
       the online claim-status tracker is confusing."
     - GitHub-safe: "A customer mentioned during a claim follow-up that
       the online claim-status tracker is confusing."
     - As a requirement: "As a customer, I want to track my claim status
       with minimal steps, so that I don't need to call the service desk
       for updates."
   - Diagram (draft) — approval-state flow from idea 04 §7:
     ```mermaid
     stateDiagram-v2
         [*] --> DraftedByAgent
         DraftedByAgent --> NeedsHumanReview
         NeedsHumanReview --> Approved
         NeedsHumanReview --> NeedsChanges
         NeedsHumanReview --> Rejected
         NeedsChanges --> NeedsHumanReview
         Approved --> CreatedInGitHub
         CreatedInGitHub --> InSprint
         InSprint --> DeliveredToTest
         DeliveredToTest --> DeliveredToProd
         DeliveredToProd --> OutcomeReviewed
         OutcomeReviewed --> [*]
         Rejected --> [*]
     ```
   - Cross-link: `FRONTIER-OPERATING-MODEL.md` §7 (thin HITL/governance
     section), ADR-0014, ADR-0038.
7. **Roadmap, phased and status-tagged** *(condensed from idea 05, reusing
   `FRONTIER-OPERATING-MODEL.md` §9's six phases and Built/Demoed/
   Documented-only tags verbatim rather than re-deriving from idea 05)*
   - Diagram (draft) — **deliberately a new, distinct colour convention**
     from the `msft`/`contoso`/`shared` ownership palette used in §4,
     because this diagram encodes a different dimension (delivery status,
     not system ownership) — reusing the same 3 colours for two different
     meanings across diagrams would confuse readers, not create alignment:
     ```mermaid
     flowchart LR
         classDef built fill:#d1fae5,stroke:#065f46,stroke-width:1px,color:#111111
         classDef demoed fill:#fef3c7,stroke:#92400e,stroke-width:1px,color:#111111
         classDef docOnly fill:#e5e5e5,stroke:#666666,stroke-width:1px,stroke-dasharray: 4 2,color:#111111

         P0["Phase 0: Foundation"]:::built --> P1["Phase 1: Teams/B2E to GitHub transparency"]:::demoed
         P1 --> P2["Phase 2: Work IQ agent intake"]:::docOnly
         P2 --> P3["Phase 3: Sprint review to GitHub"]:::built
         P3 --> P4["Phase 4: Release to outcome loop"]:::demoed
         P4 --> P5["Phase 5: Agent mesh scaling"]:::demoed
     ```
     Legend: green = Built, amber = Demoed via docs, grey dashed =
     Documented-only.
   - Cross-link: `FRONTIER-OPERATING-MODEL.md` §9 for the full phase
     descriptions (reused verbatim, so no new detail is needed here).
8. **A four-step establishment method** — unchanged content, renumbered
   from the current §3.
9. **Contoso Insurance as the worked example** — unchanged content,
   renumbered from the current §4, with its bullet list extended so items
   now covered in this same doc point at sections 2/3/5/6/7 above, while
   items still only detailed in `FRONTIER-OPERATING-MODEL.md` (terminology
   adaptation §3, the Work IQ↔GitHub pattern §8) keep pointing there.

Unchanged closing sections, both updated only for the new walk order:

- **Validate this live** — walk order becomes: this doc section by section
  (2 vision → 3 requirements → 4 control planes → 5 agents → 6 governance
  → 7 roadmap → 8 method → 9 worked example), then
  `FRONTIER-OPERATING-MODEL.md` for full depth, then
  `docs/superpowers/sprints/` for the delivery-evidence loop.
- **Decision** — unchanged; still no accept/reject recorded (this remains
  a method doc, not an ADR).

## 6. Diagram inventory

| # | Section | Diagram type | Shows | Colour convention |
| --- | --- | --- | --- | --- |
| 1 | §2 Vision and operating loop | `flowchart` | Insight→Decision→Delivery→Outcome→Learning loop + insurance-specific insight sources | Plain (process flow, not ownership) |
| 2 | §4 Five control planes | `flowchart TB` | Customers/Employees through the 5 planes and back to the transparency loop | Reuses `msft`/`contoso`/`shared` ownership classDef |
| 3 | §5 Agent roster | `flowchart LR` | Signal → runtime agent → human decision → engineering agent → GitHub | Plain (process flow) |
| 4 | §6 HITL governance | `stateDiagram-v2` | Approval-state flow, Drafted → Outcome Reviewed | Plain (state flow) |
| 5 | §7 Roadmap | `flowchart LR` | 6 phases, coloured by delivery status | New `built`/`demoed`/`docOnly` classDef — deliberately distinct from the ownership palette |

## 7. Content grounding / sourcing map

| Section | Primary source | Reused from this repo | Net-new authoring |
| --- | --- | --- | --- |
| §2 Vision and operating loop | idea 00 §2–3 | `FRONTIER-OPERATING-MODEL.md` §4 (cross-linked, not copied) | Vision statement reworded; diagram is new |
| §3 What it must deliver | idea 01 §3, 5, 8 | `docs/PERSONAS-JOURNEY.md`, ADR-0014 | Problem statement, audience table, non-goals — all newly condensed |
| §4 Five control planes | idea 02 §3–4 (diagram only) | Existing table kept verbatim | New diagram only |
| §5 Agent roster | idea 03 §2–3 (principles + roster names) | `FRONTIER-OPERATING-MODEL.md` §6 table (reused verbatim) | Intro paragraph + new small diagram |
| §6 HITL governance | idea 04 §2–5, 7 | ADR-0014, ADR-0038 (cross-linked) | Principles/data classes/redaction example reworded; diagram new |
| §7 Roadmap | idea 05 (phase names only) | `FRONTIER-OPERATING-MODEL.md` §9 (six phases + status tags reused verbatim) | New diagram only |
| §8 Method | n/a (repo-original) | Existing §3 kept as-is | None |
| §9 Worked example | n/a | Existing §4 kept | Bullet list extended only |

## 8. Out of scope for this spec

- No changes to `FRONTIER-OPERATING-MODEL.md`, `MICROSOFT-FRAMEWORKS.md`,
  or any ADR in this pass (later steps in the broader polish initiative may
  revisit them).
- No changes to the other 11 `docs/design/*.md` pattern docs.
- No renumbering or renaming of any agent, ADR, or file.
- No new external citations — this reuses `FRONTIER-OPERATING-MODEL.md`
  §2's existing grounding table by reference rather than re-citing sources.

## 9. Validation / acceptance criteria

- Every internal cross-reference (to `FRONTIER-OPERATING-MODEL.md`
  sections, ADRs, `AGENTS.md`, `PERSONAS-JOURNEY.md`) resolves to a real,
  existing anchor.
- Every new Mermaid diagram uses valid `flowchart`/`stateDiagram-v2` syntax
  and renders in GitHub's built-in Mermaid preview.
- `docs/design/README.md`'s one-line index description for pattern 00
  still accurately describes the doc after expansion (check wording, tweak
  only if it now undersells the doc).
- No content is copied verbatim from `FRONTIER-OPERATING-MODEL.md` beyond
  short quoted table rows — new prose is freshly condensed, not pasted.
- The file keeps its existing path and filename (no rename).

## 10. Open questions / risks

- Final doc length (~300–400 lines) is acceptable for a demo/reference
  doc; flag during review if it should be split instead.
- None blocking.
