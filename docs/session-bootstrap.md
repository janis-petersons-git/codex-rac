# Session Bootstrap

Use this repo, not the old RS folder, as the shared knowledge base for future sessions.

## Default startup order

Read these assets in order when starting a new SAP Cloud Integration consulting session in this repository:

1. `docs/architecture.md`
2. `knowledge/cpi/agent-operation.md`
3. `knowledge/cpi/development-principles.md`
4. `knowledge/cpi/tenant-api-notes.md`
5. `knowledge/documentation/agent-operation.md`
6. `knowledge/documentation/generation-principles.md`
7. `knowledge/documentation/screenshot-playbook.md`
8. `knowledge/btp/trial-account-playbook.md`
9. `knowledge/btp/known-findings.md`
10. `skills/orchestrator/README.md`
11. The worker skill README for the task being executed

## General operating rules

- Treat this repo as the canonical shared memory for agents and collaborators.
- Keep reusable knowledge in modular files rather than long one-off prompts.
- If a task produces a reusable workaround, research conclusion, browser path, or implementation rule, update the relevant repo asset before finishing.
- Keep secrets, service keys, copied browser state, and tenant-specific credentials out of Git.

## Recommended worker defaults

- `btp-admin`: default to `plan` or `draft` unless the scenario explicitly allows tenant changes.
- `cpi-development`: continue through deployment and runtime validation when tenant access exists.
- `documentation`: validate the final rendered document, not only intermediate files.
- `unit-test`: derive test suites from the scenario and generated artifacts, not from assumptions.
