# Mobiliar prototype intake

This folder contains review artefacts derived from a local, unpacked snapshot
of the Mobiliar rapid prototype.

## Boundary

- Evidence only: nothing in this folder is deployable.
- No Dataverse records are exported or stored here.
- Raw solution ZIP files and scan logs remain in ignored `.raw/` and `.scan/`
  folders.
- The source snapshot remains local and ignored because this repository is
  public and the exported web resources contain customer-branded content,
  email-like values, and source-environment identifiers.
- Only sanitized structural metadata, counts, classifications, and design
  decisions may be committed.
- Source components are reviewed and redesigned under the CRM Showcase
  publisher; they are never copied automatically into `solution/`.

## Regeneration

1. Export with `scripts/solution/Export-Solution.ps1`, specifying the source
   environment and expected organization explicitly.
2. Unpack locally to the ignored `intake/mobiliar/source/` folder with
   `scripts/solution/Unpack-Solution.ps1`.
3. Validate with `scripts/solution/Test-IntakeSnapshot.ps1`.
4. Generate the BOM with `scripts/solution/New-SolutionBom.ps1`.

The governing design is
[`docs/superpowers/specs/2026-08-08-mobiliar-prototype-intake-design.md`](../../docs/superpowers/specs/2026-08-08-mobiliar-prototype-intake-design.md).
