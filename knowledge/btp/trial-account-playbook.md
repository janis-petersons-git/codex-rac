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
6. Create or locate the required subaccount and verify the region.
7. Ensure Cloud Foundry is enabled for the subaccount and that at least one space exists before creating Cloud Foundry service instances.
8. Assign or verify the Integration Suite entitlement or trial plan available in the landscape.
9. Create the Integration Suite instance or subscription and enable the required capabilities.
10. Create service instances and service keys needed for downstream design-time or management access.
11. Extract the token endpoint, API endpoint, tenant-management endpoint, client ID, and client secret.
10. Hand the secrets and endpoints to the user through an approved non-Git channel.

## Current SAP-Documented Setup Sequence

Use this sequence as the default path unless the live cockpit shows a newer label or ordering:

1. Log in to SAP BTP cockpit and enter the user's trial or free account.
2. If no suitable subaccount exists, create one from the global account or trial landing page.
3. Set or confirm that the subaccount uses the Cloud Foundry environment.
4. Enable Cloud Foundry for the subaccount and create a Cloud Foundry organization and at least one space if they are not already present.
5. Verify entitlements and quota for Integration Suite at the global-account or subaccount level.
6. In the subaccount, open `Services > Service Marketplace`, locate `Integration Suite`, and create the instance or subscription using the `trial` plan when the landscape offers it.
7. Open the created Integration Suite application and enable only the capabilities required by the scenario, with `Cloud Integration` as the baseline capability for iFlow development.
8. In the same subaccount, use `Services > Service Marketplace` to create `Process Integration Runtime` instances in Cloud Foundry:
   - one instance with plan `integration-flow`
   - one instance with plan `api`
9. From `Services > Instances and Subscriptions`, create service keys for those instances.
10. Capture the returned OAuth and endpoint fields and hand them back outside Git.

## Required Inputs For A Real Run

The orchestrator should collect these inputs before handing off to `btp-admin` in `apply` mode:

- SAP login user name
- SAP login password or approved interactive login method
- project name used to derive the subaccount display name `Codex-{project}`
- preferred region if the trial account offers more than one region
- whether a new trial account may be created when login succeeds but no trial account exists
- whether existing subaccounts may be reused when the requested name already exists
- names for the Cloud Foundry org and space when defaults are not acceptable
- capability list to enable inside Integration Suite
- approved handoff channel for generated client secrets

## Expected BTP Objects For CPI Work

The default target state for CPI-focused trial onboarding is:

- one subaccount named `Codex-{project}`
- Cloud Foundry enabled in that subaccount
- one Integration Suite subscription or instance with required capabilities enabled
- one `Process Integration Runtime` instance with plan `integration-flow`
- one `Process Integration Runtime` instance with plan `api`
- one service key per required runtime instance

## Key Fields To Capture From Service Keys

At minimum, the worker should capture these fields when present:

- `clientid`
- `clientsecret`
- `url`
- `tokenurl` when explicitly returned
- token endpoint derived as `url + /oauth/token` when the key exposes only `url`
- service-plan-specific API base URLs such as `management` and `entities`

For Process Integration Runtime `api` plan keys, expect SAP-managed fields used for OData/API access.
For `integration-flow` plan keys, expect OAuth client material used for inbound authentication to deployed iFlows.

## Role And Access Notes

- SAP Integration Suite setup spans both account administration and application authorization.
- SAP documentation identifies the global account administrator as responsible for subaccount creation and quota assignment.
- SAP documentation also calls out the need to assign Integration Suite role collections so the user can access enabled capabilities after provisioning.
- If the user cannot open Integration Suite after subscription and capability enablement, inspect role collection assignment before assuming provisioning failed.

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
