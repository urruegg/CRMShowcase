# Design Pattern Library Renumbering &amp; Diagram Curation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. **Tasks 1-11 are mutually independent (different files, no shared state) — see the dispatching-parallel-agents skill; they may be executed concurrently rather than one-at-a-time.** Tasks 12-14 depend on Tasks 1-11 being complete and must run after them, sequentially.

**Goal:** Rename the 11 ADR-linked `docs/design/ADR-00NN-*.md` files to sequential `NN-*.md` names, add each pattern's number into its own H1, curate 3-5 decision-relevant Mermaid diagrams (copied verbatim) from each source ADR into its design-pattern doc, and update the 2 live files that reference the old filenames — per the approved design spec `docs/superpowers/specs/2026-08-17-design-pattern-library-renumbering-design.md`.

**Architecture:** Documentation-only. Each of Tasks 1-11 touches exactly one design-pattern doc (rename + H1 edit + diagram insertion) and reads exactly one source ADR (read-only). Tasks 12-13 touch the 2 live cross-referencing files. Task 14 is whole-library verification. "Tests" are structural/content-integrity checks via PowerShell (`Test-Path`, `Select-String`, manual diagram-diffing against source ADRs) — no code, no build system.

**Tech Stack:** Markdown + Mermaid only. `git mv` for renames (preserves file history). PowerShell for verification.

---

## Diagram selection criteria (apply in every Task 1-11)

When choosing which 3-5 diagrams to copy from a source ADR into its design-pattern doc, prioritize in this order:
1. The diagram(s) depicting the **chosen/recommended option**, or the **leading candidate** if the ADR is still `Proposed hypothesis`.
2. A diagram contrasting the chosen/leading option against a rejected/alternative one, if one exists and is genuinely illustrative placed side-by-side.
3. Any diagram the ADR's own prose treats as central to the trade-off (referenced or explained repeatedly in the surrounding text).

Copy each selected diagram's Mermaid code block **verbatim** (exact text, not retyped/paraphrased) into the matching `### Option X: ...` subsection of the design-pattern doc, placed directly after the prose paragraph(s) describing that option. If the ADR's diagram lacks an adjacent one-line caption, add one in italics directly below the code fence, in the same style as this repo's other design docs.

---

### Task 1: Rename and diagram-curate — Insurance data model shape (02)

**Files:**
- Rename: `docs/design/ADR-0019-insurance-data-model-options.md` → `docs/design/02-insurance-data-model-options.md`
- Read-only source: `docs/adr/ADR-0019-provisional-insurance-data-model-shape.md` (has 4 Mermaid diagrams)

- [ ] **Step 1: Rename via git mv**

```bash
git mv docs/design/ADR-0019-insurance-data-model-options.md docs/design/02-insurance-data-model-options.md
```

- [ ] **Step 2: Update the H1**

Change the first line from:
```text
# Design Pattern: Insurance data model shape
```
to:
```text
# Design Pattern 02: Insurance data model shape
```
Nothing else on that line or the lines immediately below (Audience/Related ADR) changes.

- [ ] **Step 3: Curate diagrams**

Read `docs/adr/ADR-0019-provisional-insurance-data-model-shape.md` in full (it has 4 Mermaid diagrams, roughly around lines 145, 221, 330, 462 — confirm exact locations yourself, these line numbers may have shifted). Apply the diagram selection criteria above. Since this ADR has only 4 diagrams total, you may include all 4 if each is genuinely distinct and illustrative (still within the "~3-5" band) — do not force an artificial cut only to hit a smaller number. Insert each into the matching `### Option ...` subsection of `docs/design/02-insurance-data-model-options.md`.

- [ ] **Step 4: Verify**

```powershell
Test-Path "docs/design/02-insurance-data-model-options.md"
Test-Path "docs/design/ADR-0019-insurance-data-model-options.md"
Select-String -Path "docs/design/02-insurance-data-model-options.md" -Pattern "^# "
(Select-String -Path "docs/design/02-insurance-data-model-options.md" -Pattern '```mermaid' -AllMatches).Matches.Count
```
Expected: first `True`, second `False` (old file gone), H1 reads `# Design Pattern 02: Insurance data model shape`, mermaid count between 3 and 5 (inclusive; see Step 3's "may include all 4" note).

- [ ] **Step 5: Commit**

