# Mobiliar prototype — BOM cross-reference

**Not a second component inventory.** See
[`../README.md`](../README.md#key-finding--this-is-the-same-underlying-export-already-governed-as-intake-contoso-insurance)
for the full finding: this folder's raw export produces a byte-identical
component inventory (by count and by `componentType|logicalName|parent` key)
to the one already published and domain-mapped at
[`intake/contoso-insurance/bom/`](../../contoso-insurance/bom/), except for
21 `Bot`/`BotComponent` rows whose `logicalName` differs only by which
customer name it carries.

## Verification (reproducible)

```powershell
. scripts/solution/New-SolutionBom.ps1
$items = New-SolutionBom -SourceFolder intake/mobiliar/source -MetadataModelFolder intake/mobiliar/.raw/model
$mapping = Import-Csv intake/contoso-insurance/mappings/domain-map.csv
$mappingByKey = @{}
foreach ($row in $mapping) { $mappingByKey["$($row.componentType)|$($row.logicalName)|$($row.parent)"] = $row }
$missing = @($items | Where-Object { -not $mappingByKey.ContainsKey("$($_.componentType)|$($_.logicalName)|$($_.parent)") })
"$($items.Count) items total; $($missing.Count) unmatched against the contoso-insurance domain-map."
```

**Result (2026-08-17):** 941 items total; 21 unmatched — all `Bot` (1) and
`BotComponent` (20: `.gpt.default`, `.settings.Ivr`, and 18 `.topic.*`
components) rows. Every one of the 920 matched items already carries a
reviewed `domain`, `targetSolution`, `disposition`, `rationale`,
`licenceReview`, and `maturityReview` in
[`intake/contoso-insurance/mappings/domain-map.csv`](../../contoso-insurance/mappings/domain-map.csv) —
re-authoring that analysis here would duplicate it, not add to it.

## The 21-item diff (generalized — real customer name never committed)

| componentType | logicalName pattern (customer name replaced with `[CUSTOMER]`) | Already-governed contoso-insurance counterpart |
| --- | --- | --- |
| Bot | `cr7e8_[CUSTOMER]` | `cr7e8_ContosoInsurance` |
| BotComponent | `cr7e8_[CUSTOMER].gpt.default` | `cr7e8_ContosoInsurance.gpt.default` |
| BotComponent | `cr7e8_[CUSTOMER].settings.Ivr` | `cr7e8_ContosoInsurance.settings.Ivr` |
| BotComponent | `cr7e8_[CUSTOMER].topic.*` (18 topics: AnsweringMachineDetection, ConversationStart, EndofConversation, Escalate, Fallback, Greeting, Goodbye, and 11 more) | `cr7e8_ContosoInsurance.topic.*` (same 18 topic names) |

Every row shares the same already-published classification: domain `AI and
agent-assisted capabilities`, target solution `None`, disposition
`Investigate`, rationale "Prototype agent evidence only; requires
Responsible AI, grounding, safety, licensing, and maturity review.",
`licenceReview` and `maturityReview` both `Required` — identical to their
`contoso-insurance` counterparts in every field except the customer-carrying
name. No new disposition decision is needed for this stream; the existing
one already applies.

## Files

- This `README.md` is the cross-reference record for this folder.
- The canonical, machine-readable BOM + domain map remain
  [`intake/contoso-insurance/bom/`](../../contoso-insurance/bom/) and
  [`intake/contoso-insurance/mappings/domain-map.csv`](../../contoso-insurance/mappings/domain-map.csv).
- [`../mappings/curveball-to-fixture-map.md`](../mappings/curveball-to-fixture-map.md)
  is this folder's own, non-duplicate contribution: concrete Advisor Cockpit
  fixture enrichments derived from `ideas/Mobiliar - Demo Curveballs &
  Architecture.html`.
