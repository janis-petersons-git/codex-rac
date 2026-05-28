# BTP Admin Execution Plan

This file defines the expected execution phases for the `btp-admin` worker.

## Phase 1. Confirm scope and safety boundary

- identify whether the task is `plan`, `draft`, `apply`, or `validate`
- confirm whether the run is allowed to create external accounts or tenant resources
- confirm the approved source for login credentials
- confirm how generated secrets will be handed back outside Git

## Phase 2. Establish current state

- determine whether the SAP BTP trial account already exists
- determine whether the target subaccount already exists
- determine whether Cloud Foundry is enabled and whether a space already exists
- determine whether Integration Suite is already provisioned
- record any known tenant identifiers, regions, or prior artifacts

## Phase 3. Drive the setup workflow

- navigate through the approved browser path or cockpit entry point
- create or locate the trial account
- create or locate the target subaccount
- enable Cloud Foundry if required
- assign or verify Integration Suite entitlement or trial plan
- create the Integration Suite subscription or instance
- enable capabilities and services required for Integration Suite and management APIs
- create service instances and service keys if approved

## Phase 4. Capture outputs

- subaccount name and region
- Cloud Foundry org and space
- Integration Suite subscription or instance status
- enabled capability list
- service-instance names and plans
- tenant management endpoint
- API endpoint
- token endpoint
- non-secret key metadata

## Phase 5. Handoff and knowledge capture

- fill in `skills/btp-admin/HANDOFF_TEMPLATE.md` or a run-specific copy
- update `knowledge/btp/*.md` with any UI or provisioning lessons
- record blockers precisely enough for the next operator to resume

## Current safety boundary for this repository

The repo may contain playbooks, prompts, checklists, and automation scaffolding for BTP setup work.

If the task requires:

- logging in with a real external account
- creating a third-party trial account
- creating live cloud resources
- extracting or handling live service keys

then the worker must stop short of performing those actions autonomously unless the environment and approval model explicitly permit that level of external account operation.
