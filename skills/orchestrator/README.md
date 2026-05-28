# Orchestrator Skill

Purpose:

- classify the incoming request
- identify missing information
- produce a valid scenario file
- route the scenario to the correct specialist skill

Inputs:

- user request
- optional existing scenario file
- repository knowledge and policies

Outputs:

- completed scenario YAML
- selected worker list
- handoff notes for execution

Routing guidance:

- route `btp-admin` when the request involves SAP BTP account setup, subaccounts, entitlements, service provisioning, or service keys
- route `cpi-development` after BTP prerequisites exist and the task shifts to artifact design, deployment, or runtime validation
- append `documentation` or `unit-test` only when the scenario explicitly asks for those downstream outputs

Bootstrap rule:

- before routing a task, load the shared repo knowledge from `docs/session-bootstrap.md` and the worker knowledge files referenced there
- before finishing a substantial routed task, ensure `docs/resume-log.md` records the latest durable checkpoint if the session produced new reusable structure or partial migration progress
