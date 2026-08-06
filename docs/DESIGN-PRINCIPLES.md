# Design Principles — CRM Frontier Firm Showcase

| Field | Value |
| --- | --- |
| **Topic area** | **A1** — *"which architecture principles secure long-term stability, extensibility and technological independence"* |
| Version | 0.2 (Draft) |
| Status | Draft |

A principle that cannot fail a review is not a principle — it is a slogan. Each
one below has a test.

| # | Principle | How it fails a review |
| --- | --- | --- |
| DP-01 | **Thin CRM over the engines** ([ADR-0008](./adr/ADR-0008-thin-crm-over-systems-of-record.md)) | Rating or eligibility computation appears in the solution |
| DP-02 | **One party model** ([ADR-0006](./adr/ADR-0006-account-centre-of-gravity.md)) | A second party container or a B2C/B2B fork appears |
| DP-03 | **Portfolio at the Account** ([ADR-0007](./adr/ADR-0007-portfolio-at-account.md)) | A policy or claim is attached to a Contact |
| DP-04 | **Events carry effective dates** ([ADR-0011](./adr/ADR-0011-event-driven-cascade.md)) | An event exists without an effective date |
| DP-05 | **Contracts are versioned artefacts** | A published contract changes without a version and an ADR |
| DP-06 | **Every extension declares its upgrade impact** | An ADR is missing the upgrade-impact line |
| DP-07 | **Everything through the pipeline** ([ADR-0017](./adr/ADR-0017-alm-everything-through-the-pipeline.md)) | A change exists in an environment but not in `solution/` |
| DP-08 | **Consent is evaluated at the API layer** ([ADR-0010](./adr/ADR-0010-consent-per-contact-per-channel.md)) | A send path exists that does not check consent |
| DP-09 | **Agents recommend; humans decide** ([ADR-0014](./adr/ADR-0014-agents-advisory-by-design.md)) | An agent performs an unattended customer-facing act |
| DP-10 | **Standard before low-code before pro-code** | A pro-code extension exists with no rejected lower-tier option in its ADR |
| DP-11 | **No per-GA forks** ([ADR-0013](./adr/ADR-0013-ga-ownership-and-territory.md)) | A GA-specific variant of the model or solution appears |
| DP-12 | **Maturity and licensing are stated, never implied** | A capability is shown with no maturity or licence flag |
| DP-13 | **Grounded generation** | An AI-generated customer-visible message cites a source it did not retrieve |
| DP-14 | **Synthetic-only demo data** ([SUPERPOWERS_CONTRACT.md](../SUPERPOWERS_CONTRACT.md) §1.3) | Real customer data appears anywhere in the repo |

## Technological independence

A recurring architecture question: how does the showcase preserve long-term
independence from the vendor stack?

- **Open schema.** Dataverse is not a packaged insurance suite schema — the
  model belongs to the customer, and it is exportable.
- **Thin CRM.** Insurance logic stays in the customer's own engines, so the CRM
  decision does not become an insurance-platform decision.
- **Source-controlled solution.** The configuration is an artefact the customer
  holds, not a state inside a vendor environment.
- **Stated dependencies.** See [SD.md](./SD.md) — we name our own lock-in
  surface rather than waiting to be asked.