```bash
git add docs/design/02-insurance-data-model-options.md
git commit -m "docs(design-library): rename to 02, curate diagrams from ADR-0019" -- docs/design/02-insurance-data-model-options.md docs/design/ADR-0019-insurance-data-model-options.md
```
(Include both the new and old path in the commit — `git mv` stages both the deletion and the addition; the pathspec here just scopes the commit to this rename+edit, not any other pending files.)

---

### Task 2: Rename and diagram-curate — Dataverse ↔ Databricks integration (03)

**Files:**
- Rename: `docs/design/ADR-0030-dataverse-databricks-integration-options.md` → `docs/design/03-dataverse-databricks-integration-options.md`
- Read-only source: `docs/adr/ADR-0030-dataverse-to-databricks-integration-pattern.md` (has 23 Mermaid diagrams — the largest source ADR in this batch)

- [ ] **Step 1: Rename via git mv**

```bash
git mv docs/design/ADR-0030-dataverse-databricks-integration-options.md docs/design/03-dataverse-databricks-integration-options.md
```

- [ ] **Step 2: Update the H1**

Change `# Design Pattern: <topic>` (read the file to get its exact current title text) to `# Design Pattern 03: <same topic text>` — add only the number, do not reword the topic.

- [ ] **Step 3: Curate diagrams**

Read `docs/adr/ADR-0030-dataverse-to-databricks-integration-pattern.md` in full — it is long (23 diagrams). Apply the diagram selection criteria above strictly: this ADR has far more diagrams than needed, so be selective — pick the 3-5 that most directly show the chosen/recommended integration approach and, if illustrative, one contrasting alternative. Insert into the matching `### Option ...` subsections of `docs/design/03-dataverse-databricks-integration-options.md`.

- [ ] **Step 4: Verify**

```powershell
Test-Path "docs/design/03-dataverse-databricks-integration-options.md"
Test-Path "docs/design/ADR-0030-dataverse-databricks-integration-options.md"
Select-String -Path "docs/design/03-dataverse-databricks-integration-options.md" -Pattern "^# "
(Select-String -Path "docs/design/03-dataverse-databricks-integration-options.md" -Pattern '```mermaid' -AllMatches).Matches.Count
```
Expected: `True`, `False`, H1 = `# Design Pattern 03: <topic>`, mermaid count 3-5.

- [ ] **Step 5: Commit**

```bash
git add docs/design/03-dataverse-databricks-integration-options.md
git commit -m "docs(design-library): rename to 03, curate diagrams from ADR-0030" -- docs/design/03-dataverse-databricks-integration-options.md docs/design/ADR-0030-dataverse-databricks-integration-options.md
```

---

### Task 3: Rename and diagram-curate — Kafka/Confluent integration (04)

**Files:**
- Rename: `docs/design/ADR-0031-kafka-confluent-integration-options.md` → `docs/design/04-kafka-confluent-integration-options.md`
- Read-only source: `docs/adr/ADR-0031-crm-core-systems-kafka-confluent-integration-pattern.md`

- [ ] **Step 1: Rename via git mv**
```bash
git mv docs/design/ADR-0031-kafka-confluent-integration-options.md docs/design/04-kafka-confluent-integration-options.md
```
- [ ] **Step 2: Update H1** — add `04` following the same pattern as Task 1/2 (read current H1, insert the number before the colon).
- [ ] **Step 3: Curate diagrams** — read the source ADR in full, apply the selection criteria, insert 3-5 diagrams verbatim into the matching Option subsections.
- [ ] **Step 4: Verify**
```powershell
Test-Path "docs/design/04-kafka-confluent-integration-options.md"
Test-Path "docs/design/ADR-0031-kafka-confluent-integration-options.md"
Select-String -Path "docs/design/04-kafka-confluent-integration-options.md" -Pattern "^# "
(Select-String -Path "docs/design/04-kafka-confluent-integration-options.md" -Pattern '```mermaid' -AllMatches).Matches.Count
```
Expected: `True`, `False`, H1 = `# Design Pattern 04: <topic>`, mermaid count 3-5.
- [ ] **Step 5: Commit**
```bash
git add docs/design/04-kafka-confluent-integration-options.md
git commit -m "docs(design-library): rename to 04, curate diagrams from ADR-0031" -- docs/design/04-kafka-confluent-integration-options.md docs/design/ADR-0031-kafka-confluent-integration-options.md
```

