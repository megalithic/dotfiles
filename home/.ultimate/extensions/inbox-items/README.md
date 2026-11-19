Keeps actions, generated artifacts and shareable links in the project's Inbox until the user marks them Done.

## Tool

`inbox` is available to @ultimate and its branches, workers and side chats:

- `add {kind: 'action'|'artifact'|'link', title, text, url?, path?, key?}` → the item. Use actions for things the user must do later that need no answer; anything needing an answer stays a question message. Links need an HTTP(S) `url`; artifacts need an absolute `path` or `~/…`. Title and text are trimmed and limited to 120 and 8000 characters; longer values are rejected.
- `done {id}` → the completed item. Repeating it keeps the original completion time.
- `list` → open items.

A repeated `key` returns its retained item, even when done, without adding or changing anything. Keys leave with pruned done items. Replay uses the default `unsafe`: a key is optional, so an interrupted keyless add must not run twice.

Items record the calling conversation. For a side chat, the server reads the registered `sidechat` document by kind and snapshots its `of` field (the same lookup as Ultimate's `actingAs` helper), recording the main conversation instead. No runtime import from the Ultimate clone is needed.

## User actions

- `done {id}` completes the stored item.
- `open {id}` and `reveal {id}` open an artifact or reveal it in Finder, using macOS `open` and `open -R` through `execFile`, never a shell. Only the stored path is accepted; a leading `~` expands to the user's home directory.

All three are user-only actions. The pane renders Markdown with `MessageResponse`, including highlighted, copyable code blocks; links open in a new tab, artifacts offer Open, Reveal in Finder and Copy path, and every item has Done. Failures stay visible in the pane.

## Document and Inbox point

`inbox-items.items` is exported on the root conversation (`ROOT_CONVERSATION_ID`), with `{next, items}`. Each item stores `{id, kind, title, text, url?, path?, conversation, key?, at, done?}`; timestamps are epoch milliseconds. It uses `history: 'latest'`, `fork: 'initial'`, and retains all open items plus the 50 newest completions.

The browser reads that root document and provides open items to `inbox.items` with keys `inbox-items:<id>`, the kind as tag, the first text line as gist and the whole text as `text`, which the Inbox's follow-up side chat (side-chat's "Ask #id about this…") is told about. The Inbox supplies the title and Open in branch link; completing an item removes it from the provided list.
