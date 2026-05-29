# CPI Migration Skill

Purpose:

- analyze source and target tenant or package scope
- compare artifacts and configuration
- prepare migration plan and execution notes

Initial focus:

- inventory
- gap analysis
- configuration parameter mapping
- migration runbook generation

Primary knowledge sources:

- `docs/session-bootstrap.md`
- `knowledge/cpi/agent-operation.md`
- `knowledge/cpi/tenant-api-notes.md`
- `examples/migration/sample-uploaded-iflows.json`

Required behavior:

- collect a sanitized inventory of artifacts, versions, roots, and package relationships before planning changes
- use structured examples such as `sample-uploaded-iflows.json` to normalize migration inventories
- map configuration differences explicitly instead of assuming parity across tenants
- leave behind a reusable migration runbook and update repo knowledge when a new migration pattern is learned