---

### Task 4: Rename and diagram-curate — IAM Entra ↔ Power Platform (05)

**Files:**
- Rename: `docs/design/ADR-0032-iam-entra-power-platform-options.md` → `docs/design/05-iam-entra-power-platform-options.md`
- Read-only source: `docs/adr/ADR-0032-entra-power-platform-dynamics365-identity-access-management.md`

- [ ] **Step 1: Rename via git mv**
```bash
git mv docs/design/ADR-0032-iam-entra-power-platform-options.md docs/design/05-iam-entra-power-platform-options.md
```
- [ ] **Step 2: Update H1** — add `05`.
- [ ] **Step 3: Curate diagrams** — read the source ADR in full, apply the criteria, insert 3-5 diagrams verbatim.
- [ ] **Step 4: Verify**
```powershell
Test-Path "docs/design/05-iam-entra-power-platform-options.md"
Test-Path "docs/design/ADR-0032-iam-entra-power-platform-options.md"
Select-String -Path "docs/design/05-iam-entra-power-platform-options.md" -Pattern "^# "
(Select-String -Path "docs/design/05-iam-entra-power-platform-options.md" -Pattern '```mermaid' -AllMatches).Matches.Count
```
Expected: `True`, `False`, H1 = `# Design Pattern 05: <topic>`, mermaid count 3-5.
- [ ] **Step 5: Commit**
```bash
git add docs/design/05-iam-entra-power-platform-options.md
git commit -m "docs(design-library): rename to 05, curate diagrams from ADR-0032" -- docs/design/05-iam-entra-power-platform-options.md docs/design/ADR-0032-iam-entra-power-platform-options.md
```

---

### Task 5: Rename and diagram-curate — CRM UX placement in B2E landscape (06)

**Files:**
- Rename: `docs/design/ADR-0033-crm-ux-placement-options.md` → `docs/design/06-crm-ux-placement-options.md`
- Read-only source: `docs/adr/ADR-0033-crm-ux-placement-in-b2e-landscape.md`

- [ ] **Step 1: Rename via git mv**
```bash
git mv docs/design/ADR-0033-crm-ux-placement-options.md docs/design/06-crm-ux-placement-options.md
```
- [ ] **Step 2: Update H1** — add `06`.
- [ ] **Step 3: Curate diagrams** — read the source ADR in full, apply the criteria, insert 3-5 diagrams verbatim.
- [ ] **Step 4: Verify**
```powershell
Test-Path "docs/design/06-crm-ux-placement-options.md"
Test-Path "docs/design/ADR-0033-crm-ux-placement-options.md"
Select-String -Path "docs/design/06-crm-ux-placement-options.md" -Pattern "^# "
(Select-String -Path "docs/design/06-crm-ux-placement-options.md" -Pattern '```mermaid' -AllMatches).Matches.Count
```
Expected: `True`, `False`, H1 = `# Design Pattern 06: <topic>`, mermaid count 3-5.
- [ ] **Step 5: Commit**
```bash
git add docs/design/06-crm-ux-placement-options.md
git commit -m "docs(design-library): rename to 06, curate diagrams from ADR-0033" -- docs/design/06-crm-ux-placement-options.md docs/design/ADR-0033-crm-ux-placement-options.md
```

---

### Task 6: Rename and diagram-curate — ARO case/task integration (07)

**Files:**
- Rename: `docs/design/ADR-0034-aro-case-task-integration-options.md` → `docs/design/07-aro-case-task-integration-options.md`
- Read-only source: `docs/adr/ADR-0034-aro-case-task-management-integration-pattern.md`

