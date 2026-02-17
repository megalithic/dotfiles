/**
 * Sentinel — tiered command guardrails with override protocol.
 *
 * Tiers:
 *   HARD    — always blocked, no override
 *   CONFIRM — blocked, user says "override"/"bypass"/"force" → UI select prompt
 *   REWRITE — blocked with clear message to use preferred tool
 */
import type { ExtensionAPI, ToolCallEvent, ToolCallEventResult, InputEventResult } from "@mariozechner/pi-coding-agent";

type Tier = "hard" | "confirm" | "rewrite";

interface Rule {
  name: string;
  tier: Tier;
  tools: string[];
  test: (cmd: string, path?: string) => boolean;
  reason: string;
}

interface BlockedState {
  command: string;
  rule: string;
  reason: string;
  timestamp: number;
}

const OVERRIDE_TTL_MS = 120_000;
let blocked: BlockedState | null = null;
let overrideGranted = false;
let overrideAt = 0;

function log(msg: string) { console.log(`[sentinel] ${msg}`); }
function resetOverride() { overrideGranted = false; overrideAt = 0; }
function resetBlocked() { blocked = null; }

function grantOverride() {
  overrideGranted = true;
  overrideAt = Date.now();
  log("override granted");
}

function consumeOverride(): boolean {
  if (!overrideGranted) return false;
  if (Date.now() - overrideAt > OVERRIDE_TTL_MS) {
    log("override expired");
    resetOverride();
    return false;
  }
  log(`override consumed for: ${blocked?.command?.slice(0, 60)}`);
  resetOverride();
  resetBlocked();
  return true;
}

const HOME = process.env.HOME || "/Users/unknown";

