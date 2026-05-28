# Known BTP Findings

This file records durable findings discovered while building the BTP administration skill set.

## Findings

### Existing RS Playwright workspace contains relevant BTP and Integration Suite artifacts

- Prior work in `C:\Users\janis.petersons\Desktop\RS\_work\playwright_ci` includes Playwright scripts and artifacts for SAP trial login and Integration Suite UI inspection.
- Recovered artifact names indicate prior successful navigation into SAP BTP cockpit and an Integration Suite trial tenant.
- Those artifacts are useful as operator context and for future tooling patterns, but they do not remove the need to re-establish live browser state in a new run.

### Browser continuity must be treated as non-persistent

- Saved artifacts and prior scripts can document a working path.
- They cannot be treated as a live authenticated browser session for future runs.

### External-account creation remains a hard safety boundary

- Building the agent, skill system, handoff assets, and execution plans is safe and reusable.
- Directly logging into SAP and creating external accounts or live tenant resources is a distinct operational boundary that must be explicitly allowed by the execution environment and approval model.

### Integration Suite onboarding requires more than a single subscription step

- Current SAP guidance separates account setup from runtime API access.
- Creating the Integration Suite subscription or instance does not by itself create the OAuth clients needed for API access or iFlow inbound authentication.
- For CPI-oriented automation, the worker should expect to create separate `Process Integration Runtime` instances with plan `api` and `integration-flow`, then create service keys from those instances.

### Cloud Foundry is a prerequisite for the runtime instances and service keys

- SAP guidance for Process Integration Runtime service instances assumes a Cloud Foundry subaccount and an existing space.
- The worker should verify Cloud Foundry enablement before attempting to create the required instances.

### Service-key extraction must be plan-aware

- Keys created from different service plans expose different endpoint fields.
- The `api` plan is the one tied to SAP Cloud Integration OData/API access.
- Some SAP docs describe token acquisition using the `url` field with `/oauth/token` appended, while other services expose a distinct `tokenurl`; the worker should capture both patterns without guessing.
