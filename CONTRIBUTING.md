# Contributing

## Ground rules

1. **Every architectural decision becomes an ADR.** No decision lives only in a
   deck or a chat. See [docs/adr/](./docs/adr/).
2. **Schema changes never bypass `solution/`.** If it is not in source control,
   it does not exist ([ADR-0017](./docs/adr/ADR-0017-alm-everything-through-the-pipeline.md)).
3. **Every change declares its upgrade impact.** Enforced in the ADR template
   and the PR checklist.
4. **Every capability carries a licensing flag** and, where AI, a **maturity**
   flag. See [docs/LICENSING.md](./docs/LICENSING.md).
5. **Never invent** a number, a customer name or a licensing statement. Use
   `[TBD — …]`.

## Workflow

```
question / change request
  → AG-E-03 enterprise-architect  → docs/adr/ADR-####-*.md
  → AG-E-08 dataverse-modeler     → solution/ change + test
  → AG-E-06 responsible-ai-officer→ guardrail review (AI / consent / personal data)
  → AG-E-10 insurance-domain-expert → domain correctness for insurance-vertical scope
  → AG-E-05 crm-domain-expert     → generic CRM practice correctness
  → PR                            → pipeline → sandbox
```

For data-plane concerns (signals, features, models, the Frontier Firm loop),
add `AG-E-07 data-engineer-scientist` to the review. For integration-contract
changes, add `AG-E-09 integration-engineer`.

## Naming

- ADRs: `ADR-####-kebab-case-title.md`, sequential, never renumbered.
- Superseded ADRs stay with `Status: Superseded by ADR-####`.
- Stories in [docs/BACKLOG.md](./docs/BACKLOG.md) use stable `US-###` IDs.
  Priorities move; IDs do not.

## Escalation

If a request would breach [SUPERPOWERS_CONTRACT.md](./SUPERPOWERS_CONTRACT.md)
§1, open a `governance-escalation` issue using
[the template](./.github/ISSUE_TEMPLATE/governance-escalation.md) rather than
working around it.
