# Documentation Session Start Prompt

Use this repo-native launch guidance instead of the old RS start prompt.

## Required reading for a fresh documentation session

1. `docs/session-bootstrap.md`
2. `knowledge/documentation/agent-operation.md`
3. `knowledge/documentation/generation-principles.md`
4. `knowledge/documentation/screenshot-playbook.md`
5. the job-specific XML, template `.docx`, and artifact inputs for the task

## Execution rule

Execute the documentation task end to end.

- use the sample `.docx` as the formatting template
- preserve the same section structure and layout as closely as possible
- document the integration flows defined by the task inputs
- validate the final rendered `.docx`
- if screenshots are required, validate caption numbering, generated figure lists, and embedded media after insertion

## Default expectations

- include only externally configurable parameters in parameter tables
- keep reference tables empty unless the document truly references external documents
- group related flows under shared business-process sections when appropriate
- if new documentation-specific lessons are learned, update the shared repo knowledge before finishing