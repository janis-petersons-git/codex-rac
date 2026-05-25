# CPI Tenant API Notes

Validated and reusable observations extracted from the RS prompt material.

## Common design-time operations

- list packages
- list package artifacts
- create packages
- create or recreate integration artifacts from zip payloads
- deploy artifacts
- poll build and deploy status
- export design-time artifact zips
- inspect runtime artifacts and errors
- list and delete design-time locks
- create security material
- create and deploy value mappings

## Important behavior notes

- do not assume technical IDs from display names
- some advertised OData endpoints may still return `404` or `501`
- package navigation endpoints can be safer than some keyed reads
- deploy operations may return a raw task ID string instead of JSON
- build/deploy polling may use `Status` instead of `State`
- on some tenant families, media update endpoints may be unreliable; delete-and-recreate can be the safer fallback when proven

## Lock handling

- use `IntegrationDesigntimeLocks` as the source of truth
- do not trust only generic lock endpoints
- record approval policy explicitly rather than burying it in prompts
