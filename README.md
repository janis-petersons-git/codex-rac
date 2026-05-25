# SAP CI Agent System

This repository is a clean starting point for building a shared agent and skill system for SAP Cloud Integration consulting workflows.

The goal is to make reusable consultant know-how versioned, reviewable, and improvable by multiple contributors.

## What this repo contains

- `docs/`
  Architecture, roadmap, and Git setup notes.
- `knowledge/`
  Reusable guidance extracted and normalized from the RS workspace.
- `schemas/`
  Structured contracts for scenarios and agent handoff.
- `scenarios/`
  Scenario templates for actual work intake.
- `skills/`
  Agent/skill-level operating instructions and checklists.
- `examples/`
  Sanitized sample scenarios.
- `policies/`
  Security and contribution rules.
- `tools/`
  Reserved for validators and helper scripts.

## Recommended workflow

1. Start with a scenario file from `scenarios/scenario.template.yaml`.
2. Let the orchestrator classify and enrich the scenario.
3. Route work to the relevant specialist skill.
4. Capture outputs and decisions in a run report.
5. Update modular knowledge files when new reusable lessons are confirmed.

## Immediate next implementation targets

1. Expand the scenario schema into separate migration and development contracts.
2. Add a run-report template.
3. Build the orchestrator intake and routing logic.
4. Add one end-to-end worker flow for CPI development.

## Git

Git is initialized locally in this workspace, but no remote is configured yet.

Before committing, configure your local Git identity:

```powershell
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

If you want hosted collaboration, create a GitHub or other Git-hosting account and connect a remote later.
