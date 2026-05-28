# CPI Session Start Prompt

Use this repo-native launch guidance instead of the old RS start prompt.

## Required reading for a fresh CPI session

1. `docs/session-bootstrap.md`
2. `knowledge/cpi/agent-operation.md`
3. `knowledge/cpi/development-principles.md`
4. `knowledge/cpi/tenant-api-notes.md`
5. the scenario-specific XML, YAML, or source files for the task

## Execution rule

Execute the CPI task end to end.

- read the specifications, examples, and tenant configuration first
- build the correct CPI artifacts for the scenario
- if tenant access exists, continue through package update, credential creation when requested, deployment, runtime error inspection, and real endpoint testing
- if new CPI-specific knowledge is learned, update the shared repo knowledge before finishing

## Default expectations

- prefer standard CPI steps and configuration objects over scripting when they can implement the requirement cleanly
- prefer graphical message mappings for normal payload transformations
- use XSLT when reshaping is needed
- use Groovy only where it is the right tool rather than as a shortcut
- keep packages portable unless the scenario explicitly calls for shared tenant dependencies