- [ ] **Step 1: Rename via git mv**
```bash
git mv docs/design/ADR-0034-aro-case-task-integration-options.md docs/design/07-aro-case-task-integration-options.md
```
- [ ] **Step 2: Update H1** — add `07`.
- [ ] **Step 3: Curate diagrams** — read the source ADR in full, apply the criteria, insert 3-5 diagrams verbatim.
- [ ] **Step 4: Verify**
```powershell
Test-Path "docs/design/07-aro-case-task-integration-options.md"
Test-Path "docs/design/ADR-0034-aro-case-task-integration-options.md"
Select-String -Path "docs/design/07-aro-case-task-integration-options.md" -Pattern "^# "
(Select-String -Path "docs/design/07-aro-case-task-integration-options.md" -Pattern '```mermaid' -AllMatches).Matches.Count
```
Expected: `True`, `False`, H1 = `# Design Pattern 07: <topic>`, mermaid count 3-5.
- [ ] **Step 5: Commit**
```bash
git add docs/design/07-aro-case-task-integration-options.md
git commit -m "docs(design-library): rename to 07, curate diagrams from ADR-0034" -- docs/design/07-aro-case-task-integration-options.md docs/design/ADR-0034-aro-case-task-integration-options.md
```

---

### Task 7: Rename and diagram-curate — PDV partner master data integration (08)

**Files:**
- Rename: `docs/design/ADR-0035-pdv-partner-master-data-options.md` → `docs/design/08-pdv-partner-master-data-options.md`
- Read-only source: `docs/adr/ADR-0035-pdv-partner-master-data-integration-pattern.md`

- [ ] **Step 1: Rename via git mv**
```bash
git mv docs/design/ADR-0035-pdv-partner-master-data-options.md docs/design/08-pdv-partner-master-data-options.md
```
- [ ] **Step 2: Update H1** — add `08`.
- [ ] **Step 3: Curate diagrams** — read the source ADR in full, apply the criteria, insert 3-5 diagrams verbatim.
- [ ] **Step 4: Verify**
```powershell
Test-Path "docs/design/08-pdv-partner-master-data-options.md"
Test-Path "docs/design/ADR-0035-pdv-partner-master-data-options.md"
Select-String -Path "docs/design/08-pdv-partner-master-data-options.md" -Pattern "^# "
(Select-String -Path "docs/design/08-pdv-partner-master-data-options.md" -Pattern '```mermaid' -AllMatches).Matches.Count
```
Expected: `True`, `False`, H1 = `# Design Pattern 08: <topic>`, mermaid count 3-5.
- [ ] **Step 5: Commit**
```bash
git add docs/design/08-pdv-partner-master-data-options.md
git commit -m "docs(design-library): rename to 08, curate diagrams from ADR-0035" -- docs/design/08-pdv-partner-master-data-options.md docs/design/ADR-0035-pdv-partner-master-data-options.md
```

---

### Task 8: Rename and diagram-curate — Lead/campaign external landscape (09)

**Files:**
- Rename: `docs/design/ADR-0036-crm-lead-campaign-landscape-options.md` → `docs/design/09-crm-lead-campaign-landscape-options.md`
- Read-only source: `docs/adr/ADR-0036-crm-lead-campaign-external-landscape.md`

- [ ] **Step 1: Rename via git mv**
```bash
git mv docs/design/ADR-0036-crm-lead-campaign-landscape-options.md docs/design/09-crm-lead-campaign-landscape-options.md
```
- [ ] **Step 2: Update H1** — add `09`.
- [ ] **Step 3: Curate diagrams** — read the source ADR in full, apply the criteria, insert 3-5 diagrams verbatim.
- [ ] **Step 4: Verify**
```powershell
Test-Path "docs/design/09-crm-lead-campaign-landscape-options.md"
Test-Path "docs/design/ADR-0036-crm-lead-campaign-landscape-options.md"
Select-String -Path "docs/design/09-crm-lead-campaign-landscape-options.md" -Pattern "^# "
(Select-String -Path "docs/design/09-crm-lead-campaign-landscape-options.md" -Pattern '```mermaid' -AllMatches).Matches.Count
```
Expected: `True`, `False`, H1 = `# Design Pattern 09: <topic>`, mermaid count 3-5.
- [ ] **Step 5: Commit**
```bash
git add docs/design/09-crm-lead-campaign-landscape-options.md
git commit -m "docs(design-library): rename to 09, curate diagrams from ADR-0036" -- docs/design/09-crm-lead-campaign-landscape-options.md docs/design/ADR-0036-crm-lead-campaign-landscape-options.md
```

---

### Task 9: Rename and diagram-curate — Environment strategy B2B/B2C (10)

**Files:**
- Rename: `docs/design/ADR-0037-environment-strategy-options.md` → `docs/design/10-environment-strategy-options.md`
- Read-only source: `docs/adr/ADR-0037-power-platform-environment-strategy-b2b-b2c.md`

