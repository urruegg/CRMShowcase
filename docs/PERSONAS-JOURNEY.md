# Personas & Journeys — CRM Frontier Firm Showcase

| Field | Value |
| --- | --- |
| Version | 0.1 (Draft) |
| Status | Draft |

> **Template.** Fill in journeys as the showcase concretises. Copilot agents in
> [.github/agents/](../.github/agents/) reason over these entries.

## P-01 — Sales Rep (Alex)
- **Wants:** to spend time with prospects who will close, not on triage.
- **Reality:** overloaded inbox, patchy CRM hygiene, high context-switching cost.
- **Frontier-firm shift:** the Lead Qualification Assistant (`AG-F-01`) drafts summaries;
  Alex decides which leads to pursue.

## P-02 — Service Agent (Priya)
- **Wants:** to resolve a case in one interaction with a happy customer.
- **Reality:** knowledge scattered across tools, high volume of routine tickets.
- **Frontier-firm shift:** the Service Triage Agent (`AG-F-02`) categorises and drafts;
  Priya reviews and sends.

## P-03 — Marketing Operator (Sam)
- **Wants:** more variants, faster, without diluting the brand.
- **Reality:** manual copy iteration is the bottleneck.
- **Frontier-firm shift:** the Campaign Copy Generator (`AG-F-03`) drafts variants;
  Sam approves before scheduling.

## P-04 — RevOps Lead (Jordan)
- **Wants:** a weekly, honest read of the pipeline with anomalies flagged early.
- **Reality:** dashboards say what happened, not what to do.
- **Frontier-firm shift:** the RevOps Insights Agent (`AG-F-04`) summarises movement and
  flags top-N anomalies; Jordan chooses what to act on.

## P-05 — Customer (external)
- Interacts with the showcase indirectly, via messages a human on P-01/P-02/P-03 has
  approved before sending. **Never** talks to an agent that can act autonomously in this demo.

## Journeys

> One journey per use case, referenced from [PRD.md](./PRD.md). Add as the showcase grows.

### Journey — UC1 Assisted lead-to-cash
1. Lead arrives → Dataverse `Lead` record.
2. `AG-F-01` drafts a qualification summary grounded in the record + interactions.
3. Alex reviews, edits if needed, and either dismisses or clicks *Approve → schedule meeting*.
4. Nothing is sent externally until Alex approves.
