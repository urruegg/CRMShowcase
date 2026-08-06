# Functional Domain: Field Service

## Scope

Scheduling and dispatch of on-site work: work order management, resource
scheduling, and technician mobile execution.

## Key Processes

- **Work order management** — creation (often from a Customer Service
  case), scoping, and lifecycle tracking of on-site work.
- **Scheduling & dispatch** — matching work orders to available technicians
  based on skills, location, and availability.
- **Mobile execution** — technician-facing mobile experience for
  on-site work: status updates, parts/time logging, and customer sign-off.
- **Asset & inventory tracking** — customer assets serviced and inventory
  consumed during work orders.

## Personas

- Field technician
- Dispatcher / scheduler
- Field service manager

## Conventions

- Work orders originating from a case must retain a link back to the
  originating [Customer Service](customer-service.md) case.
- Scheduling logic should rely on the shared resource/skill model in the
  [CRM Core Platform](../architecture/crm.md) rather than a domain-specific
  copy.

## Related Domains

- [Customer Service](customer-service.md) — source of many work orders.
- [CRM Core Platform](../architecture/crm.md) — shared resource/asset data
  model.
- [Other Systems](../architecture/other-systems.md) — inventory/ERP
  integration for parts consumption.
