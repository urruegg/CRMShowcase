# Design Pattern Library — Renumbering &amp; Diagram Curation (Phase 1) — Design Spec

| Field | Value |
| --- | --- |
| Status | Draft — pending user review |
| Date | 2026-08-17 |
| Author | AG-E-12 Frontier Firm Guide (drafted via Copilot CLI, brainstorming skill) |
| Related | [docs/design/README.md](../../design/README.md) · [docs/FRONTIER-OPERATING-MODEL.md](../../FRONTIER-OPERATING-MODEL.md) · the 11 `docs/design/ADR-00NN-*.md` files · `docs/adr/ADR-0019`, `ADR-0030`–`ADR-0039` |
| Licence | Documentation only — no runtime capability, no agent behaviour change |
| Upgrade impact | 11 file renames + content additions (new diagrams) inside `docs/design/`; 2 live cross-reference updates (`docs/design/README.md`, `docs/FRONTIER-OPERATING-MODEL.md` §10). No ADR renumbering, no change to any ADR's recorded decision. |

## 1. Purpose and scope

This is **Phase 1 of a larger 4-phase initiative** (confirmed via brainstorming
2026-08-17): the end-to-end Advisory Cockpit use-case documentation pass.
The full sequence is:

1. **Phase 1 (this spec)** — renumber `docs/design/*.md` and curate diagrams
   from their source ADRs into each.
2. **Phase 2** — new `docs/design/01-...md`: the Advisory Cockpit use case
   used as a "challenger" to validate the design patterns/options recorded
   in the other numbered docs.
3. **Phase 3** — FR/NFR traceability tables for UC-01 in `PRD.md`/`SD.md`.
4. **Phase 4** — refine remaining `docs/` files to align with Phases 2-3.

Phases 2-4 are **out of scope for this spec** and will each get their own
brainstorm → spec → plan cycle once the phase ahead of them is built (each
phase's concrete output shapes what the next phase needs — see
[writing-plans decomposition guidance]).

**This spec covers only:**
- Renaming the 11 ADR-linked `docs/design/ADR-00NN-*.md` files to sequential
  `NN-*.md` names (dropping the `ADR-00NN-` prefix from the filename and
  from each doc's own identity, while leaving each doc's `**Related ADR:**`
  cross-link to the real, unrenamed `docs/adr/ADR-00NN-*.md` untouched).
- Adding the pattern number into each doc's own H1 title, matching pattern
  `00`'s existing convention.
- Curating 3-5 decision-relevant Mermaid diagrams from each source ADR into
  its corresponding design-pattern doc.
- Updating the two live files that reference the old filenames:
  `docs/design/README.md` (the index) and `docs/FRONTIER-OPERATING-MODEL.md`
  §10 (its deliverables table).

## 2. Why now

`docs/design/README.md` already frames this folder as a demo-ready pattern
library, but today's ADR-number-based filenames (`ADR-0019-...`,
`ADR-0030-...`) expose internal ADR numbering to a customer-facing library,
and none of the 11 docs carry any of their source ADR's diagrams — a
stakeholder reading the pattern doc alone sees prose-only options with no
visual. Confirmed while researching: ADR-0019 has 4 Mermaid diagrams,
ADR-0030 has 23; the corresponding design docs currently have exactly 1
diagram each (added incidentally, not curated).

## 3. Decisions from brainstorming Q&A (2026-08-17)

| Question | Decision |
| --- | --- |
| Diagram scope per doc | Curated selection (~3-5), erring generous rather than minimal — not every diagram, not just 1-2 |
| Renumbering scheme | `01` reserved for Phase 2's new use-case doc; `02`-`12` = the 11 ADR-linked docs, same relative order as today's README (see table below; corrects an earlier `02`-`11` miscount) |
| Extension doc (`contoso-insurance-data-model-extension.md`) | Stays as-is, unnumbered — it is implementation-detail/BOM evidence for ADR-0019, a different purpose from the options-comparison docs |
| Historical spec/plan files (2026-08-16) | Left referencing the old `ADR-00NN-*.md` names — dated historical records, never retroactively updated, same convention already established for ADR renumbering in this repo |

## 4. Rename mapping

