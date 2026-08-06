# Personas & End-to-End Journey

| Status | Draft 0.2 |

The narrative anchor: **customers do not experience departments, they
experience the insurer.** They do not care whether a process belongs to sales,
service or claims — only that somebody knows them.

| # | Persona | Cares about | Deep-dive |
| --- | --- | --- | --- |
| P-01 | **Advisor (GA)** | *"Every minute spent searching for information is one less minute helping customers."* No opportunity forgotten. | Sales |
| P-02 | **General Agent lead** | Local steering, autonomy within governance, portfolio health | Sales |
| P-03 | **Assistance agent** | *A customer beside a broken vehicle at 2 AM does not need a case number — they need reassurance.* | Service |
| P-04 | **Marketer** | Relevance over volume; *"which customer needs our attention right now?"* | Marketing |
| P-05 | **Broker manager** | Moving from retrospective reporting to proactive partnership management | Broker |
| P-06 | **IT / Architect** | Boundaries, contracts, upgrade safety, operability, who is accountable | **This repository** |
| P-07 | **Business owner / Data steward** | What they can change on Monday without a ticket; data quality ownership | A9 |

## The Tag-1 persona

**P-06 is the architecture audience.** They are not evaluating whether the UI
is pleasant. They are evaluating whether this platform will still be
maintainable in ten years, who they will be arguing with when an integration
breaks, and whether the claims survive contact with their own architects.

Everything is built for that persona: repository first because they distrust
slides, ADRs because they want the reasoning not the conclusion, the live
build because extensibility claims are cheap, and the rollback because
operability claims are cheaper.

## Illustrated primary customer

- **Contoso Insurance** — a cooperative multi-line insurer with roughly 80
  independent General Agent offices. The illustrated household is the **Smith
  household**: existing customer with motor, contents, liability, natural-hazard
  and building cover, and a multi-product discount. They relocate across a
  jurisdiction boundary. See
  [ideas/UC-01-relocation-across-jurisdictions/README.md](./ideas/UC-01-relocation-across-jurisdictions/README.md).

## The journey on the golden thread

`Relocation → Cascade → Coverage check → GA reassignment → Advisory
opportunity → Quote → Close`

The customer experiences one continuous relationship. Internally it crosses
marketing, sales, service, after-sales, the GA organisation, and four systems
of record. That gap is the whole architecture conversation.
