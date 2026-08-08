# Sprint 2 - Mobiliar Prototype Intake and Data-Model Baseline

| Field | Value |
| --- | --- |
| Status | Approved for implementation |
| Date | 2026-08-08 |
| Source | Mobiliar rapid-prototype solution in an isolated demo environment |
| Target | CRM Frontier Firm Showcase development lifecycle |
| Owners | AG-E-03 Enterprise Architect, AG-E-08 Dataverse Modeler |
| Related | ADR-0006 through ADR-0010, ADR-0017, ADR-0019 |
| Licence | Configuration and own build; individual imported capabilities require separate review |
| Upgrade impact | Discovery only. No source component is deployed or adopted by this sprint. |

## Purpose

Preserve the Mobiliar RFP prototype as inspectable evidence, inventory its
solution artefacts, map them to CRM Showcase domains, and define the target
data-model extensions required to rebuild useful capabilities within the
governed CRM Showcase architecture.

The prototype is an input to analysis, not the target architecture. No source
component is imported into CRM Showcase DEV during this sprint.

## Success criteria

- The unmanaged source solution is exported and reproducibly unpacked.
- The committed intake snapshot contains no records, credentials, tokens,
  connection values, real customer content, or source-environment identifiers.
- Every exported root component is represented in a machine-readable BOM.
- Data-model artefacts include tables, columns, keys, relationships, choices,
  forms, views, and business processes where present.
- Every BOM item has a domain, target solution container, review disposition,
  and rationale.
- The data-model design identifies reuse, extension, redesign, and retirement
  decisions against the CRM Showcase principles and ADRs.
- A GitHub feature issue links the design, implementation plan, BOM, domain
  map, and data-model design.

## Non-goals

- Exporting or migrating Dataverse records.
- Importing the Mobiliar solution into CRM Showcase DEV or TEST.
- Preserving the source publisher or schema prefix in the target model.
- Rebuilding apps, flows, plug-ins, or integrations in this sprint.
- Treating prototype behaviour as an approved requirement.
- Resolving licensing or maturity for every capability; unresolved items are
  flagged for review.

## Options considered

### Directly import and refactor

Fast initially, but it would contaminate the target environment with the
prototype publisher, schema, dependencies, and design assumptions. Rejected.

### Metadata-only discovery

Querying Dataverse metadata avoids handling an export, but it misses important
implementation content and package dependencies. Rejected as incomplete.

### Quarantined export plus metadata enrichment

Export the complete unmanaged solution, unpack it outside the deployable
`solution/` tree, scan and sanitize it, then generate the BOM and design
outputs. Selected metadata queries may enrich details that the package does not
express clearly. Chosen.

## Architecture and repository boundaries

The source snapshot is isolated from deployable solutions:

```text
intake/
  mobiliar/
    README.md
    source/                  sanitized unpacked source snapshot
    bom/
      artefacts.json         canonical machine-readable inventory
      artefacts.csv          tabular review format
      README.md              counts, coverage, and limitations
    mappings/
      domain-map.csv         domain, target container, disposition, rationale

docs/
  design/
    mobiliar-data-model-extension.md
```

The raw ZIP and temporary extraction remain outside Git. Only the sanitized,
unpacked snapshot and derived review artefacts may be committed. The deploy
workflows continue to read only `solution/manifest.json`; therefore nothing
under `intake/` can be packed or deployed accidentally.

## Intake flow

1. Authenticate interactively to the isolated source demo environment.
2. Verify the connected organization before export.
3. Export the unmanaged `Mobiliar` solution to session-local temporary storage.
4. Unpack it with Power Platform CLI.
5. Scan text and package metadata for credentials, connection values,
   environment identifiers, URLs, email addresses, phone-like values, and
   customer content.
6. Remove environment-variable current values and other environment-bound
   configuration from the commit candidate. If customer content is detected,
   exclude the affected artefact and record the exclusion in the BOM.
7. Copy the sanitized snapshot into `intake/mobiliar/source/`.
8. Parse solution metadata and unpacked component folders into the BOM.
9. Map each BOM item to a domain, target container, and disposition.
10. Produce the target data-model extension design and review backlog.

The export script must accept an explicit environment URL or environment ID and
must verify `pac org who` before exporting. It must not depend silently on the
currently active `pac` profile.

## BOM model

