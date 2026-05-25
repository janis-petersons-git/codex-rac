# Roadmap

## Phase 1: Foundation

- Extract reusable knowledge from the RS workspace
- Define scenario and worker contracts
- Scaffold repository structure
- Set up Git conventions and contribution rules

## Phase 2: Orchestrator

- Build request-classification logic
- Define intake questions by scenario type
- Produce validated scenario files
- Route work to the correct specialist skill

## Phase 3: First end-to-end worker

Recommended first implementation:

- `cpi-development`

Why:

- easier to validate locally
- lower risk than BTP administration
- strong overlap with your existing CPI prompt material

## Phase 4: Downstream assets

- test suite generation
- documentation generation
- run report standardization

## Phase 5: High-risk automation

- BTP account and subaccount administration
- tenant-connected write actions
- guarded approval flows for destructive changes

## Current progress

- `btp-admin` scaffold added with checklist, playbook, and sample scenario
- shared knowledge-capture rule added so hard-won lessons are preserved in modular assets
- next useful increments are a worker prompt, run-report template, and concrete scenario routing examples
