# BTP Admin Checklist

Use this checklist when executing or reviewing a BTP administration scenario.

## Before Execution

- confirm whether the mode is `plan`, `draft`, `apply`, or `validate`
- confirm approval for creating accounts, subaccounts, entitlements, or service instances
- identify the approved secret source for login credentials
- identify where generated secrets will be handed back outside Git

## Trial Account And Subaccount

- confirm whether the SAP BTP trial account already exists
- create or locate the subaccount required by the scenario
- verify the subaccount name and region
- record the exact navigation path used in the cockpit

## Integration Suite Enablement

- identify the relevant service or capability names shown in the trial landscape
- enable the minimum required services for Integration Suite administration and API usage
- record any region-specific or trial-specific limitations

## Service Access

- create the required service instances
- create service keys for the required APIs
- capture token endpoint, API base URL, tenant-management endpoint, client ID, and client secret
- verify that secrets are not written into repo files

## Handoff

- update reusable knowledge if any step was unclear or fragile
- produce a scenario result or run report with checkpoints, outcomes, and blockers
- state exactly what the next agent or user should do
