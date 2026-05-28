# BTP Admin Skill

Purpose:

- create or configure a SAP BTP trial landscape for SAP Integration Suite work
- provision the subaccount, subscription, capabilities, service instances, and service keys needed by downstream CPI agents
- capture exact non-secret metadata and operator handoff for later automation

Scope:

- SAP BTP trial signup or login decision flow
- subaccount creation using the `Codex-{project_name}` naming convention
- Cloud Foundry enablement for the target subaccount
- Integration Suite subscription and capability activation
- `Process Integration Runtime` service-instance and service-key creation
- endpoint and authorization handoff for downstream workers

This skill is for scaffolding and guided execution. Live browser login and cloud-resource creation should only run in `apply` mode with explicit approval and a non-Git secret channel.

## Required inputs

The orchestrator should collect these fields before handing off to `btp-admin`:

- `project_name`
- `btp_account.credentials_source`
- `btp_account.account_mode`
  Values: `login-existing`, `create-trial-if-missing`
- `global_account.preferred_region`
- `subaccount.name`
  Default: `Codex-{project_name}`
- `subaccount.region`
- `subaccount.reuse_if_present`
- `cloud_foundry.org_name`
- `cloud_foundry.space_name`
- `integration_suite.capabilities`
  Minimum: `Cloud Integration`
- `service_instances`
  Minimum target set:
  - `Process Integration Runtime` with plan `integration-flow`
  - `Process Integration Runtime` with plan `api`
- `service_keys`
  Key names to create for each instance
- `handoff.secret_delivery_method`

## Expected outputs

- trial account status
- global account and subaccount identifiers
- subaccount region
- Cloud Foundry org and space used
- Integration Suite subscription status
- activated capabilities list
- service-instance inventory with service name, runtime, plan, and instance name
- service-key inventory with key name only
- token endpoint, API base URL, and tenant/runtime endpoints when present in the created keys
- precise blocker notes when trial or region limits prevent completion

## Current implementation stance

- prefer `plan` and `draft` while the workflow is being stabilized
- keep credentials, service keys, and browser storage state out of Git-tracked files
- record cockpit navigation labels exactly because SAP UI labels change over time
- treat trial-region and service availability as live environment facts that must be verified during execution
