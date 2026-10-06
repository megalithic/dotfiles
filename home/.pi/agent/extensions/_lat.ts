import { Type } from "@sinclair/typebox";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { getMarkdownTheme, keyHint } from "@mariozechner/pi-coding-agent";
import type { Theme } from "@mariozechner/pi-tui";
import { Box, Markdown, Text } from "@mariozechner/pi-tui";

const PREVIEW_LINES = 4;

function collapsibleResult(
  result: { content: Array<{ type: string; text?: string }> },
  options: { expanded: boolean; isPartial: boolean },
  theme: Theme,
) {
  const text =
    result.content?.[0]?.type === "text"
      ? (result.content[0] as { type: "text"; text: string }).text
      : "";
  if (!text) return new Text(theme.fg("dim", "(empty)"), 0, 0);
  if (options.isPartial) return new Text(theme.fg("dim", "…"), 0, 0);
  const mdTheme = getMarkdownTheme();
  if (options.expanded) return new Markdown(text, 0, 0, mdTheme);

  const lines = text.split("\n");
  if (lines.length <= PREVIEW_LINES) return new Markdown(text, 0, 0, mdTheme);

  const preview = lines.slice(0, PREVIEW_LINES).join("\n");
  const remaining = lines.length - PREVIEW_LINES;
  const hint = keyHint("expandTools", "to expand");
  return new Text(
    preview + "\n" + theme.fg("dim", `… ${remaining} more lines (${hint})`),
    0,
    0,
  );
}

/** Prefer the agent-managed lat binary over whatever PATH resolves first. */
const LAT =
  process.env.LAT_BIN ??
  (process.env.HOME ? `${process.env.HOME}/.pi/agent/bin/lat` : "lat");

function hasLatMd(from = process.cwd()): boolean {
  const { existsSync, statSync } =
    require("node:fs") as typeof import("node:fs");
  const { dirname, join, resolve } =
    require("node:path") as typeof import("node:path");
  let dir = resolve(from);

  while (true) {
    const candidate = join(dir, "lat.md");
    if (existsSync(candidate) && statSync(candidate).isDirectory()) return true;
    const parent = dirname(dir);
    if (parent === dir) return false;
    dir = parent;
  }
}

function run(args: string[], cwd?: string): string {
  const { execFileSync } =
    require("child_process") as typeof import("child_process");
  return execFileSync(LAT, args, {
    cwd: cwd ?? process.cwd(),
    encoding: "utf-8",
    timeout: 30_000,
    stdio: ["ignore", "pipe", "pipe"],
  });
}

type RunResult = { output: string; isError: boolean };

function tryRun(args: string[]): RunResult {
  try {
    return { output: run(args), isError: false };
  } catch (err: unknown) {
    const e = err as { stdout?: string; stderr?: string; message?: string };
    const output = [e.stdout, e.stderr]
      .filter((text): text is string => !!text?.trim())
      .join("\n")
      .trim();
    return {
      output: output || e.message || "lat command failed",
      isError: true,
    };
  }
}