function normalizePath(p: string): string {
  return p.replace(/^~\//, HOME + "/").replace(/^\$HOME\//, HOME + "/");
}

// ── Shell-aware parsing ──────────────────────────────────────────────────────

/**
 * Strip quoted strings and heredoc bodies so regex only matches shell commands,
 * not string literals. Replaces content with empty placeholders to preserve
 * structure (separators, positions).
 *
 * Handles: "...", '...', $'...', <<EOF...EOF, <<'EOF'...EOF, <<"EOF"...EOF
 * Also handles escaped quotes (\", \') inside double-quoted strings.
 */
function stripQuoted(cmd: string): string {
  let result = "";
  let i = 0;
  while (i < cmd.length) {
    // Heredoc: <<EOF, <<'EOF', <<"EOF", <<-EOF
    if (cmd[i] === "<" && cmd[i + 1] === "<" && cmd[i + 2] !== "<") {
      let j = i + 2;
      if (cmd[j] === "-") j++;
      const quoteChar = cmd[j] === "'" || cmd[j] === '"' ? cmd[j] : null;
      if (quoteChar) j++;
      let delim = "";
      while (j < cmd.length && /\w/.test(cmd[j])) delim += cmd[j++];
      if (quoteChar) j++; // closing quote around delimiter
      result += '<<""';
      // Skip to line matching delimiter
      const endPattern = "\n" + delim;
      const endIdx = cmd.indexOf(endPattern, j);
      i = endIdx === -1 ? cmd.length : endIdx + endPattern.length;
      continue;
    }

    // $'...' (ANSI-C quoting)
    if (cmd[i] === "$" && cmd[i + 1] === "'") {
      result += '""';
      i += 2;
      while (i < cmd.length && cmd[i] !== "'") {
        if (cmd[i] === "\\" && i + 1 < cmd.length) i++;
        i++;
      }
      i++; // closing '
      continue;
    }

    // Single-quoted string (no escapes inside)
    if (cmd[i] === "'") {
      result += '""';
      i++;
      while (i < cmd.length && cmd[i] !== "'") i++;
      i++; // closing '
      continue;
    }

    // Double-quoted string (backslash escapes)
    if (cmd[i] === '"') {
      result += '""';
      i++;
      while (i < cmd.length && cmd[i] !== '"') {
        if (cmd[i] === "\\" && i + 1 < cmd.length) i++;
        i++;
      }
      i++; // closing "
      continue;
    }

    result += cmd[i];
    i++;
  }
  return result;
}

/**
 * Extract command names at "command position" — the first word of each
 * pipeline segment. Splits on |, &&, ||, ;, and $( then returns the
 * first non-flag token of each segment.
 *
 * Example: `echo foo | grep bar && npm install` → ["echo", "grep", "npm"]
 */
function commandNames(stripped: string): string[] {
  // Split into segments at shell separators
  const segments = stripped.split(/\s*(?:\|\||&&|[|;]|\$\()\s*/);
  const names: string[] = [];
  for (const seg of segments) {
    const trimmed = seg.trim();
    if (!trimmed) continue;
    // Skip leading env assignments (FOO=bar) and sudo
    const tokens = trimmed.split(/\s+/);
    for (const tok of tokens) {
      if (/^\w+=/.test(tok)) continue; // env assignment
      if (tok === "sudo") continue;
      names.push(tok);
      break;
    }
  }
  return names;
}

/**
 * Test if a pattern matches at command position in a shell command.
 * First strips quoted strings, then checks command names + surrounding context.
 */
function cmdMatch(cmd: string, pattern: RegExp): boolean {
  return pattern.test(stripQuoted(cmd));
}

/**
 * Test if a word appears as a command (first token of a pipeline segment).
 * More precise than regex — won't match arguments or string contents.
 */
function isCommand(cmd: string, ...names: string[]): boolean {
  const cmds = commandNames(stripQuoted(cmd));
  return cmds.some(c => names.includes(c));
}

/**
 * Test if a multi-word command prefix appears at command position.
 * E.g., isCommandPrefix(cmd, "jj", "describe") matches `jj describe -m "foo"`
 * but not `echo "jj describe"`.
 */
function isCommandPrefix(cmd: string, ...prefix: string[]): boolean {
  const stripped = stripQuoted(cmd);
  const segments = stripped.split(/\s*(?:\|\||&&|[|;]|\$\()\s*/);
  for (const seg of segments) {
    const trimmed = seg.trim();
    if (!trimmed) continue;
    const tokens = trimmed.split(/\s+/).filter(t => !/^\w+=/.test(t));
    // Strip leading sudo
    const start = tokens[0] === "sudo" ? 1 : 0;
    let match = true;
    for (let i = 0; i < prefix.length; i++) {
      if (tokens[start + i] !== prefix[i]) { match = false; break; }
    }
    if (match && tokens.length >= start + prefix.length) return true;
  }
  return false;
}

/**
 * Get all tokens (non-quoted) for a segment starting with a given command prefix.
 * Useful for checking flags like -m, -u after the command.
 */
function segmentTokens(cmd: string, ...prefix: string[]): string[] | null {
  const stripped = stripQuoted(cmd);
  const segments = stripped.split(/\s*(?:\|\||&&|[|;]|\$\()\s*/);
  for (const seg of segments) {
    const trimmed = seg.trim();
    if (!trimmed) continue;
    const tokens = trimmed.split(/\s+/).filter(t => !/^\w+=/.test(t));
    const start = tokens[0] === "sudo" ? 1 : 0;
    let match = true;
    for (let i = 0; i < prefix.length; i++) {
      if (tokens[start + i] !== prefix[i]) { match = false; break; }
    }
    if (match && tokens.length >= start + prefix.length) return tokens.slice(start);
  }
  return null;
}

// ── Rules ────────────────────────────────────────────────────────────────────

const rules: Rule[] = [
  // ── HARD: interactive commands (would hang) ──
  {
    name: "jj-describe-no-msg",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => {
      const tokens = segmentTokens(cmd, "jj", "describe") || segmentTokens(cmd, "jj", "dm");
      return tokens !== null && !tokens.includes("-m");
    },
    reason: "Opens editor. Use `jj describe -m \"message\"`",
  },
  {
    name: "jj-commit-no-msg",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => {
      const tokens = segmentTokens(cmd, "jj", "commit");
      return tokens !== null && !tokens.includes("-m");
    },
    reason: "Opens editor. Use `jj commit -m \"message\"`",
  },
  {
    name: "jj-squash-no-msg",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => {
      const tokens = segmentTokens(cmd, "jj", "squash");
      if (!tokens) return false;
      return !tokens.includes("-m") && !tokens.includes("-u") && !tokens.includes("--use-destination-message");
    },
    reason: "May open editor. Use `-m \"message\"` or `-u`",
  },
  {
    name: "jj-split",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => isCommandPrefix(cmd, "jj", "split"),
    reason: "Inherently interactive. Use separate commits.",
  },
  {
    name: "jj-interactive-flag",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => {
      const stripped = stripQuoted(cmd);
      // Match jj <subcommand> ... -i or --interactive
      return /(?:^|\s)jj\s+\w+/.test(stripped) &&
        (/\s-i\b/.test(stripped) || /\s--interactive\b/.test(stripped));
    },
    reason: "Interactive flag. Use file paths instead.",
  },
  {
    name: "editor-invocation",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => isCommand(cmd, "vim", "nvim", "nano", "emacs", "vi"),
    reason: "Use Write/Edit tool or heredoc.",
  },
  {
    name: "secret-tools",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => isCommand(cmd, "pass", "gpg"),
    reason: "Secret tool access blocked.",
  },
  {
    name: "nix-managed-write",
    tier: "hard",
    tools: ["write", "edit"],
    test: (_cmd, path) => {
      if (!path) return false;
      const p = normalizePath(path);
      return [HOME + "/bin/", HOME + "/.config/", HOME + "/.hammerspoon/", HOME + "/.pi/agent/"]
        .some(m => p.startsWith(m));
    },
    reason: "Nix-managed path. Edit ~/.dotfiles/ source instead.",
  },

  // ── CONFIRM: destructive jj (can lose work or flatten history) ──
  {
    name: "jj-rebase",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => isCommandPrefix(cmd, "jj", "rebase"),
    reason: "Can discard uncommitted changes or flatten commit history.",
  },
  {
    name: "jj-abandon",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => isCommandPrefix(cmd, "jj", "abandon"),
    reason: "Permanently discards changes.",
  },
  {
    name: "jj-restore",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => isCommandPrefix(cmd, "jj", "restore"),
    reason: "Can overwrite uncommitted changes.",
  },
  {
    name: "jj-undo",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => isCommandPrefix(cmd, "jj", "undo"),
    reason: "Can affect uncommitted work.",
  },
  {
    name: "jj-squash-history",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => {
      const tokens = segmentTokens(cmd, "jj", "squash");
      if (!tokens) return false;
      return tokens.includes("-m") || tokens.includes("-u") || tokens.includes("--use-destination-message");
    },
    reason: "Squash flattens commit history.",
  },

  // ── CONFIRM: push / deploy / ssh ──
  {
    name: "push",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => isCommandPrefix(cmd, "jj", "push") || isCommandPrefix(cmd, "jj", "git", "push") || isCommandPrefix(cmd, "git", "push"),
    reason: "Push to remote.",
  },
  {
    name: "deploy",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => isCommand(cmd, "deploy", "vercel", "dokploy") ||
      isCommandPrefix(cmd, "fly", "deploy") ||
      isCommandPrefix(cmd, "netlify", "deploy") ||
      isCommandPrefix(cmd, "kubectl", "apply") ||
      isCommandPrefix(cmd, "terraform", "apply") ||
      isCommandPrefix(cmd, "pulumi", "up"),
    reason: "Deployment command.",
  },
  {
    name: "ssh",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => isCommand(cmd, "ssh", "scp") || isCommandPrefix(cmd, "rsync") && cmdMatch(cmd, /rsync\s+.*:/),
    reason: "Remote server access.",
  },

  // ── CONFIRM: non-nix package installs ──
  {
    name: "brew-install",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => isCommandPrefix(cmd, "brew", "install") || isCommandPrefix(cmd, "brew", "cask") || isCommandPrefix(cmd, "brew", "tap"),
    reason: "Non-nix install. Nix is the source of truth.",
  },
  {
    name: "global-pkg-install",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => {
      const stripped = stripQuoted(cmd);
      return /(?:^|[;&|]\s*)npm\s+(i|install)\s+(-g|--global)\b/.test(stripped) ||
        isCommandPrefix(cmd, "pip", "install") ||
        isCommandPrefix(cmd, "cargo", "install") ||
        isCommandPrefix(cmd, "go", "install");
    },
    reason: "Global package install. Check Nix first.",
  },
  {
    name: "project-pkg-install",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => {
      return isCommandPrefix(cmd, "npm", "install") ||
        isCommandPrefix(cmd, "npm", "i") ||
        isCommandPrefix(cmd, "npm", "add") ||
        isCommandPrefix(cmd, "yarn", "add") ||
        isCommandPrefix(cmd, "pnpm", "add") ||
        isCommandPrefix(cmd, "pnpm", "install") ||
        isCommandPrefix(cmd, "mix", "deps.get") ||
        isCommandPrefix(cmd, "cargo", "add") ||
        isCommandPrefix(cmd, "bun", "add") ||
        isCommandPrefix(cmd, "bun", "install");
    },
    reason: "Project dependency install. Verify not already available via Nix.",
  },
  {
    name: "npx-bunx",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => isCommand(cmd, "npx", "bunx"),
    reason: "Package runner. Prefer package.json scripts or Nix.",
  },

  // ── REWRITE: tool preferences (block with clear alternative) ──
  {
    name: "find→fd",
    tier: "rewrite",
    tools: ["bash"],
    test: (cmd) => isCommand(cmd, "find"),
    reason: "Use `fd` instead of `find`.",
  },
  {
    name: "grep→rg",
    tier: "rewrite",
    tools: ["bash"],
    test: (cmd) => isCommand(cmd, "grep"),
    reason: "Use `rg` instead of `grep`.",
  },
  {
    name: "rm→trash",
    tier: "rewrite",
    tools: ["bash"],
    test: (cmd) => isCommand(cmd, "rm", "rmdir"),
    reason: "Use `trash` instead of `rm`.",
  },
  {
    name: "git→jj",
    tier: "rewrite",
    tools: ["bash"],
    test: (cmd) => {
      // git as command, but not `jj git ...`
      if (!isCommand(cmd, "git")) return false;
      return !isCommandPrefix(cmd, "jj", "git");
    },
    reason: "Use `jj` instead of `git`.",
  },
];

// ── Extension ────────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  // Intercept user input for override keywords
  pi.on("input", async (event, ctx): Promise<InputEventResult | void> => {
    const text = event.text?.trim().toLowerCase() || "";

    const isOverride = ["override", "bypass", "force"].includes(text);
    const isForceOverride = ["!override", "!bypass", "!force"].includes(text);

    if (!isOverride && !isForceOverride) return;

    if (!blocked) {
      log(`${text}: nothing blocked`);
      return;
    }

    if (isForceOverride) {
      grantOverride();
      log(`${text}: immediate grant`);
      if (ctx.hasUI) ctx.ui.notify(`✓ Override granted for: ${blocked.rule}`, "info");
      return { action: "handled" };
    }

    // Regular override — show UI prompt
    if (ctx.hasUI) {
      const cmd = blocked.command;
      const choice = await ctx.ui.select(
        `⚠️  Override: ${blocked.rule}\n\n  ${cmd.slice(0, 120)}${cmd.length > 120 ? "..." : ""}\n\n${blocked.reason}\n\nAllow?`,
        ["Yes", "No"],
      );
      if (choice === "Yes") {
        grantOverride();
        ctx.ui.notify(`✓ Override granted for: ${blocked.rule}`, "info");
      } else {
        log("override rejected");
        resetBlocked();
      }
    } else {
      grantOverride();
      log("override: no UI, granted directly");
    }

    return { action: "handled" };
  });

  // Intercept tool calls
  pi.on("tool_call", async (event, _ctx): Promise<ToolCallEventResult | void> => {
    const toolName = event.toolName;
    const input = (event as ToolCallEvent).input;
    const cmd = (input as any).command as string || "";
    const path = (input as any).path as string || "";

    for (const rule of rules) {
      if (!rule.tools.includes(toolName)) continue;
      if (!rule.test(cmd, path)) continue;

      if (rule.tier === "hard") {
        log(`HARD [${rule.name}]: ${(cmd || path).slice(0, 60)}`);
        return { block: true, reason: `⛔ ${rule.reason}` };
      }

      if (rule.tier === "rewrite") {
        log(`REWRITE [${rule.name}]: ${cmd.slice(0, 60)}`);
        return { block: true, reason: `⚙️ ${rule.reason}` };
      }

      if (rule.tier === "confirm") {
        if (overrideGranted && blocked?.command === cmd) {
          if (consumeOverride()) return undefined;
        }

        blocked = { command: cmd, rule: rule.name, reason: rule.reason, timestamp: Date.now() };
        log(`CONFIRM [${rule.name}]: ${cmd.slice(0, 60)}`);
        return { block: true, reason: `🔒 **${rule.name}** — ${rule.reason}\n\nSay \`override\` to allow.` };
      }
    }

    return undefined;
  });

  (globalThis as Record<string, unknown>).__sentinel = {
    get blocked() { return blocked; },
    get overrideGranted() { return overrideGranted; },
    reset: () => { resetOverride(); resetBlocked(); },
    grant: grantOverride,
  };
}
