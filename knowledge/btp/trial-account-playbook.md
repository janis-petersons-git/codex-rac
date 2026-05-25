# SAP BTP Trial Account Playbook

This file captures reusable guidance for a BTP administration agent working against SAP BTP trial landscapes.

## Purpose

Use this playbook when the task involves:

- creating a SAP BTP trial account
- creating or configuring a trial subaccount
- enabling capabilities needed for Integration Suite
- creating service instances, service keys, and API access details
- performing browser-driven SAP BTP setup steps

## Operating Rules

1. Default to `plan` or `draft` before any action that creates accounts or changes tenant state.
2. Treat credentials, service keys, tokens, cookies, and copied browser session state as secrets.
3. Never commit secret material to Git. Store it outside the repo or provide it directly to the user.
4. Prefer deterministic handoff assets over one-off chat memory.
5. If a browser step is flaky, record the exact page, control label, prerequisite, and workaround in this file or a narrower skill file before finishing.

## Browser Automation Guidance

- Prefer a controllable browser session such as Playwright when UI interaction is required.
- Assume prior browser state is gone unless re-established in the current run.
- Record exact navigation paths because SAP BTP trial UI labels and menu nesting can shift over time.
- Capture enough detail for the next operator to resume from the last proven checkpoint.
- If a UI path fails, look for equivalent BTP cockpit navigation, service marketplace entries, or service-instance flows rather than guessing.

## Suggested Workflow For Trial Setup

1. Confirm execution mode and approval for tenant-modifying actions.
2. Acquire credentials from an approved local secret source.
3. Open the SAP BTP trial signup or login flow.
4. Establish whether the account already exists before attempting creation.
5. Create or locate the global trial account.
6. Create or locate the required subaccount.
7. Enable capabilities and entitlements required for Integration Suite administration and API access.
8. Create service instances and service keys needed for downstream design-time or management access.
9. Extract the token endpoint, API endpoint, tenant-management endpoint, client ID, and client secret.
10. Hand the secrets and endpoints to the user through an approved non-Git channel.

## Handoff Requirements

Every completed or blocked BTP run should leave behind reusable notes covering:

- what prerequisite state was assumed
- which navigation path worked
- which capabilities or services were enabled
- what naming convention was used for subaccounts and instances
- which endpoints and key fields were produced
- what blockers or UI ambiguities were discovered
- what another operator should do next

## Knowledge Capture Rule

If the agent spends extra effort on an unclear BTP or browser setup issue, it must convert the result into reusable handoff knowledge.

Preferred destinations:

- `knowledge/btp/*.md` for durable BTP platform rules
- `skills/btp-admin/*.md` for execution checklists or worker-specific instructions
- `examples/**/*.yaml` for scenario examples once the pattern stabilizes
