---
id: dot-7yvx
status: open
deps: 4:1:deps: [, dot-7ioi]
links: []
created: 2026-06-10T16:55:32Z
type: feature
priority: 3
assignee: Seth Messer
tags: [shade-next, phase-3]
---

# Add image conversion previews to shade-next

Implement a follow-up workflow for converting one image type to another from shade-next and previewing original vs converted output. Use the preview primitives from dot-7ioi: store generated preview metadata in the SQLite results table, render preview rows in the panel overview, and keep binary data in BlobStore rather than notes. Relevant files: ~/code/shade-next/Sources/ShadeNextCore/Persistence/BlobStore.swift, Schema.swift results/blobs tables, PanelOverview.swift, PanelController.swift, and the shade-next app command/routing layer.

## Acceptance Criteria

1. A route or command can request an image conversion with explicit source and target formats.
2. Original and converted image metadata are stored through BlobStore/results so the panel can render a before/after preview row.
3. The UI shows enough preview context to compare original vs converted output before commit or save.
4. Conversion failures show a non-destructive error and do not modify the notes vault.
5. Existing shade-next tests pass, and new tests cover conversion metadata/result rendering.
