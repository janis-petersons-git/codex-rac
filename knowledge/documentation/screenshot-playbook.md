# Screenshot Playbook

## Capture workflow

1. Use a controllable browser session.
2. Open the SAP Integration Suite graphical designer.
3. Wait for the diagram canvas to finish rendering.
4. Use SAP canvas zoom deliberately.
5. Save raw screenshots first.
6. Crop in a separate step.
7. Validate screenshots inside the final document.

## Capture rules

- use a large viewport for complex flows
- use SAP designer zoom controls, not only browser zoom
- if the process is hidden under the SAP UI chrome, pan the canvas down before capture
- avoid global crop logic that breaks edge cases
- keep per-flow crop overrides when needed

## Crop rules

- preserve the whole process container unless intentionally marked as cropped
- do not clip participant boxes, borders, dashed lines, or labels
- remove SAP UI remnants at the top and left
- keep raw and cropped outputs separate
