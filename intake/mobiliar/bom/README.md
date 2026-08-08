# Mobiliar prototype artefact BOM

Generated on 2026-08-08 from the unmanaged `Mobiliar` solution with Power
Platform CLI 1.43.6 and enriched with filtered Dataverse model metadata for
package-omitted table definitions.

## Safety boundary

- No Dataverse records were exported.
- The raw ZIP, unpacked web resources, bot content, and generated metadata
  classes remain local and ignored.
- The source scan inspected 181 files and found no credential pattern.
- It found seven files with email-like values and six files containing the
  source environment hostname. This confirms that the source snapshot must not
  be published in this public repository.
- The committed BOM contains structural metadata and classifications only.

## Coverage

| Measure | Count |
| --- | ---: |
| Root components | 43 |
| BOM items | 941 |
| Tables | 11 |
| Custom tables | 6 |
| Items enriched from live table metadata | 94 |
| Declared missing dependencies | 605 |
| Domain-map rows | 941 |

`Household`, `Policy`, and `Offer` were exported as root tables with empty
entity definitions. Their columns and relationships were therefore enriched
through a filtered `pac modelbuilder build` metadata read. This is evidence
that the prototype solution package is not a self-contained deployment
baseline.

## Component counts

| Component type | Count |
| --- | ---: |
| AppModule | 5 |
| Attribute | 168 |
| Bot | 1 |
| BotComponent | 19 |
| ChoiceOption | 10 |
| DataverseSearch | 2 |
| DataverseSearchEntity | 12 |
| Entity | 11 |
| Form | 18 |
| MissingDependency | 605 |
| OrganizationSetting | 1 |
| Relationship | 29 |
| Ribbon | 11 |
| SettingDefinition | 1 |
| SiteMap | 5 |
| View | 21 |
| WebResource | 22 |

## Domain counts

| Domain | Count |
| --- | ---: |
| AI and agent-assisted capabilities | 20 |
| Foundation and shared configuration | 623 |
| Marketing, consent, and journeys | 61 |
| Party, household, and relationship | 97 |
| Policy, claim, quote, and insured-object projections | 36 |
| Sales and opportunity management | 41 |
| Service and case management | 63 |

## Initial dispositions

| Disposition | Count | Meaning |
| --- | ---: | --- |
| Investigate | 641 | Dependency, licence, maturity, or target-availability review is required. |
| Redesign | 273 | Requirement is potentially useful but conflicts with the target model or implementation approach. |
| Refactor | 25 | Native capability or useful UX pattern should be rebuilt with governed configuration. |
| Retire | 2 | Customer-specific branding is excluded from the anonymized showcase. |

## Files

- [`artefacts.json`](./artefacts.json) is the canonical machine-readable BOM.
- [`artefacts.csv`](./artefacts.csv) is the tabular review format.
- [`../mappings/domain-map.csv`](../mappings/domain-map.csv) is the standalone
  domain, target-solution, and disposition map.

The composite identity for reconciliation is
`componentType + logicalName + parent`.
