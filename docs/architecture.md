# Architecture

This repository is the shared operating system for SAP Cloud Integration consultant workflows.

The intent is not to "train" agents in the machine learning sense. The reusable intelligence lives in versioned assets:

- prompts
- skills
- schemas
- checklists
- examples
- scripts
- regression tests

## Core design

The system is built around one orchestrator and multiple specialist workers.

### Orchestrator

Responsibilities:

- classify the request
- gather missing inputs
- create a structured scenario file
- select the correct worker or worker chain
- enforce execution mode and approval policy
- collect outputs into a final run report

### Specialist workers

Initial worker set:

- `btp-admin`
- `cpi-development`
- `cpi-migration`
- `sanity-test`
- `unit-test`
- `documentation-development`
- `documentation-migration`

Do not assume every worker is fully autonomous. Some may begin as skill packs invoked by the orchestrator.

## Execution modes

Every agent workflow should support explicit execution modes:

- `plan`
- `draft`
- `apply`
- `validate`

Default to `plan` or `draft` for actions that can modify a tenant or environment.

## Shared contracts

Agents must exchange structured files, not free-form prose, wherever possible.

Primary contract files:

- `scenarios/scenario.yaml`
- `schemas/*.schema.yaml`
- `examples/**/*.yaml`
- `runs/<timestamp>/run-report.md`

## Design principles

1. Separate reusable knowledge from scenario-specific inputs.
2. Keep credentials and real tenant identifiers out of Git.
3. Prefer deterministic inputs and outputs over clever prompting.
4. Capture lessons learned in modular files, not long handoff prompts.
5. Add tests around skills and schemas as soon as patterns stabilize.
