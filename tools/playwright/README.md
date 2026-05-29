# Playwright Helper Scripts

These scripts were imported as sanitized reference implementations for Integration Suite UI automation.

## Portability rules

- Replace `REPO_ROOT` with your local clone path or derive it dynamically before execution.
- Replace placeholder tenant values such as `https://<tenant-host>`, `<package-id>`, and `<artifact-id>` with your own environment-specific values.
- Keep browser storage state, credentials, and captured customer artifacts outside Git.

## Files

- `capture-iflow-screenshots.example.js`: captures iFlow screenshots using canvas zoom and selective panning
- `crop-iflow-screenshots.example.js`: post-processes raw screenshots into cropped artifacts
- `inspect-iflow-ui.example.js`: inspects visible designer controls and layout metadata