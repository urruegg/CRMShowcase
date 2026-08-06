# Non-Delegable Work

Some decisions in this repo cannot be made by a Copilot agent alone. This file
records them so both humans and agents know when to stop and escalate.

## Human sign-off is required for

1. **Architecture decisions** that change the API contract, the data model,
   the residency posture, or the human/agent split of work.
   *Escalate to:* Enterprise Architect (human), record via ADR.

2. **Responsible-AI decisions**: adopting a new model, changing a system prompt,
   changing a Content Safety configuration, or changing an eval baseline.
   *Escalate to:* Responsible-AI Officer (human).

3. **Security and identity** changes: adding a new secret, disabling a CI gate,
   changing OIDC federation, changing branch protection.
   *Escalate to:* SecDevOps lead (human).

4. **Customer-impacting actions in the running demo**: sending outbound email,
   modifying pricing/quotes, closing service cases — unless a specific story's
   acceptance criteria explicitly scopes the agent to do so autonomously.
   *Escalate to:* the running human user of the demo (in-product approval UI).

5. **Introducing real customer data**. This is never delegable. If a demo needs
   more realism, produce synthetic data instead.

## What an agent should do when it hits a non-delegable decision

- **Stop** the change.
- **Explain** in the PR / chat which rule is triggered.
- **Open an issue** tagged `governance-escalation`.
- **Propose** the smallest possible slice that is delegable.
