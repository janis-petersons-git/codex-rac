# CPI Development Skill

Purpose:

- design and generate CPI implementation artifacts
- package them correctly
- deploy and validate them when tenant access exists

Scope:

- iFlow structure
- message mappings
- XSLT
- Groovy as a fallback
- adapter configuration
- externalized parameters
- packaging and tenant validation guidance

Primary knowledge sources:

- `knowledge/cpi/agent-operation.md`
- `knowledge/cpi/development-principles.md`
- `knowledge/cpi/tenant-api-notes.md`

Required behavior:

- prefer standard CPI artifacts before scripting
- prefer graphical mappings first, XSLT second, Groovy third
- verify real runtime structures before finalizing mappings
- use proven tenant API patterns instead of guessed endpoints or payload shapes
- continue through deployment and runtime validation when the scenario and access model allow it
