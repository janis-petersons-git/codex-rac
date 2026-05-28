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
- confirm the subaccount uses or can enable Cloud Foundry
- confirm at least one Cloud Foundry space exists before runtime-instance creation
- record the exact navigation path used in the cockpit

## Integration Suite Enablement

- identify the relevant service or capability names shown in the trial landscape
- verify entitlements or trial plan availability for Integration Suite
- create the Integration Suite subscription or instance
- enable the minimum required services and capabilities for Integration Suite administration and API usage
- confirm Cloud Integration capability status
- record any region-specific or trial-specific limitations

## Service Access

- create the required `Process Integration Runtime` service instances
- create at least one instance with plan `api`
- create at least one instance with plan `integration-flow`
- create service keys for the required APIs
- capture token endpoint, API base URL, tenant-management endpoint, client ID, and client secret
- verify that secrets are not written into repo files

## Access Validation

- confirm the user has the role collections needed to open Integration Suite and Cloud Integration
- if access fails, distinguish authorization problems from provisioning problems

## Handoff

- update reusable knowledge if any step was unclear or fragile
- produce a scenario result or run report with checkpoints, outcomes, and blockers
- state exactly what the next agent or user should do