- [ ] **Step 1: Rename via git mv**
```bash
git mv docs/design/ADR-0037-environment-strategy-options.md docs/design/10-environment-strategy-options.md
```
- [ ] **Step 2: Update H1** — add `10`.
- [ ] **Step 3: Curate diagrams** — read the source ADR in full, apply the criteria, insert 3-5 diagrams verbatim.
- [ ] **Step 4: Verify**
```powershell
Test-Path "docs/design/10-environment-strategy-options.md"
Test-Path "docs/design/ADR-0037-environment-strategy-options.md"
Select-String -Path "docs/design/10-environment-strategy-options.md" -Pattern "^# "
(Select-String -Path "docs/design/10-environment-strategy-options.md" -Pattern '```mermaid' -AllMatches).Matches.Count
```
Expected: `True`, `False`, H1 = `# Design Pattern 10: <topic>`, mermaid count 3-5.
- [ ] **Step 5: Commit**
```bash
git add docs/design/10-environment-strategy-options.md
git commit -m "docs(design-library): rename to 10, curate diagrams from ADR-0037" -- docs/design/10-environment-strategy-options.md docs/design/ADR-0037-environment-strategy-options.md
```

---

### Task 10: Rename and diagram-curate — Purview compliance (11)

**Files:**
- Rename: `docs/design/ADR-0038-purview-compliance-options.md` → `docs/design/11-purview-compliance-options.md`
- Read-only source: `docs/adr/ADR-0038-purview-power-platform-dynamics365-compliance.md`

- [ ] **Step 1: Rename via git mv**
```bash
git mv docs/design/ADR-0038-purview-compliance-options.md docs/design/11-purview-compliance-options.md
```
- [ ] **Step 2: Update H1** — add `11`.
- [ ] **Step 3: Curate diagrams** — read the source ADR in full, apply the criteria, insert 3-5 diagrams verbatim.
- [ ] **Step 4: Verify**
```powershell
Test-Path "docs/design/11-purview-compliance-options.md"
Test-Path "docs/design/ADR-0038-purview-compliance-options.md"
Select-String -Path "docs/design/11-purview-compliance-options.md" -Pattern "^# "
(Select-String -Path "docs/design/11-purview-compliance-options.md" -Pattern '```mermaid' -AllMatches).Matches.Count
```
Expected: `True`, `False`, H1 = `# Design Pattern 11: <topic>`, mermaid count 3-5.
- [ ] **Step 5: Commit**
```bash
git add docs/design/11-purview-compliance-options.md
git commit -m "docs(design-library): rename to 11, curate diagrams from ADR-0038" -- docs/design/11-purview-compliance-options.md docs/design/ADR-0038-purview-compliance-options.md
```

---

### Task 11: Rename and diagram-curate — DevSecOps CI/CD (12)

**Files:**
- Rename: `docs/design/ADR-0039-devsecops-cicd-options.md` → `docs/design/12-devsecops-cicd-options.md`
- Read-only source: `docs/adr/ADR-0039-devsecops-cicd-github-enterprise-vs-gitlab.md`

- [ ] **Step 1: Rename via git mv**
```bash
git mv docs/design/ADR-0039-devsecops-cicd-options.md docs/design/12-devsecops-cicd-options.md
```
- [ ] **Step 2: Update H1** — add `12`.
- [ ] **Step 3: Curate diagrams** — read the source ADR in full, apply the criteria, insert 3-5 diagrams verbatim.
- [ ] **Step 4: Verify**
```powershell
Test-Path "docs/design/12-devsecops-cicd-options.md"
Test-Path "docs/design/ADR-0039-devsecops-cicd-options.md"
Select-String -Path "docs/design/12-devsecops-cicd-options.md" -Pattern "^# "
(Select-String -Path "docs/design/12-devsecops-cicd-options.md" -Pattern '```mermaid' -AllMatches).Matches.Count
```
Expected: `True`, `False`, H1 = `# Design Pattern 12: <topic>`, mermaid count 3-5.
- [ ] **Step 5: Commit**
```bash
git add docs/design/12-devsecops-cicd-options.md
git commit -m "docs(design-library): rename to 12, curate diagrams from ADR-0039" -- docs/design/12-devsecops-cicd-options.md docs/design/ADR-0039-devsecops-cicd-options.md
```

