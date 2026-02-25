/**
 * Sentinel — tiered command guardrails with override protocol.
 *
 * Tiers:
 *   HARD    — always blocked, no override
 *   CONFIRM — blocked, user says "override"/"bypass"/"force" → UI select prompt
 *   REWRITE — blocked with clear message to use preferred tool
 *
 * Rules loaded from sentinel-rules.json (interactive commands, tool corrections).
 * Hardcoded rules remain for jj editor/message checks, secrets, nix-managed paths,
 * push/deploy/ssh, and package install guards.
 */
import type { ExtensionAPI, ToolCallEvent, ToolCallEventResult, InputEventResult } from "@mariozechner/pi-coding-agent";
import { readFileSync, existsSync } from "fs";
import { join, dirname } from "path";
import { execSync, spawnSync } from "child_process";

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

// ── Config types ─────────────────────────────────────────────────────────────

interface SubcommandEntry { flags: string[]; reason: string; }
interface InteractiveCommand { _doc?: string; subcommands: Record<string, SubcommandEntry>; }
interface AlwaysInteractiveEntry { reason: string; unless_args?: boolean; }
interface ToolCorrection { use: string; reason: string; except_prefix?: string[]; }
interface SentinelConfig {
  interactive_commands: Record<string, InteractiveCommand>;
  always_interactive: { commands: Record<string, AlwaysInteractiveEntry> };
  tool_corrections: Record<string, ToolCorrection>;
}

// ── State ────────────────────────────────────────────────────────────────────

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
 * not string literals.
 */
function stripQuoted(cmd: string): string {
  let result = "";
  let i = 0;
  while (i < cmd.length) {
    if (cmd[i] === "<" && cmd[i + 1] === "<" && cmd[i + 2] !== "<") {
      let j = i + 2;
      if (cmd[j] === "-") j++;
      const quoteChar = cmd[j] === "'" || cmd[j] === '"' ? cmd[j] : null;
      if (quoteChar) j++;
      let delim = "";
      while (j < cmd.length && /\w/.test(cmd[j])) delim += cmd[j++];
      if (quoteChar) j++;
      result += '<<""';
      const endPattern = "\n" + delim;
      const endIdx = cmd.indexOf(endPattern, j);
      i = endIdx === -1 ? cmd.length : endIdx + endPattern.length;
      continue;
    }
    if (cmd[i] === "$" && cmd[i + 1] === "'") {
      result += '""';
      i += 2;
      while (i < cmd.length && cmd[i] !== "'") {
        if (cmd[i] === "\\" && i + 1 < cmd.length) i++;
        i++;
      }
      i++;
      continue;
    }
    if (cmd[i] === "'") {
      result += '""';
      i++;
      while (i < cmd.length && cmd[i] !== "'") i++;
      i++;
      continue;
    }
    if (cmd[i] === '"') {
      result += '""';
      i++;
      while (i < cmd.length && cmd[i] !== '"') {
        if (cmd[i] === "\\" && i + 1 < cmd.length) i++;
        i++;
      }
      i++;
      continue;
    }
    result += cmd[i];
    i++;
  }
  return result;
}