Each item contains:

| Field | Meaning |
| --- | --- |
| `componentType` | Dataverse component category |
| `logicalName` | Stable logical or unique name |
| `displayName` | Source label where available |
| `sourcePath` | Relative path in the sanitized snapshot |
| `parent` | Owning table, app, process, or assembly |
| `dependencies` | Referenced component identifiers where discoverable |
| `domain` | CRM Showcase business or platform domain |
| `targetSolution` | Foundation, DataModel, Integration, Sales, Service, Marketing, or None |
| `disposition` | Reuse, Refactor, Redesign, Retire, or Investigate |
| `rationale` | Reviewable reason for the disposition |
| `licenceReview` | Required, Not required, or Investigate |
| `maturityReview` | Required, Not required, or Investigate |
| `sourceOnly` | True when retained only as prototype evidence |

The inventory covers all package root components and expands data-model
components to their relevant child artefacts.

## Domain taxonomy

- Foundation and shared configuration
- Party, household, and relationship
- Sales and opportunity management
- Service and case management
- Marketing, consent, and journeys
- Policy, claim, quote, and insured-object projections
- Integration and automation
- Analytics and reporting
- Security, governance, and administration
- AI and agent-assisted capabilities
- Unclassified pending review

## Disposition rules

- **Reuse**: native component or configuration already aligned with target
  principles; target implementation still uses the CRM Showcase publisher.
- **Refactor**: useful capability with acceptable semantics but unsuitable
  packaging, naming, ownership, or coupling.
- **Redesign**: capability is valuable but conflicts with a target ADR, domain
  boundary, data ownership rule, or security baseline.
- **Retire**: duplicate, obsolete, prototype-only, or unsupported capability.
- **Investigate**: insufficient evidence for a safe decision.

No artefact is automatically classified as Reuse solely because it exists in
the prototype.

## Target data-model design rules

- Account remains the centre of gravity with Household, Business, and Broker
  account types.
- Portfolio records attach to Account, never Contact.
- Contact participates through explicit, effective-dated roles.
- Policy, claim, and quote are thin projections with external system and
  external reference keys.
- Consent is per contact and channel with source and capture date.
- Lead represents interest by an existing person and qualifies only to
  Opportunity.
- Common Data Model and native Dataverse tables are evaluated before custom
  tables.
- Source prefixes and table names do not determine target names.
- Every proposed table states mastership, sensitivity, lifecycle, owner,
  integration boundary, and target solution.
- Agents remain advisory; model output cannot write directly to Dataverse.

## Error handling and evidence

- Abort if the connected organization is not the intended source.
- Abort if the source solution cannot be found or exported.
- Preserve CLI logs and hashes in session-local storage; do not commit
  authentication or environment details.
- Fail BOM generation when a root component is unaccounted for.
- Record unsupported component types as `Investigate`; never silently omit
  them.
- Block commit when secret or personal-data scans find unresolved matches.

## Verification

- Repack the sanitized snapshot as an unmanaged solution in temporary storage
  to verify structural integrity where sanitization did not intentionally
  exclude a component.
- Reconcile BOM root-component counts with `Solution.xml`.
- Validate JSON and CSV outputs and require deterministic regeneration.
- Run repository secret scanning and targeted personal-data pattern checks.
- Confirm `solution/manifest.json` and the six deployable solution folders are
  unchanged.
- Review the data-model delta against ADR-0006 through ADR-0010 and DP-17
  CDM-first reuse.

## Sprint deliverables

1. Reproducible source export and sanitization procedure.
2. Sanitized unpacked source snapshot.
3. Machine-readable and reviewable BOM.
4. Domain, target-container, and disposition mapping.
5. CRM Showcase data-model extension design.
6. Follow-up backlog grouped into reviewable delivery slices.
7. GitHub feature issue linking all evidence.

## Framework alignment

- **CAF**: Adopt and Govern through controlled discovery and traceable
  modernization decisions.
- **WAF**: Operational Excellence through reproducible inventory; Security
  through quarantine and scanning; Reliability through dependency evidence.
- **Zero Trust**: explicit source verification, least-privileged export, no
  credential persistence, and strict source/target isolation.
- **Responsible AI**: AI artefacts are inventory-only until maturity,
  licensing, grounding, safety, transparency, and accountability reviews are
  complete.
