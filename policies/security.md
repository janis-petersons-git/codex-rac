# Security Policy

- Never commit real credentials, service keys, tokens, or browser session state.
- Use placeholder or template credential files in Git.
- Keep environment-specific values in ignored local files.
- Sanitize customer names, URLs, package IDs, and payload examples before adding them to shared examples.
- Default tenant-modifying actions to `plan` or `draft`.
- Require explicit operator confirmation for destructive or state-changing production-like actions.
