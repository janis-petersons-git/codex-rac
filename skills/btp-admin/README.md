# BTP Admin Skill

Purpose:

- create or configure SAP BTP trial landscape prerequisites for Integration Suite work
- provision subaccounts, entitlements, service instances, and service keys
- capture tenant management and API endpoints needed by downstream CPI agents

Scope:

- SAP BTP trial account onboarding guidance
- browser-driven administrative setup steps
- subaccount creation and capability enablement
- Integration Suite and related service provisioning
- service key capture and endpoint reporting
- reusable handoff notes for downstream workers

Execution notes:

- default to `plan` or `draft` for actions that create accounts or modify tenant state
- treat login credentials and service keys as secrets and keep them out of Git
- when browser automation is required, follow the shared browser playbook and record blockers precisely
- if a step is difficult, unstable, or unclear, add the reusable lesson to modular knowledge files before finishing