/** Split stripped command into pipeline segments. */
function splitSegments(stripped: string): string[] {
  return stripped.split(/\s*(?:\|\||&&|[|;]|\$\()\s*/);
}

/** Extract command name (first non-env, non-sudo token) from each segment. */
function commandNames(stripped: string): string[] {
  const names: string[] = [];
  for (const seg of splitSegments(stripped)) {
    const trimmed = seg.trim();
    if (!trimmed) continue;
    for (const tok of trimmed.split(/\s+/)) {
      if (/^\w+=/.test(tok)) continue;
      if (tok === "sudo") continue;
      names.push(tok);
      break;
    }
  }
  return names;
}

/** Test if a pattern matches in stripped (non-quoted) command text. */
function cmdMatch(cmd: string, pattern: RegExp): boolean {
  return pattern.test(stripQuoted(cmd));
}

/** Test if any of the given names appear as a command (first token of a segment). */
function isCommand(cmd: string, ...names: string[]): boolean {
  return commandNames(stripQuoted(cmd)).some(c => names.includes(c));
}

/** Test if a multi-word prefix appears at command position in any segment. */
function isCommandPrefix(cmd: string, ...prefix: string[]): boolean {
  for (const seg of splitSegments(stripQuoted(cmd))) {
    const trimmed = seg.trim();
    if (!trimmed) continue;
    const tokens = trimmed.split(/\s+/).filter(t => !/^\w+=/.test(t));
    const start = tokens[0] === "sudo" ? 1 : 0;
    let match = true;
    for (let i = 0; i < prefix.length; i++) {
      if (tokens[start + i] !== prefix[i]) { match = false; break; }
    }
    if (match && tokens.length >= start + prefix.length) return true;
  }
  return false;
}

/** Get all tokens for a segment matching a command prefix. */
function segmentTokens(cmd: string, ...prefix: string[]): string[] | null {
  for (const seg of splitSegments(stripQuoted(cmd))) {
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

/**
 * Check if a command has arguments beyond the command name itself.
 * Used for "unless_args" commands like python/node that are only
 * interactive when invoked bare (no script/flags).
 */
function hasArgs(cmd: string, cmdName: string): boolean {
  const tokens = segmentTokens(cmd, cmdName);
  // tokens[0] is the command itself, anything after is an argument
  return tokens !== null && tokens.length > 1;
}

// ── Load config ──────────────────────────────────────────────────────────────

function loadConfig(): SentinelConfig {
  const configPath = join(dirname(new URL(import.meta.url).pathname), "sentinel-rules.json");
  try {
    const raw = readFileSync(configPath, "utf-8");
    const config = JSON.parse(raw) as SentinelConfig;
    log(`loaded config from ${configPath}`);
    return config;
  } catch (e) {
    log(`failed to load config: ${e}`);
    return {
      interactive_commands: {},
      always_interactive: { commands: {} },
      tool_corrections: {},
    };
  }
}

// ── Build rules from config ──────────────────────────────────────────────────

function buildRules(config: SentinelConfig): Rule[] {
  const rules: Rule[] = [];

  // ── HARD: interactive commands from config ──

  // Subcommand + flag based (jj squash -i, docker exec -it, etc.)
  for (const [tool, entry] of Object.entries(config.interactive_commands)) {
    for (const [sub, subEntry] of Object.entries(entry.subcommands || {})) {
      if (sub === "_doc") continue;

      if (sub === "__base__") {
        // Bare command is interactive (mysql, psql, iex, etc.)
        // flags array empty = always interactive; non-empty = only with those flags
        if (subEntry.flags.length === 0) {
          rules.push({
            name: `${tool}-interactive`,
            tier: "hard",
            tools: ["bash"],
            test: (cmd) => isCommand(cmd, tool),
            reason: `⛔ ${subEntry.reason}`,
          });
        } else {
          rules.push({
            name: `${tool}-interactive-flag`,
            tier: "hard",
            tools: ["bash"],
            test: (cmd) => {
              const tokens = segmentTokens(cmd, tool);
              return tokens !== null && subEntry.flags.some(f => tokens.includes(f));
            },
            reason: `⛔ ${subEntry.reason}`,
          });
        }
      } else {
        // Subcommand-specific flags
        if (subEntry.flags.length === 0) {
          // Subcommand is always interactive (e.g., nix repl)
          rules.push({
            name: `${tool}-${sub}-interactive`,
            tier: "hard",
            tools: ["bash"],
            test: (cmd) => isCommandPrefix(cmd, tool, sub),
            reason: `⛔ ${subEntry.reason}`,
          });
        } else {
          rules.push({
            name: `${tool}-${sub}-interactive-flag`,
            tier: "hard",
            tools: ["bash"],
            test: (cmd) => {
              const tokens = segmentTokens(cmd, tool, sub);
              return tokens !== null && subEntry.flags.some(f => tokens.includes(f));
            },
            reason: `⛔ ${subEntry.reason}`,
          });
        }
      }
    }
  }

  // Always-interactive commands (editors, REPLs, pagers)
  for (const [cmd, entry] of Object.entries(config.always_interactive.commands)) {
    if (cmd === "_doc") continue;
    rules.push({
      name: `${cmd}-interactive`,
      tier: "hard",
      tools: ["bash"],
      test: (c) => {
        if (!isCommand(c, cmd)) return false;
        // If unless_args is set, only block when invoked bare (no arguments)
        if (entry.unless_args) return !hasArgs(c, cmd);
        return true;
      },
      reason: `⛔ ${entry.reason}`,
    });
  }

  // ── HARD: jj editor rules (not in config — logic too specific) ──

  rules.push({
    name: "jj-describe-no-msg",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => {
      const tokens = segmentTokens(cmd, "jj", "describe") || segmentTokens(cmd, "jj", "dm");
      return tokens !== null && !tokens.includes("-m");
    },
    reason: "⛔ Opens editor. Use `jj describe -m \"message\"`",
  });

  rules.push({
    name: "jj-commit-no-msg",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => {
      const tokens = segmentTokens(cmd, "jj", "commit");
      return tokens !== null && !tokens.includes("-m");
    },
    reason: "⛔ Opens editor. Use `jj commit -m \"message\"`",
  });

  rules.push({
    name: "jj-squash-no-msg",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => {
      const tokens = segmentTokens(cmd, "jj", "squash");
      if (!tokens) return false;
      return !tokens.includes("-m") && !tokens.includes("-u") && !tokens.includes("--use-destination-message");
    },
    reason: "⛔ May open editor. Use `-m \"message\"` or `-u`",
  });

  rules.push({
    name: "jj-split",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => isCommandPrefix(cmd, "jj", "split"),
    reason: "⛔ Inherently interactive. Use separate commits.",
  });

  // ── HARD: secrets ──

  rules.push({
    name: "secret-tools",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => isCommand(cmd, "pass", "gpg"),
    reason: "⛔ Secret tool access blocked.",
  });

  // ── HARD: nix-managed path writes ──

  rules.push({
    name: "nix-managed-write",
    tier: "hard",
    tools: ["write", "edit"],
    test: (_cmd, path) => {
      if (!path) return false;
      const p = normalizePath(path);
      return [HOME + "/bin/", HOME + "/.config/", HOME + "/.hammerspoon/", HOME + "/.pi/agent/"]
        .some(m => p.startsWith(m));
    },
    reason: "⛔ Nix-managed path. Edit ~/.dotfiles/ source instead.",
  });

  // ── CONFIRM: destructive jj ──

  for (const [sub, reason] of Object.entries({
    "rebase": "Can discard uncommitted changes or flatten commit history.",
    "abandon": "Permanently discards changes.",
    "restore": "Can overwrite uncommitted changes.",
    "undo": "Can affect uncommitted work.",
  } as Record<string, string>)) {
    rules.push({
      name: `jj-${sub}`,
      tier: "confirm",
      tools: ["bash"],
      test: (cmd) => isCommandPrefix(cmd, "jj", sub),
      reason,
    });
  }

  rules.push({
    name: "jj-squash-history",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => {
      const tokens = segmentTokens(cmd, "jj", "squash");
      if (!tokens) return false;
      
      // Safe: simple squash (@ into @-) with any message options
      // Only block when --from, --into, or -r is used with potentially broad revsets
      const hasFrom = tokens.includes("--from") || tokens.includes("-f");
      const hasInto = tokens.includes("--into") || tokens.includes("--to") || tokens.includes("-t");
      const hasRevision = tokens.includes("-r") || tokens.includes("--revision");
      const hasDestination = tokens.includes("-d") || tokens.includes("--destination");
      const hasInsertAfter = tokens.includes("-A") || tokens.includes("--insert-after");
      const hasInsertBefore = tokens.includes("-B") || tokens.includes("--insert-before");
      
      // If none of these multi-commit options are present, it's a simple squash (safe)
      if (!hasFrom && !hasInto && !hasRevision && !hasDestination && !hasInsertAfter && !hasInsertBefore) {
        return false;
      }
      
      // Block if any of these potentially dangerous options are used
      // User can override if they know what they're doing
      return true;
    },
    reason: "Squash with --from/--into/-r can flatten history. Simple `jj squash` is safe.",
  });

  // ── HARD: gatekeeper (secrets in diff) ──
  
  // Store gatekeeper findings for error message
  let gatekeeperFindings = "";
  
  function isPushCommand(cmd: string): boolean {
    return isCommandPrefix(cmd, "jj", "push") || 
           isCommandPrefix(cmd, "jj", "git", "push") || 
           isCommandPrefix(cmd, "git", "push");
  }
  
  function checkDiffForSecrets(): { blocked: boolean; findings: string } {
    // Check if gatekeeper is available
    try {
      execSync("which gatekeeper", { encoding: "utf-8", stdio: "pipe" });
    } catch {
      log("gatekeeper not found, skipping secrets check");
      return { blocked: false, findings: "" };
    }
    
    // Get the diff
    let diff = "";
    try {
      diff = execSync("jj diff --git 2>/dev/null || git diff HEAD 2>/dev/null || echo ''", {
        encoding: "utf-8",
        timeout: 10000,
        stdio: ["pipe", "pipe", "pipe"],
      });
    } catch (e) {
      log("failed to get diff for gatekeeper check");
      return { blocked: false, findings: "" };
    }
    
    if (!diff.trim()) {
      return { blocked: false, findings: "" };
    }
    
    // Run gatekeeper on the diff
    try {
      const result = spawnSync("gatekeeper", ["--stdin", "--severity=high"], {
        input: diff,
        encoding: "utf-8",
        timeout: 30000,
      });
      
      if (result.status === 2) {
        // Blocked - secrets found
        return { blocked: true, findings: result.stdout || "Secrets detected" };
      }
      return { blocked: false, findings: "" };
    } catch (e) {
      log(`gatekeeper error: ${e}`);
      return { blocked: false, findings: "" };
    }
  }
  
  rules.push({
    name: "gatekeeper-secrets",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => {
      if (!isPushCommand(cmd)) return false;
      
      const check = checkDiffForSecrets();
      if (check.blocked) {
        gatekeeperFindings = check.findings;
        return true;
      }
      return false;
    },
    get reason() {
      return `⛔ **Secrets detected in diff!**\n\n\`\`\`\n${gatekeeperFindings}\`\`\`\n\n**Remove the secrets before pushing.** This cannot be overridden.`;
    },
  });

  // ── CONFIRM: push / deploy / ssh ──

  rules.push({
    name: "push",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => isPushCommand(cmd),
    reason: "Push to remote.",
  });

  rules.push({
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
  });

  rules.push({
    name: "ssh",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => isCommand(cmd, "ssh", "scp") || (isCommandPrefix(cmd, "rsync") && cmdMatch(cmd, /rsync\s+.*:/)),
    reason: "Remote server access.",
  });

  // ── CONFIRM: non-nix package installs ──

  rules.push({
    name: "brew-install",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => isCommandPrefix(cmd, "brew", "install") || isCommandPrefix(cmd, "brew", "cask") || isCommandPrefix(cmd, "brew", "tap"),
    reason: "Non-nix install. Nix is the source of truth.",
  });

  rules.push({
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
  });

  rules.push({
    name: "project-pkg-install",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => {
      // mix deps.get is always allowed - standard Elixir workflow
      if (isCommandPrefix(cmd, "mix", "deps.get")) return false;
      return isCommandPrefix(cmd, "npm", "install") ||
        isCommandPrefix(cmd, "npm", "i") ||
        isCommandPrefix(cmd, "npm", "add") ||
        isCommandPrefix(cmd, "yarn", "add") ||
        isCommandPrefix(cmd, "pnpm", "add") ||
        isCommandPrefix(cmd, "pnpm", "install") ||
        isCommandPrefix(cmd, "cargo", "add") ||
        isCommandPrefix(cmd, "bun", "add") ||
        isCommandPrefix(cmd, "bun", "install");
    },
    reason: "Project dependency install. Verify not already available via Nix.",
  });

  rules.push({
    name: "npx-bunx",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => isCommand(cmd, "npx", "bunx"),
    reason: "Package runner. Prefer package.json scripts or Nix.",
  });

  // ── REWRITE: tool corrections from config ──

  for (const [blocked, correction] of Object.entries(config.tool_corrections)) {
    if (blocked === "_doc") continue;
    rules.push({
      name: `${blocked}→${correction.use}`,
      tier: "rewrite",
      tools: ["bash"],
      test: (cmd) => {
        if (!isCommand(cmd, blocked)) return false;
        // Exception: don't flag `git` when it's part of `jj git ...`
        if (correction.except_prefix) {
          if (isCommandPrefix(cmd, ...correction.except_prefix)) return false;
        }
        return true;
      },
      reason: correction.reason,
    });
  }

  return rules;
}

// ── Extension ────────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  const config = loadConfig();
  const rules = buildRules(config);
  log(`${rules.length} rules loaded`);

  // Intercept user input for override keywords
  pi.on("input", async (event, ctx): Promise<InputEventResult | void> => {
    const text = event.text?.trim().toLowerCase() || "";

    const isOverrideCmd = ["override", "bypass", "force"].includes(text);
    const isForceOverride = ["!override", "!bypass", "!force"].includes(text);

    if (!isOverrideCmd && !isForceOverride) return;

    if (!blocked) {
      log(`${text}: nothing blocked`);
      return;
    }

    const blockedCmd = blocked.command;
    const blockedRule = blocked.rule;

    if (isForceOverride) {
      grantOverride();
      log(`${text}: immediate grant`);
      if (ctx.hasUI) ctx.ui.notify(`✓ Override granted for: ${blockedRule}`, "info");
      // Signal agent to retry the blocked command
      pi.sendMessage({
        customType: "sentinel_override",
        content: `✓ Override granted for **${blockedRule}**. Retry the command now.`,
        display: "user",
      }, { triggerTurn: true });
      return { action: "handled" };
    }

    if (ctx.hasUI) {
      const choice = await ctx.ui.select(
        `⚠️  Override: ${blockedRule}\n\n  ${blockedCmd.slice(0, 120)}${blockedCmd.length > 120 ? "..." : ""}\n\n${blocked.reason}\n\nAllow?`,
        ["Yes", "No"],
      );
      if (choice === "Yes") {
        grantOverride();
        ctx.ui.notify(`✓ Override granted for: ${blockedRule}`, "info");
        // Signal agent to retry the blocked command
        pi.sendMessage({
          customType: "sentinel_override",
          content: `✓ Override granted for **${blockedRule}**. Retry the command now.`,
          display: "user",
        }, { triggerTurn: true });
      } else {
        log("override rejected");
        resetBlocked();
      }
    } else {
      grantOverride();
      log("override: no UI, granted directly");
      // Signal agent to retry
      pi.sendMessage({
        customType: "sentinel_override",
        content: `✓ Override granted for **${blockedRule}**. Retry the command now.`,
        display: "user",
      }, { triggerTurn: true });
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
        return { block: true, reason: rule.reason };
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
        const cmdPreview = cmd.length > 200 ? cmd.slice(0, 200) + "..." : cmd;
        return {
          block: true,
          reason: `🔒 **${rule.name}** — ${rule.reason}

**Command:** \`${cmdPreview}\`

**Agent:** Before asking for override, explain to the user:
1. What this command does
2. Why it was blocked (${rule.reason})
3. Whether it's safe to override in this context

Say \`override\` to allow.`
        };
      }
    }

    return undefined;
  });

  (globalThis as Record<string, unknown>).__sentinel = {
    get blocked() { return blocked; },
    get overrideGranted() { return overrideGranted; },
    rules: rules.map(r => r.name),
    reset: () => { resetOverride(); resetBlocked(); },
    grant: grantOverride,
  };
}
