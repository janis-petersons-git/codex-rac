# CPI Development Principles

Extracted from the RS CPI prompt set and normalized for reuse.

## Preferred implementation order

For payload transformation:

1. graphical message mapping
2. XSLT when reshaping is needed
3. Groovy only as a fallback

For non-transform concerns:

- prefer standard CPI steps and configuration first
- use Content Modifier for constants, headers, properties, and simple body assignments

## Design rules

- confirm source and target structures before authoring mappings
- validate namespaces, wrappers, repeated nodes, and root mappings carefully
- do not guess uncertain adapter serialization; export and mirror a real tenant reference when possible
- externalize adapter address, credential alias, and client number where applicable
- prefer reusable value mappings for cross-process lookup data when they fit the runtime model cleanly

## Packaging rules

- include `META-INF/MANIFEST.MF`
- use forward slashes in archive entries
- keep CPI-compatible folder structure under `src/main/resources`
- update copied identity files when cloning an iFlow

## Validation rules

- local validation is not enough when tenant access exists
- continue through deploy and runtime verification unless blocked
- when using dummy backend flows, validate inbound request shape before returning a canned response
