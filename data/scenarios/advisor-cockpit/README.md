# Advisor Cockpit — scenario fixtures

**Synthetic data only.** No real customer identity, policy, or claims data — see
[SUPERPOWERS_CONTRACT.md](../../../SUPERPOWERS_CONTRACT.md) §1 rule 3. The carrier
is the fictional **Contoso Insurance**; the illustrated GA is **Bern-Mittelland**
(advisor _Rahel Moser_). Household and SMB names are invented; e-mail addresses use
the reserved `.example` domain (RFC 2606) and phone numbers use a `555` fictional
marker so no value can collide with a real person.

These fixtures reproduce the Advisor Cockpit + Sales Leader Dashboard mockups as the
seed for local PCF development (Phase 7/8) and for the pipeline-loaded Dataverse
scenario (loaded by [`seed-advisor-cockpit.ps1`](../../../scripts/solution/seed-advisor-cockpit.ps1)).

| Fixture | Feeds | Target entity (provisional) |
| --- | --- | --- |
| `measures.json` | Sales Leader Dashboard KPIs, scorecard, forecast, product/region drill | `crmshow_measuresnapshot` (validates against the Phase-4 contract) |
| `accounts-contacts.json` | Households / businesses + primary contacts (consent per channel) | `account` · `contact` |
| `leads.json` | Lead queue + Brunner lead cluster | `lead` |
| `activities.json` | Termine heute + offene Aufgaben | `appointment` · `task` |
| `nba.json` | Copilot Next-Best-Action cards + provenance | `crmshow_nextbestaction` · `crmshow_nbaprovenance` |
| `policies.json` | Portfolio projections (external reference keys) | `crmshow_policyprojection` |
| `claims.json` | Anliegen & Schäden | `crmshow_claimprojection` |

`measures.json` is the analytics projection (materialized-projection pattern,
[ADR-0026](../../../docs/adr/ADR-0026-inbound-analytics-projection-pattern.md)) and
validates against
[`api/advisor-cockpit/measure-snapshot.schema.json`](../../../api/advisor-cockpit/measure-snapshot.schema.json).
KPI numbers (Zielerreichung 96 %, Wachstum YoY 7.2 %, NPS 42, Automation 72 %,
Forecast 320→412 CHF Tsd, product lines Motorfahrzeug 148 / Hausrat 108 / Gewerbe 89
/ Vorsorge 79 / Rechtsschutz 69) mirror the mockups exactly.

Target entity logical names are **provisional** until Phases 1–3 author the tables in
DEV; the loader's field mapping is exercised only in the pipeline seed step (Phase 5.3,
DEV-gated).

## Sprint-004 enrichment (2026-08-17)

`policies.json`, `claims.json`, `leads.json`, and `activities.json` were
enriched per
[`intake/mobiliar/mappings/curveball-to-fixture-map.md`](../../../intake/mobiliar/mappings/curveball-to-fixture-map.md)
(sprint-004, `fixture-enrichment`, issue #130) to fixture-back 7 of the 8
Mobiliar reference-environment demo curveball scenarios: a multi-line
Brunner household portfolio (Hausrat + Motorfahrzeug + Rechtsschutz) so the
existing address-change Anliegen visibly ripples across several policies; a
second Roth policy (Hausrat) so the existing expiring Rechtsschutz line
demonstrates portfolio-aware discount unwinding; and one new lead, task, or
Anliegen each for GA reassignment, motor-vehicle re-rating, a life-event
trigger, a property/sum-insured change, and a data-quality/identity task.
The 8th curveball (building-insurance jurisdiction eligibility) is **not**
included — it would require a 6th `crmshow_productline` choice option
(schema change + ADR), which is out of scope for a fixture-only stream; see
the curveball map for the full rationale. All new records use only the
already-defined `crmshow_productline` options and stay within the existing
7 fixture files' shapes — no new entity type, no schema change.

