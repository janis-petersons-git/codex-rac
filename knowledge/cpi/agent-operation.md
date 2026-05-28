# CPI Agent Operation Guide

This file consolidates the reusable operating guidance extracted from the RS CPI kit.

## Execution expectation

- Do not stop at file generation when tenant access exists.
- Continue through packaging, deployment, runtime validation, and iteration on tenant feedback until the work is proven or a concrete blocker remains.
- Prefer deterministic tenant validation over assumptions based on local inspection.
- Load the scenario-specific XML or structured scenario contract before implementation so repo knowledge is combined with task-specific inputs.

## Preferred implementation order

- Use standard CPI configuration objects and steps before scripting.
- For payload transformations, prefer graphical message mappings.
- Use XSLT when XML reshaping is needed to make the mapping or structure clean.
- Use Groovy only when standard CPI artifacts, mappings, or XSLT cannot implement the requirement responsibly.

## Structure and mapping rules

- Confirm the real runtime source and target structures before editing mappings.
- Validate namespaces, wrappers, repeated nodes, root mappings, and top-level array behavior explicitly.
- For query-parameter-driven APIs, normalize request data into properties first and keep the business transform in a graphical mapping when practical.
- If a CPI-authored source scaffold is needed to make a graphical mapping deployable, keep the actual business values property-driven and document that distinction.

## Packaging and tenant API rules

- Package deployables with `META-INF/MANIFEST.MF`, CPI-compatible folder structure, and forward slashes inside ZIP entries.
- If an iFlow is cloned from an existing artifact, update copied identity files such as `.project` and manifest bundle identity fields.
- Prefer proven OData patterns over guessed endpoints or payload shapes.
- When a tenant rejects one update style, switch to a proven create-or-recreate path instead of retrying the same unsupported call.

## Adapter, credential, and lock rules

- Do not guess adapter serialization. Use exported tenant-created references when the exact shape is uncertain.
- Externalize sender and receiver adapter address, credential alias, and client number wherever applicable.
- Create security artifacts by mirroring proven tenant entity shapes rather than inventing fields from memory.
- When design-time locks are encountered, use the real design-time lock endpoints and follow the project lock policy rather than relying on generic lock assumptions.

## Validation rules

- Validate locally first, then validate in the tenant when access exists.
- For helper flows or dummy backends, ensure the helper verifies the inbound request shape before returning a canned response.
- For screenshot-dependent tasks, treat the web UI as the source of truth rather than trying to infer layout from exported files.

## Knowledge maintenance

- If a CPI task reveals reusable deployment, mapping, adapter, runtime, or screenshot knowledge, convert that into modular repo assets before finishing.
- When importing or continuing older workspace knowledge, normalize it into repo-native files instead of depending on personal prompts outside Git.
