# Documentation Agent Operation Guide

This file consolidates the reusable operating guidance extracted from the RS documentation kit.

## Core approach

- Use the sample `.docx` template as the formatting source of truth.
- Prefer editing a template-driven document structure over recreating formatting from scratch.
- Validate the final `.docx` as a rendered Word document, not only by inspecting generated XML.
- Load the documentation job config or structured scenario input before generating output so repo knowledge is applied to the actual document scope.

## Screenshot rules

- Use the SAP Integration Suite web UI for trustworthy iFlow screenshots.
- Prefer Playwright or an equivalent controllable browser session.
- Use SAP designer canvas zoom controls deliberately; browser zoom alone is not enough.
- If the flow opens under SAP UI chrome, pan the canvas before capturing.
- Keep raw screenshots and cropped screenshots separate so cropping can be iterated without recapture.
- Crop whitespace, but never cut off process borders, labels, connectors, or participant boxes.

## Word formatting rules

- Check headers, footers, document properties, relationship targets, and custom XML for stale customer or project references.
- Keep version tables, authentication tables, figure captions, and table captions aligned to the template structure.
- When Word COM is unreliable for a task, patch OpenXML directly and then reopen/save in Word if needed.
- If the output file is locked, save a timestamped copy instead of forcing an overwrite.

## Parameter extraction rules

- Do not rely only on `param_references`.
- Use the ordered externalized parameter list from `parameters.propdef` as the primary source.
- Merge in `param_references` only as a supplement, then intersect with configured values from `parameters.prop`.
- If a documented artifact unexpectedly produces no parameters, first verify the artifact was actually unpacked and available to the generator.

## Captions and generated lists

- Put screenshots in image-only paragraphs and keep captions in separate `Caption` paragraphs.
- Ensure `Figure n` and `Table n` numbering is sequential with no gaps or duplicates.
- Validate `List of Figures` and `List of Tables` after field updates.
- If the generated list contains artifacts like `/Figure`, split mixed image/caption paragraphs rather than overwriting them blindly.

## Validation checklist

- Confirm the document opens cleanly.
- Confirm figure and table numbering is correct.
- Confirm embedded media still exists after caption and field updates.
- Confirm placeholder text that should remain visible is intentionally highlighted.
- Confirm the final document contains no stale customer or project references unless explicitly required.

## Knowledge maintenance

- If documentation generation reveals reusable Word, screenshot, cropping, or validation lessons, add them back into the repo knowledge files before finishing.
- Normalize useful legacy prompt content into repo-native guides so future sessions can start from Git alone.
