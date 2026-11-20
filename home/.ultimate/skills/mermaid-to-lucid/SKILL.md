---
name: mermaid-to-lucid
description: Put existing Mermaid diagrams (.mmd files, Mermaid blocks in lat.md or other docs) into Lucidchart through executor's `lucid` app. Use when someone asks to export, import, send, publish or share Mermaid in Lucid or Lucidchart.
---

# Mermaid to Lucid

Executor-local (the `executor` MCP server) has a `lucid` app: Lucid's official MCP server (`https://mcp.lucid.app/mcp`), signed in with Seth's work Lucid account over OAuth. Every call that is not read-only asks Seth for approval first.

## Steps

1. Take the Mermaid as it is: the `.mmd` file or the fenced `mermaid` block. Do not redraw it with Lucid's native tools. Lucid's own guidance says to build diagrams natively; here the Mermaid is the source of truth, so send it unchanged.
2. Find the account and the exact path:
   `search {query: "mermaid", namespace: "lucid"}` returns `tools.lucid.lucid_create_diagram_from_mermaid` and the account ID in its input type.
3. Call it:
   ```json
   {"path": "tools.lucid.lucid_create_diagram_from_mermaid",
    "input": {"accountId": "<from search>",
              "input": {"title": "<doc or diagram name>", "mermaid_markup": "<the Mermaid>", "product": "lucidchart"}}}
   ```
   For sequence diagrams and ERDs, Lucid offers `lucid_create_sequence_diagram` (PlantUML) and `lucid_create_erd` instead. Still send Mermaid to `lucid_create_diagram_from_mermaid` unless the person asks for those.
4. The call returns `approval-required` with an `approvalUrl`. Give Seth that link and stop. After he approves, call `resume {requestId}`. Never repeat the call.
5. Reply with the document's title and `editUrl` from the result, and ask Seth to open it once. Lucid creates a native Mermaid block that stays empty ("Mermaid Diagram Zero State") until the document is first opened in the editor; only then does it become shapes. A PNG export (`lucid_export_document_as_PNG {document_id}`, read-only) before that is blank, so check it only after he has opened it.

## When it fails

- No `lucid` tools, or the account is unhealthy (`tools.executor.appAccounts.userList {path: {app: "lucid"}}`): the sign-in expired or was revoked. Get a new connect link with `tools.executor.appAccounts.userConnect {path: {app: "lucid", requirement: "lucid"}, body: {account: "<account id>"}}` and give Seth the URL.
- Lucid refuses because MCP access is off: only his Lucid admin can turn it on (Admin → Security → AI controls → MCP access). Until then, write `.mmd` files and tell Seth to paste them into Lucid's **Diagram as code → Mermaid** panel.
- Markup limit: about 50,000 characters per diagram. Split larger diagrams.

The app is set up per Mac, in executor's own data. On megabookpro, add it once with the dashboard's quick add for `https://mcp.lucid.app/mcp` and sign in.
