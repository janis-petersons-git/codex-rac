# Documentation Skill

Purpose:

- generate migration or development documentation from structured inputs and artifacts
- preserve template-driven formatting rules
- validate output quality before handoff

Primary knowledge sources:

- `knowledge/documentation/agent-operation.md`
- `knowledge/documentation/session-start-prompt.md`
- `knowledge/documentation/generation-principles.md`
- `knowledge/documentation/screenshot-playbook.md`

Required behavior:

- use the sample/template document as the formatting source of truth
- validate screenshots as rendered document content, not only as standalone images
- derive configuration-parameter tables from the full externalized parameter model, not only from direct references
- validate figure/table numbering, lists, and stale customer references before handoff
- read the documentation job config or scenario contract before generation and treat it as the authoritative scope for grouping and output
