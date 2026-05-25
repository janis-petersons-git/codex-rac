# Documentation Generation Principles

Normalized from the RS documentation kit.

## General rules

- use the sample `.docx` as the formatting source of truth
- preserve section structure and formatting conventions
- generate content from artifact facts, not guesswork
- validate the final `.docx`, not just the intermediate XML

## Parameter documentation

- use `parameters.propdef` as the primary ordered source for configurable parameters
- merge `param_references` only as a supplement
- intersect with `parameters.prop` to obtain configured values
- verify that advanced adapter settings are not silently omitted

## Word handling

- use Word COM for open/save, field refresh, and simple text assignment
- use OpenXML when Word COM is unreliable or destructive
- do not overwrite a locked file; create a timestamped copy

## Validation

- confirm old customer/project wording is removed from body, headers, footers, properties, and relationships
- confirm figure and table captions are sequential
- confirm Lists of Figures and Tables are populated correctly
- verify screenshots in the final document, not only as standalone images
