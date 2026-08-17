# Mobiliar demo curveballs → Advisor Cockpit fixture enrichment map

Source: `../ideas/Mobiliar - Demo Curveballs & Architecture.html`, 8 concrete
demo scenarios. Cross-checked against the current fixtures under
[`data/scenarios/advisor-cockpit/`](../../../data/scenarios/advisor-cockpit/)
(read 2026-08-17: `accounts-contacts.json`, `leads.json`, `policies.json`,
`claims.json`, `activities.json`). This is the input Task 5
(`fixture-enrichment`, issue #130) implements against — it stays within the
7 existing fixture files and their existing shapes; no new entity type, no
schema change (per the sprint-004 design spec's guardrail).

| # | Curveball | Currently reflected? | Concrete enrichment recommendation |
| --- | --- | --- | --- |
| 1 | Cross-canton change of address — multi-line cascade | Partially — `ANL-204902` ("Adressänderung", `ACC-BRUNNER`, Anliegen) exists, but Brunner only has **one** policy (`POL-HR-BRUNNER`, Hausrat), so the "cascade across several policies" effect has nothing to ripple into. | Add 1-2 more policies to `ACC-BRUNNER` using existing valid `crmshow_productline` options (e.g. `MotorVehicle` and `LegalProtection` — see the schema note below) so the existing address-change case visibly touches a multi-line portfolio, matching the golden thread (`docs/ideas/UC-01-relocation-across-jurisdictions/`). |
| 2 | Building insurance — monopoly vs. free market (jurisdiction-driven eligibility) | **Not reflected, and not safely implementable in this sprint** — see schema note below. | ~~Add a `BuildingInsurance` policy~~ **Blocked:** `crmshow_productline` is a closed `GlobalChoice` with exactly 5 options (`MotorVehicle`, `HouseholdContents`, `CommercialProperty`, `Pension3a`, `LegalProtection` — `solution/schema/insurance-foundation.json`, ~line 243); `BuildingInsurance` is not one of them. Adding a 6th option is a data-model/schema change requiring an ADR per this repo's own rule ("change to the data model" → ADR), not a fixture-only change — out of scope for `fixture-enrichment` (issue #130). Filed as a follow-up recommendation for a future sprint/ADR rather than worked around here. |
| 3 | General Agency reassignment on the move | Not reflected — no ownership-transfer or GA-handover artefact exists. | Add a `task` activity such as "GA-Übergabe vorbereiten" or "Zuständigkeit prüfen nach Umzug" tied to a relocating household account, reflecting ADR-0013 territory/ownership without requiring an actual ownership-transfer data model (out of scope for this sprint). |
| 4 | Motor-vehicle re-rating triggers | Partially — `POL-MF-AEBISCHER` (fleet) and `POL-MF-IMHOF` exist, but no re-rating trigger event (new driver, object change) is modeled. | Add a `lead` or `task` such as "Neuwagen gemeldet — Neubewertung Flotte" tied to `ACC-AEBISCHER`, or a `claims.json`/Anliegen row for a vehicle-change notification. |
| 5 | Life-event triggers (household change → cross-policy re-evaluation) | Not reflected. | Add a `lead` such as "Familienzuwachs — Vorsorge & Haftpflicht prüfen" tied to one of the household accounts (e.g. `ACC-KELLER`, which already has an open Vorsorge 3a lead — a life-event angle fits naturally). |
| 6 | Property/object changes (sum-insured & exposure shifts) | Not reflected — `POL-HR-BRUNNER` (Hausrat) has no sum-insured-review context. | Add a `claims.json` Anliegen row such as "Renovation gemeldet — Hausrat-Summe anpassen" tied to `ACC-BRUNNER`'s existing Hausrat policy. |
| 7 | Bundle & discount unwinding (portfolio-aware pricing) | Partially — `POL-RS-ROTH` (Rechtsschutz) already has `status: "Ablauf"` (expiring), but `ACC-ROTH` has only that one policy, so there is no bundle/discount to unwind. | Add a second policy to `ACC-ROTH` using the existing `HouseholdContents` option (Hausrat) so the existing expiring Rechtsschutz line visibly demonstrates a portfolio-aware discount-recalculation scenario when it lapses. |
| 8 | Shared phone / data-quality ambiguity (identity resolution) | Not reflected — every contact in `accounts-contacts.json` has a distinct phone number today. | Add a `task` such as "Datenqualität: Telefonnummer-Duplikat prüfen" (AG-F-05 Data-Quality & Identity-Resolution Agent), or — if a low-risk way is found to model it — two contacts sharing one phone number across two household accounts. Prefer the task-only approach: creating an actual ambiguous duplicate contact risks confusing the demo rather than illustrating the point cleanly. |

## Not fixture-relevant (already covered elsewhere)

The curveball document's two contact-center integration patterns (GA Sales
Hub Dialer, Mobi24/Luware Nimbus contact center) and the "coexistence
watch-outs" section are voice/telephony architecture, not Advisor Cockpit
data — already reflected in ADR-0015 (voice-channel-boundary) and ADR-0016
(governed-outbound). No fixture change recommended.

## Schema constraint discovered while validating this map (2026-08-17)

`crmshow_productline` (used by `policies.json`'s `productLine` field once
that fixture is eventually wired into the seed script) is a closed
`GlobalChoice` with exactly 5 options: `MotorVehicle`, `HouseholdContents`,
`CommercialProperty`, `Pension3a`, `LegalProtection` — see
`solution/schema/insurance-foundation.json`. There is no `BuildingInsurance`
option. Curveball #2's original recommendation (add a building-insurance
policy) is therefore revised above to explicitly flag it as **not
implementable as a fixture-only change** — it needs a schema change (a 6th
choice option) and an ADR, which is out of scope for `fixture-enrichment`
(issue #130). All other recommendations above use only the 5 existing
options.

## Priority for Task 5

If only a subset can be done in one pass, curveballs **#1 (Brunner
multi-line cascade)** and **#7 (bundle unwinding on Roth)** are the
highest-value, schema-safe enrichments — both use only the already-defined
`crmshow_productline` options and directly strengthen scenarios the fixtures
already half-tell.