| New # | Old filename | New filename | Topic |
| --- | --- | --- | --- |
| 02 | `ADR-0019-insurance-data-model-options.md` | `02-insurance-data-model-options.md` | Insurance data model shape |
| 03 | `ADR-0030-dataverse-databricks-integration-options.md` | `03-dataverse-databricks-integration-options.md` | Dataverse ↔ Databricks integration |
| 04 | `ADR-0031-kafka-confluent-integration-options.md` | `04-kafka-confluent-integration-options.md` | Kafka/Confluent integration |
| 05 | `ADR-0032-iam-entra-power-platform-options.md` | `05-iam-entra-power-platform-options.md` | IAM (Entra ↔ Power Platform) |
| 06 | `ADR-0033-crm-ux-placement-options.md` | `06-crm-ux-placement-options.md` | CRM UX placement in B2E landscape |
| 07 | `ADR-0034-aro-case-task-integration-options.md` | `07-aro-case-task-integration-options.md` | ARO case/task integration |
| 08 | `ADR-0035-pdv-partner-master-data-options.md` | `08-pdv-partner-master-data-options.md` | PDV partner master data integration |
| 09 | `ADR-0036-crm-lead-campaign-landscape-options.md` | `09-crm-lead-campaign-landscape-options.md` | Lead/campaign external landscape |
| 10 | `ADR-0037-environment-strategy-options.md` | `10-environment-strategy-options.md` | Environment strategy (B2B/B2C) |
| 11 | `ADR-0038-purview-compliance-options.md` | `11-purview-compliance-options.md` | Purview compliance |
| 12 | `ADR-0039-devsecops-cicd-options.md` | `12-devsecops-cicd-options.md` | DevSecOps CI/CD |

Each renamed file's H1 changes from `# Design Pattern: <topic>` to
`# Design Pattern <NN>: <topic>` (number added, matching pattern `00`'s H1
"Design Pattern 00: Frontier Firm operating model for insurance"). No other
prose in any of the 11 files changes as part of the rename itself — content
changes (diagrams) are additive, addressed separately below.

## 5. Diagram curation approach

For each of the 11 files, read the full source ADR (`docs/adr/ADR-00NN-*.md`)
and select **~3-5 diagrams** using this priority order:
1. The diagram(s) depicting the **chosen/recommended option** (if the ADR
   has reached a decision) or the **leading candidate** (if still proposed).
2. A diagram contrasting the chosen option against at least one rejected
   alternative, if one exists and is genuinely illustrative side-by-side.
3. Any diagram the ADR itself flags as central to understanding the
   trade-off (e.g., a sequence/data-flow diagram referenced repeatedly in
   the ADR's own prose).

Insert each selected diagram into the matching "Option" subsection of the
design-pattern doc (next to the prose already describing that option), with
a one-line caption if the ADR's own diagram lacks one. Do not renumber or
retitle the ADR's own diagrams — copy them verbatim (Mermaid source
unchanged) so they stay a faithful, unforked reproduction, consistent with
this repo's "no forked content" principle already applied in the Frontier
Operating Model work.

**Concrete diagram selection is plan-level work**, done file-by-file once
this spec is approved — this spec fixes the approach and count, not the
literal list of which diagrams for which file.

## 6. Live cross-reference updates

**`docs/design/README.md`** — its index table's `#` column changes from
`ADR-0019`/`ADR-0030`-`ADR-0039` to `02`-`12`; each row's link target updates
to the new filename. The "Related ADR" column (linking into `docs/adr/`) is
unaffected — those files are not renamed.

**`docs/FRONTIER-OPERATING-MODEL.md` §10** — its deliverables table (row
"6–16") lists the 11 old filenames; update to the new filenames. This table
is retrospective build history for the 2026-08-16 initiative — updating it
keeps it a truthful pointer to where that content now lives, without
rewriting what was decided or when.

**Not touched:** `docs/superpowers/specs/2026-08-16-frontier-operating-model-design.md`
and `docs/superpowers/plans/2026-08-16-frontier-operating-model.md` — dated
historical records, per this repo's established convention (same treatment
already given to the ADR-0023→ADR-0040 renumbering's historical references).

## 7. Out of scope for this spec

- Phases 2-4 of the larger initiative (new use-case doc, FR/NFR traceability,
  refining other `docs/` files) — separate specs, later.
- Any change to the content/decision recorded in any ADR.
- Any change to `contoso-insurance-data-model-extension.md`.
- Any prose rewording inside the 11 design-pattern docs beyond the H1 number
  addition and the new diagram insertions (i.e., no wording "polish" pass on
  these 11 docs in this phase — that could be a candidate for a future
  polish step, but isn't part of renumbering + diagram curation).

## 8. Validation / acceptance criteria

- All 11 files exist under their new names; none of the old `ADR-00NN-*.md`
  filenames remain in `docs/design/`.
- `docs/design/README.md` and `docs/FRONTIER-OPERATING-MODEL.md` §10 contain
  zero remaining references to the old filenames.
- Every diagram copied into a design-pattern doc is valid Mermaid (renders
  cleanly) and is byte-identical to its source ADR's diagram (verbatim copy,
  not paraphrased).
- Each of the 11 H1 titles reads `# Design Pattern <NN>: <topic>` with the
  correct number from the mapping table.
- No other file in the repo (outside the 2 historical exceptions) still
  references an old filename — verified by a repo-wide search.
- The 2 historical files remain byte-identical to their current state.

## 9. Open questions / risks

- None blocking. Diagram selection quality is a per-file judgment call made
  during planning/execution, reviewed the same way Phase 1 (Design Pattern
  00 expansion) diagrams were reviewed — spec-compliance + quality review,
  including actually test-rendering Mermaid rather than only eyeballing it.
