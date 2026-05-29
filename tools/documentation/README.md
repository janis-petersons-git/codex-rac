# Documentation Helper Scripts

These scripts were imported as sanitized reference implementations.

## Portability rules

- Replace `REPO_ROOT` with your local clone path or derive it dynamically before execution.
- Replace placeholder tenant values such as `https://<tenant-host>`, `<package-id>`, and `<artifact-id>` with your own environment-specific values.
- Keep customer templates, service keys, browser storage state, and output paths outside Git.

## Files

- `generate-documentation-from-template.example.ps1`: template-driven DOCX generation reference
- `patch-parameter-tables.example.ps1`: parameter-table refresh reference using `parameters.propdef` plus configured values
- `insert-screenshots.example.ps1`: screenshot insertion reference for generated documentation