---

### Task 12: Update `docs/design/README.md` index (run only after Tasks 1-11 are all committed)

**Files:**
- Modify: `docs/design/README.md`

- [ ] **Step 1: Read the current file and replace the index table**

The current table (verified 2026-08-17) reads:

```text
| # | Pattern | Related ADR |
| --- | --- | --- |
| 00 | [Frontier Firm operating model for insurance](./00-frontier-firm-operating-model-for-insurance.md) | `docs/FRONTIER-OPERATING-MODEL.md` |
| ADR-0019 | [Insurance data model shape](./ADR-0019-insurance-data-model-options.md) | [ADR-0019](../adr/ADR-0019-provisional-insurance-data-model-shape.md) |
| — | [Insurance data model extension (implementation detail)](./contoso-insurance-data-model-extension.md) | [ADR-0019](../adr/ADR-0019-provisional-insurance-data-model-shape.md) |
| ADR-0030 | [Dataverse to Databricks integration](./ADR-0030-dataverse-databricks-integration-options.md) | [ADR-0030](../adr/ADR-0030-dataverse-to-databricks-integration-pattern.md) |
| ADR-0031 | [CRM to core-systems Kafka/Confluent integration](./ADR-0031-kafka-confluent-integration-options.md) | [ADR-0031](../adr/ADR-0031-crm-core-systems-kafka-confluent-integration-pattern.md) |
| ADR-0032 | [Identity and access management (Entra to Power Platform)](./ADR-0032-iam-entra-power-platform-options.md) | [ADR-0032](../adr/ADR-0032-entra-power-platform-dynamics365-identity-access-management.md) |
| ADR-0033 | [CRM UX placement in the B2E landscape](./ADR-0033-crm-ux-placement-options.md) | [ADR-0033](../adr/ADR-0033-crm-ux-placement-in-b2e-landscape.md) |
| ADR-0034 | [ARO case/task management integration](./ADR-0034-aro-case-task-integration-options.md) | [ADR-0034](../adr/ADR-0034-aro-case-task-management-integration-pattern.md) |
| ADR-0035 | [PDV partner master data integration](./ADR-0035-pdv-partner-master-data-options.md) | [ADR-0035](../adr/ADR-0035-pdv-partner-master-data-integration-pattern.md) |
| ADR-0036 | [Lead and campaign external landscape](./ADR-0036-crm-lead-campaign-landscape-options.md) | [ADR-0036](../adr/ADR-0036-crm-lead-campaign-external-landscape.md) |
| ADR-0037 | [Power Platform environment strategy (B2B/B2C)](./ADR-0037-environment-strategy-options.md) | [ADR-0037](../adr/ADR-0037-power-platform-environment-strategy-b2b-b2c.md) |
| ADR-0038 | [Purview compliance for Power Platform/Dynamics 365](./ADR-0038-purview-compliance-options.md) | [ADR-0038](../adr/ADR-0038-purview-power-platform-dynamics365-compliance.md) |
| ADR-0039 | [DevSecOps CI/CD operating model](./ADR-0039-devsecops-cicd-options.md) | [ADR-0039](../adr/ADR-0039-devsecops-cicd-github-enterprise-vs-gitlab.md) |
```

Replace it with (only the `#` column and the pattern-doc link paths change — the pattern names, the `Related ADR` column, and the extension-doc row are unchanged):

