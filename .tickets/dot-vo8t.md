---
id: dot-vo8t
status: closed
deps: 4:1:deps: [, dot-mg2c]
links: []
created: 2026-06-09T15:10:55Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development, shade-next]
---

# Implement blob metadata and edge model

In ~/code/shade-next, add content-addressed blob metadata and relationship edges for attachments and future transforms. Cover metadata storage plus edge types such as thumbnail_of, converted_to, and extracted_text_from. File hints: blob store modules under ~/code/shade-next/Sources/ and related tests under ~/code/shade-next/Tests/.

## Acceptance Criteria

1. Schema and code support blob metadata records and blob edge relationships.
2. Blob layout targets ~/.local/share/shade-next/blobs/sha256/... or equivalent configured content-addressed path.
3. Tests cover blob metadata creation and at least one edge relationship round-trip.
4. Existing persistence tests still pass.
5. Ticket notes identify any deferred blob file IO concerns separately from metadata work.