export default function (pi: ExtensionAPI) {
  // ── Tools ──────────────────────────────────────────────────────────

  pi.registerTool({
    name: "lat_search",
    label: "lat search",
    description: "Semantic search across lat.md sections using embeddings",
    promptSnippet: "Search lat.md documentation by meaning",
    promptGuidelines: [
      "Use before starting any task to find relevant design context",
      "Search results include section IDs you can pass to lat_section",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Search query in natural language" }),
      limit: Type.Optional(
        Type.Number({ description: "Max results (default 5)", default: 5 }),
      ),
    }),
    async execute(_id, params) {
      const args = ["search", params.query];
      if (params.limit) args.push("--limit", String(params.limit));
      const result = tryRun(args);
      return {
        content: [{ type: "text", text: result.output || "No results found." }],
        isError: result.isError,
      };
    },
    renderCall(args, theme) {
      return new Text(
        theme.fg("toolTitle", theme.bold("lat search ")) +
          theme.fg("dim", `"${args.query}"`),
        0,
        0,
      );
    },
    renderResult: collapsibleResult,
  });

  pi.registerTool({
    name: "lat_section",
    label: "lat section",
    description:
      "Show full content of a lat.md section with outgoing/incoming refs",
    promptSnippet: "Read a specific lat.md section",
    parameters: Type.Object({
      query: Type.String({
        description: 'Section ID or name (e.g. "cli#init", "Tests#User login")',
      }),
    }),
    async execute(_id, params) {
      const result = tryRun(["section", params.query]);
      return {
        content: [
          { type: "text", text: result.output || "Section not found." },
        ],
        isError: result.isError,
      };
    },
    renderCall(args, theme) {
      return new Text(
        theme.fg("toolTitle", theme.bold("lat section ")) +
          theme.fg("dim", `"${args.query}"`),
        0,
        0,
      );
    },
    renderResult: collapsibleResult,
  });

  pi.registerTool({
    name: "lat_locate",
    label: "lat locate",
    description:
      "Find a section by name (exact, subsection tail, or fuzzy match)",
    promptSnippet: "Find a lat.md section by name",
    parameters: Type.Object({
      query: Type.String({ description: "Section name to locate" }),
    }),
    async execute(_id, params) {
      const result = tryRun(["locate", params.query]);
      return {
        content: [
          {
            type: "text",
            text: result.output || "No sections matching query.",
          },
        ],
        isError: result.isError,
      };
    },
    renderCall(args, theme) {
      return new Text(
        theme.fg("toolTitle", theme.bold("lat locate ")) +
          theme.fg("dim", `"${args.query}"`),
        0,
        0,
      );
    },
  });

  pi.registerTool({
    name: "lat_check",
    label: "lat check",
    description:
      "Validate all wiki links and code refs in lat.md. Returns errors or 'All checks passed'",
    promptSnippet: "Validate lat.md links and code refs",
    parameters: Type.Object({}),
    async execute() {
      try {
        const output = run(["check"]);
        return { content: [{ type: "text", text: output }] };
      } catch (err: unknown) {
        const e = err as { stdout?: string; stderr?: string };
        return {
          content: [
            { type: "text", text: e.stdout || e.stderr || "Check failed" },
          ],
          isError: true,
        };
      }
    },
    renderCall(_args, theme) {
      return new Text(theme.fg("toolTitle", theme.bold("lat check")), 0, 0);
    },
  });

  pi.registerTool({
    name: "lat_expand",
    label: "lat expand",
    description:
      "Expand [[refs]] in text to resolved file locations and context",
    promptSnippet: "Resolve [[wiki links]] in text",
    parameters: Type.Object({
      text: Type.String({ description: "Text containing [[refs]] to expand" }),
    }),
    async execute(_id, params) {
      const result = tryRun(["expand", params.text]);
      return {
        content: [{ type: "text", text: result.output || params.text }],
        isError: result.isError,
      };
    },
    renderCall(args, theme) {
      const preview =
        args.text.length > 60 ? args.text.slice(0, 60) + "…" : args.text;
      return new Text(
        theme.fg("toolTitle", theme.bold("lat expand ")) +
          theme.fg("dim", `"${preview}"`),
        0,
        0,
      );
    },
  });

  pi.registerTool({
    name: "lat_refs",
    label: "lat refs",
    description: "Find what references a given section",
    promptSnippet: "Find incoming references to a lat.md section",
    parameters: Type.Object({
      query: Type.String({
        description: 'Section ID (e.g. "cli#init", "file#Section")',
      }),
    }),
    async execute(_id, params) {
      const result = tryRun(["refs", params.query]);
      return {
        content: [
          { type: "text", text: result.output || "No references found." },
        ],
        isError: result.isError,
      };
    },
    renderCall(args, theme) {
      return new Text(
        theme.fg("toolTitle", theme.bold("lat refs ")) +
          theme.fg("dim", `"${args.query}"`),
        0,
        0,
      );
    },
  });

  // ── Message renderers ────────────────────────────────────────────

  pi.registerMessageRenderer("lat-reminder", (message, { expanded }, theme) => {
    const box = new Box(1, 1, (t) => theme.bg("customMessageBg", t));
    if (expanded) {
      box.addChild(new Text(theme.fg("accent", "lat.md"), 0, 0));
      box.addChild(new Markdown(message.content, 0, 0, getMarkdownTheme()));
    } else {
      const hint = keyHint("expandTools", "to expand");
      box.addChild(
        new Text(
          theme.fg("accent", "lat.md") +
            " " +
            theme.fg(
              "dim",
              `Search lat.md before starting work. Keep lat.md/ in sync. (${hint})`,
            ),
          0,
          0,
        ),
      );
    }
    return box;
  });

  pi.registerMessageRenderer("lat-check", (message, { expanded }, theme) => {
    const box = new Box(1, 1, (t) => theme.bg("customMessageBg", t));
    if (expanded) {
      box.addChild(new Text(theme.fg("warning", "lat check"), 0, 0));
      box.addChild(new Markdown(message.content, 0, 0, getMarkdownTheme()));
    } else {
      const hint = keyHint("expandTools", "to expand");
      const firstLine = message.content.split("\n")[0];
      box.addChild(
        new Text(
          theme.fg("warning", "lat check") +
            " " +
            theme.fg("dim", `${firstLine} (${hint})`),
          0,
          0,
        ),
      );
    }
    return box;
  });

  // ── Lifecycle hooks ────────────────────────────────────────────────

  // Hooks can be disabled per session via `/lat off` or LAT_HOOKS=off.
  let hooksEnabled = process.env.LAT_HOOKS !== "off";
  // Reminder fires once per session, not every turn.
  let reminderSent = false;
  // Guard to prevent agent_end from firing twice per prompt (infinite loop)
  let agentEndFired = false;
  // Only nag about lat.md sync when this session actually edited files.
  let sessionEdited = false;

  // Snapshot of dirty-worktree state at startup, so pre-existing
  // uncommitted changes don't count against the current session.
  function diffNumstat(): Map<string, number> {
    const result = new Map<string, number>();
    try {
      const { execSync } =
        require("child_process") as typeof import("child_process");
      const numstat = execSync("git diff HEAD --numstat", {
        encoding: "utf-8",
        cwd: process.cwd(),
        timeout: 10_000,
        stdio: ["ignore", "pipe", "pipe"],
      });
      for (const line of numstat.split("\n")) {
        const parts = line.split("\t");
        if (parts.length < 3) continue;
        const added = parseInt(parts[0], 10) || 0;
        const removed = parseInt(parts[1], 10) || 0;
        result.set(parts[2], added + removed);
      }
    } catch {
      // git not available or no HEAD
    }
    return result;
  }
  const baseline = hasLatMd() ? diffNumstat() : new Map<string, number>();

  pi.registerTool({
    name: "lat_hooks",
    label: "lat hooks",
    description:
      "Enable or disable lat.md lifecycle hooks (pre-work reminder, post-work lat check) for this session. Disable during pure-conversation workflows (e.g. grill-me interviews); re-enable when done.",
    parameters: Type.Object({
      enabled: Type.Boolean({
        description: "true = hooks on, false = hooks off",
      }),
    }),
    async execute(_id, params: { enabled: boolean }) {
      hooksEnabled = params.enabled;
      return {
        content: [
          {
            type: "text",
            text: `lat.md hooks ${hooksEnabled ? "enabled" : "disabled"} for this session.`,
          },
        ],
      };
    },
    renderCall(args: { enabled: boolean }, theme) {
      return new Text(
        theme.fg("toolTitle", theme.bold("lat hooks ")) +
          theme.fg("dim", args.enabled ? "on" : "off"),
        0,
        0,
      );
    },
  });

  pi.registerCommand("lat", {
    description: "Control lat.md hooks: /lat on | off | status",
    handler: async (args: string) => {
      const arg = (args || "").trim();
      if (arg === "on") {
        hooksEnabled = true;
      } else if (arg === "off") {
        hooksEnabled = false;
      }
      pi.sendMessage(
        {
          customType: "lat-reminder",
          content: `lat.md hooks: ${hooksEnabled ? "on" : "off"}`,
          display: true,
        },
        { deliverAs: "nextTurn" },
      );
    },
  });

  pi.on("tool_call", async (event: { toolName: string }) => {
    if (event.toolName === "edit" || event.toolName === "write") {
      sessionEdited = true;
    }
  });

  pi.on("before_agent_start", async () => {
    agentEndFired = false;

    if (!hasLatMd() || !hooksEnabled || reminderSent) return;
    reminderSent = true;

    const reminder = [
      "If this task involves understanding or changing code, run `lat_search` with queries describing the intent before diving in — results may reveal design details, protocols, or constraints.",
      "Use `lat_section` to read the full content of relevant matches.",
      "For pure conversation (interviews, brainstorming, Q&A about intent), skip lat tools and respond directly.",
      "",
      "Remember: `lat.md/` must stay in sync with the codebase. If you change code, update the relevant sections in `lat.md/` and run `lat_check` before finishing.",
    ].join("\n");

    return {
      message: {
        customType: "lat-reminder",
        content: reminder,
        display: true,
      },
    };
  });

  pi.on("agent_end", async () => {
    // Don't fire twice per prompt — prevents infinite loop
    if (agentEndFired) return;
    agentEndFired = true;

    // Skip entirely when hooks are off or this session never edited files
    // (read-only sessions must not be punished for a dirty worktree).
    if (!hasLatMd() || !hooksEnabled || !sessionEdited) return;

    // Run lat check
    let checkFailed = false;
    try {
      run(["check"]);
    } catch {
      checkFailed = true;
    }

    // Compare current diff against startup baseline — only count changes
    // made during this session.
    let needsSync = false;
    let codeLines = 0;
    {
      const current = diffNumstat();
      let latMdLines = 0;
      for (const [file, changed] of current) {
        const delta = Math.max(0, changed - (baseline.get(file) ?? 0));
        if (delta === 0) continue;
        if (file.startsWith("lat.md/")) {
          latMdLines += delta;
        } else if (/\.(ts|tsx|js|jsx|py|rs|go|c|h)$/.test(file)) {
          codeLines += delta;
        }
      }

      if (codeLines >= 5) {
        const effectiveLatMd = latMdLines === 0 ? 0 : Math.max(latMdLines, 1);
        needsSync = effectiveLatMd < codeLines * 0.05;
      }
    }

    if (!checkFailed && !needsSync) return;

    const parts: string[] = [];
    if (checkFailed && needsSync) {
      parts.push(
        `\`lat check\` found errors AND the codebase has changes (${codeLines} lines) with no updates to \`lat.md/\`. Before finishing:`,
        "",
        "1. Update `lat.md/` to reflect your code changes — run `lat_search` to find relevant sections.",
        "2. Run `lat_check` until it passes.",
      );
    } else if (checkFailed) {
      parts.push(
        "`lat check` failed. Run `lat_check`, fix the errors, and repeat until it passes.",
      );
    } else {
      parts.push(
        `The codebase has changes (${codeLines} lines) but \`lat.md/\` was not updated. Update \`lat.md/\` to be in sync with the changes — run \`lat_search\` to find relevant sections. Run \`lat_check\` at the end.`,
      );
    }

    pi.sendMessage(
      { customType: "lat-check", content: parts.join("\n"), display: true },
      { deliverAs: "followUp", triggerTurn: true },
    );
  });
}