```text
| # | Pattern | Related ADR |
| --- | --- | --- |
| 00 | [Frontier Firm operating model for insurance](./00-frontier-firm-operating-model-for-insurance.md) | `docs/FRONTIER-OPERATING-MODEL.md` |
| 02 | [Insurance data model shape](./02-insurance-data-model-options.md) | [ADR-0019](../adr/ADR-0019-provisional-insurance-data-model-shape.md) |
| — | [Insurance data model extension (implementation detail)](./contoso-insurance-data-model-extension.md) | [ADR-0019](../adr/ADR-0019-provisional-insurance-data-model-shape.md) |
| 03 | [Dataverse to Databricks integration](./03-dataverse-databricks-integration-options.md) | [ADR-0030](../adr/ADR-0030-dataverse-to-databricks-integration-pattern.md) |
| 04 | [CRM to core-systems Kafka/Confluent integration](./04-kafka-confluent-integration-options.md) | [ADR-0031](../adr/ADR-0031-crm-core-systems-kafka-confluent-integration-pattern.md) |
| 05 | [Identity and access management (Entra to Power Platform)](./05-iam-entra-power-platform-options.md) | [ADR-0032](../adr/ADR-0032-entra-power-platform-dynamics365-identity-access-management.md) |
| 06 | [CRM UX placement in the B2E landscape](./06-crm-ux-placement-options.md) | [ADR-0033](../adr/ADR-0033-crm-ux-placement-in-b2e-landscape.md) |
| 07 | [ARO case/task management integration](./07-aro-case-task-integration-options.md) | [ADR-0034](../adr/ADR-0034-aro-case-task-management-integration-pattern.md) |
| 08 | [PDV partner master data integration](./08-pdv-partner-master-data-options.md) | [ADR-0035](../adr/ADR-0035-pdv-partner-master-data-integration-pattern.md) |
| 09 | [Lead and campaign external landscape](./09-crm-lead-campaign-landscape-options.md) | [ADR-0036](../adr/ADR-0036-crm-lead-campaign-external-landscape.md) |
| 10 | [Power Platform environment strategy (B2B/B2C)](./10-environment-strategy-options.md) | [ADR-0037](../adr/ADR-0037-power-platform-environment-strategy-b2b-b2c.md) |
| 11 | [Purview compliance for Power Platform/Dynamics 365](./11-purview-compliance-options.md) | [ADR-0038](../adr/ADR-0038-purview-power-platform-dynamics365-compliance.md) |
| 12 | [DevSecOps CI/CD operating model](./12-devsecops-cicd-options.md) | [ADR-0039](../adr/ADR-0039-devsecops-cicd-github-enterprise-vs-gitlab.md) |
```

Note: a `01` row for Phase 2's future use-case doc is intentionally **not** added yet — that happens when Phase 2 is built, not in this task.

- [ ] **Step 2: Verify**

