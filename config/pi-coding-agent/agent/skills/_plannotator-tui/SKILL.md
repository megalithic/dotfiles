---
name: plannotator-tui
description: Open a Markdown plan or document in the terminal for interactive review and annotations. Use when the user asks to review a plan in plannotator-tui, or to annotate a Pi reply with plannotator-tui in tmux.
---

# Plannotator TUI

Use Plannotator TUI's standalone mode. This setup runs Pi in tmux, not Herdr.

## Review a file

1. Write the plan or document to a stable Markdown file. Keep secrets and private infrastructure identifiers out of the artifact.
2. Open the file in an interactive overlay:

   ```text
   interactive_shell({
     command: "plannotator-tui /absolute/path/to/plan.md",
     cwd: "/path/to/project",
     mode: "dispatch",
     reason: "Reviewing plan in plannotator-tui",
     handsFree: { autoExitOnQuiet: false }
   })
   ```

3. End the turn. Do not poll. The user selects text and adds notes with `c`, marks approval with `a`, or marks deletion with `d`. They press `q` when finished.
4. After the completion notification, export the active annotations:

   ```bash
   plannotator-tui --export /absolute/path/to/plan.md
   ```

5. Address every exported annotation. An empty export means no active annotations.

Annotations persist under Plannotator's data directory, not beside the reviewed file. Standalone `E` copies feedback to the terminal clipboard; it does not send feedback to Pi. Export after exit instead.

## Review Pi replies

Use Pi's upstream-supported transcript reader:

```bash
plannotator-tui last --host pi
```

For an exact transcript when `PI_SESSION_FILE` is available:

```bash
plannotator-tui last --host pi --session "$PI_SESSION_FILE"
```

Reply reviews are transient and cannot be exported after exit. Press `E` to copy their feedback, quit with `q`, then paste the copied feedback into Pi.

## Do not

- Do not run `plannotator-tui herdr ...`; this setup does not use Herdr.
- Do not launch the interactive TUI with the non-interactive bash tool.
- Do not claim standalone `E` sends feedback directly to Pi.
- Do not put tokens, private addresses, tailnet names, or other secrets in review artifacts.