```powershell
Select-String -Path "docs/design/README.md" -Pattern "ADR-00(19|30|31|32|33|34|35|36|37|38|39)-"
```
Expected: no matches in the `#`/pattern-link columns (the `Related ADR` column's links to `../adr/ADR-00NN-*.md` are unaffected and will still match this pattern legitimately — confirm any remaining matches are only inside `../adr/` links, not `./`-relative pattern-doc links).

- [ ] **Step 3: Commit**

```bash
git add docs/design/README.md
git commit -m "docs(design-library): update index for renumbered pattern docs" -- docs/design/README.md
```

---

### Task 13: Update `docs/FRONTIER-OPERATING-MODEL.md` §10 deliverables table (run only after Tasks 1-11 are all committed)

**Files:**
- Modify: `docs/FRONTIER-OPERATING-MODEL.md`

- [ ] **Step 1: Update the filename list in the deliverables table**

Find the row (in §10 "Deliverables", currently around line 360) that lists:
```text
`docs/design/ADR-0019-insurance-data-model-options.md`, `ADR-0030-dataverse-databricks-integration-options.md`, `ADR-0031-kafka-confluent-integration-options.md`, `ADR-0032-iam-entra-power-platform-options.md`, `ADR-0033-crm-ux-placement-options.md`, `ADR-0034-aro-case-task-integration-options.md`, `ADR-0035-pdv-partner-master-data-options.md`, `ADR-0036-crm-lead-campaign-landscape-options.md`, `ADR-0037-environment-strategy-options.md`, `ADR-0038-purview-compliance-options.md`, `ADR-0039-devsecops-cicd-options.md`
```
Replace with:
```text
`docs/design/02-insurance-data-model-options.md`, `03-dataverse-databricks-integration-options.md`, `04-kafka-confluent-integration-options.md`, `05-iam-entra-power-platform-options.md`, `06-crm-ux-placement-options.md`, `07-aro-case-task-integration-options.md`, `08-pdv-partner-master-data-options.md`, `09-crm-lead-campaign-landscape-options.md`, `10-environment-strategy-options.md`, `11-purview-compliance-options.md`, `12-devsecops-cicd-options.md`
```
Only this row's content changes — nothing else in §10 or the rest of the file.

- [ ] **Step 2: Verify**

```powershell
Select-String -Path "docs/FRONTIER-OPERATING-MODEL.md" -Pattern "docs/design/ADR-00"
```
Expected: no matches.

- [ ] **Step 3: Commit**

```bash
git add docs/FRONTIER-OPERATING-MODEL.md
git commit -m "docs(design-library): update deliverables table for renumbered pattern docs" -- docs/FRONTIER-OPERATING-MODEL.md
```

---

### Task 14: Final whole-library verification (run after Tasks 1-13)

**Files:** read-only checks across `docs/design/`, `docs/FRONTIER-OPERATING-MODEL.md`, `docs/adr/`

- [ ] **Step 1: Confirm no old ADR-prefixed design-doc filenames remain**

```powershell
Get-ChildItem "docs/design" -Filter "ADR-00*.md"
```
Expected: no output (empty list).

- [ ] **Step 2: Confirm all 11 new files exist**

```powershell
$files = @("02-insurance-data-model-options.md","03-dataverse-databricks-integration-options.md","04-kafka-confluent-integration-options.md","05-iam-entra-power-platform-options.md","06-crm-ux-placement-options.md","07-aro-case-task-integration-options.md","08-pdv-partner-master-data-options.md","09-crm-lead-campaign-landscape-options.md","10-environment-strategy-options.md","11-purview-compliance-options.md","12-devsecops-cicd-options.md")
foreach ($f in $files) { Test-Path "docs/design/$f" }
```
Expected: `True` × 11.

- [ ] **Step 3: Confirm every H1 has its correct number**

```powershell
foreach ($f in $files) { Select-String -Path "docs/design/$f" -Pattern "^# Design Pattern \d\d:" }
```
Expected: 11 matches, one per file, each with the correct number from the mapping table in the spec.

- [ ] **Step 4: Confirm no repo-wide stray references to old filenames remain (outside the 2 historical exceptions)**

```powershell
Select-String -Path "docs/**/*.md" -Pattern "docs/design/ADR-00(19|30|31|32|33|34|35|36|37|38|39)-|\./ADR-00(19|30|31|32|33|34|35|36|37|38|39)-" | Where-Object { $_.Path -notmatch "specs\\2026-08-16|plans\\2026-08-16" }
```
Expected: no output. (If the filter doesn't catch a nested path variant, manually confirm any remaining hits are only inside `docs/superpowers/specs/2026-08-16-frontier-operating-model-design.md` or `docs/superpowers/plans/2026-08-16-frontier-operating-model.md`.)

- [ ] **Step 5: Confirm each design doc's diagram count is in the 3-5 band and each diagram is a verbatim match to its source ADR**

For each of the 11 files, read the design-pattern doc and its source ADR side by side. Confirm every Mermaid code block in the design doc appears character-for-character somewhere in its source ADR (copy-paste verbatim, not retyped/paraphrased). Record any mismatch.

- [ ] **Step 6: Confirm `docs/design/README.md` and `docs/FRONTIER-OPERATING-MODEL.md` have zero remaining old-filename references**

```powershell
Select-String -Path "docs/design/README.md" -Pattern "ADR-00(19|30|31|32|33|34|35|36|37|38|39)-insurance|ADR-00(19|30|31|32|33|34|35|36|37|38|39)-dataverse|ADR-00(19|30|31|32|33|34|35|36|37|38|39)-kafka|ADR-00(19|30|31|32|33|34|35|36|37|38|39)-iam|ADR-00(19|30|31|32|33|34|35|36|37|38|39)-crm|ADR-00(19|30|31|32|33|34|35|36|37|38|39)-aro|ADR-00(19|30|31|32|33|34|35|36|37|38|39)-pdv|ADR-00(19|30|31|32|33|34|35|36|37|38|39)-environment|ADR-00(19|30|31|32|33|34|35|36|37|38|39)-purview|ADR-00(19|30|31|32|33|34|35|36|37|38|39)-devsecops"
Select-String -Path "docs/FRONTIER-OPERATING-MODEL.md" -Pattern "docs/design/ADR-00"
```
Expected: no output for either.

- [ ] **Step 7: Fix anything found, then final commit only if fixes were needed**

```bash
git add -A docs/design/ docs/FRONTIER-OPERATING-MODEL.md
git commit -m "docs(design-library): fix issues found in final verification pass"
```
Skip this commit if Steps 1-6 found no issues.
