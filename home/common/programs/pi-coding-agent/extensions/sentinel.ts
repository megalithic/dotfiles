/**
 * Sentinel — tiered command guardrails with override protocol.
 *
 * Tiers:
 *   HARD    — always blocked, no override
 *   CONFIRM — blocked, user says "override"/"bypass"/"force" → UI select prompt
 *   REWRITE — blocked with clear message to use preferred tool
 *
 * Rules are bundled in this extension so activation has one source of truth.
 * Specialized logic remains for jj editor/message checks, secrets,
 * nix-managed paths, push/deploy/ssh, package install guards, investigation mode,
 * and pipe/redirect hang prevention.
 */
import type {
  ExtensionAPI,
  ToolCallEvent,
  ToolCallEventResult,
  InputEventResult,
} from "@earendil-works/pi-coding-agent";
import { existsSync } from "fs";
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

// ── Bundled rules ────────────────────────────────────────────────────────────

const INTERACTIVE_COMMANDS: Record<
  string,
  Record<string, { flags: string[]; reason: string }>
> = {
  jj: {
    squash: {
      flags: ["-i", "--interactive"],
      reason: "Interactive diff selection. Use file paths instead.",
    },
    commit: {
      flags: ["-i", "--interactive"],
      reason: "Interactive diff selection. Use file paths instead.",
    },
    restore: {
      flags: ["-i", "--interactive"],
      reason: "Interactive diff selection. Use file paths instead.",
    },
  },
  docker: {
    exec: {
      flags: ["-it", "-i", "--interactive"],
      reason:
        "Allocates interactive TTY. Use non-interactive: `docker exec <container> <cmd>`.",
    },
    run: {
      flags: ["-it", "-i", "--interactive"],
      reason:
        "Allocates interactive TTY. Use non-interactive: `docker run <image> <cmd>`.",
    },
  },
  kubectl: {
    exec: {
      flags: ["-it", "-i", "--stdin"],
      reason:
        "Opens interactive shell in pod. Use: `kubectl exec <pod> -- <cmd>`.",
    },
    run: {
      flags: ["-it", "-i", "--stdin"],
      reason:
        "Opens interactive shell. Use: `kubectl run --rm --restart=Never <name> --image=<img> -- <cmd>`.",
    },
    attach: {
      flags: ["-it", "-i", "--stdin"],
      reason: "Attaches to running process. Use `kubectl logs` instead.",
    },
  },
  nix: {
    repl: {
      flags: [],
      reason: "Opens interactive REPL. Use `nix eval` instead.",
    },
  },
  mysql: {
    __base__: {
      flags: [],
      reason: 'Opens interactive shell. Use: `mysql -e "<query>"`.',
    },
  },
  psql: {
    __base__: {
      flags: [],
      reason: 'Opens interactive shell. Use: `psql -c "<query>"`.',
    },
  },
  sqlite3: {
    __base__: {
      flags: [],
      reason: "Opens interactive shell. Pass SQL directly or use `.read`.",
    },
  },
  iex: {
    __base__: {
      flags: [],
      reason: "Opens interactive REPL. Use `elixir -e` or `mix run --eval`.",
    },
  },
  irb: {
    __base__: {
      flags: [],
      reason: "Opens interactive REPL. Use `ruby -e`.",
    },
  },
};

const ALWAYS_INTERACTIVE_COMMANDS: Record<
  string,
  { reason: string; unlessArgs?: boolean }
> = {
  vim: { reason: "Use Write/Edit tool or heredoc.", unlessArgs: true },
  nvim: { reason: "Use Write/Edit tool or heredoc.", unlessArgs: true },
  nano: { reason: "Use Write/Edit tool or heredoc.", unlessArgs: true },
  emacs: { reason: "Use Write/Edit tool or heredoc.", unlessArgs: true },
  vi: { reason: "Use Write/Edit tool or heredoc.", unlessArgs: true },
  less: { reason: "Use Read tool or `head`/`tail`." },
  more: { reason: "Use Read tool or `head`/`tail`." },
  top: { reason: "Use `ps aux` or `ps aux --sort=-%mem`." },
  htop: { reason: "Use `ps aux` or `ps aux --sort=-%mem`." },
  python: {
    reason: "Opens REPL. Use `python -c` or `python script.py`.",
    unlessArgs: true,
  },
  python3: {
    reason: "Opens REPL. Use `python3 -c` or `python3 script.py`.",
    unlessArgs: true,
  },
  node: {
    reason: "Opens REPL. Use `node -e` or `node script.js`.",
    unlessArgs: true,
  },
  lua: {
    reason: "Opens REPL. Use `lua -e` or `lua script.lua`.",
    unlessArgs: true,
  },
};

const TOOL_CORRECTIONS: Record<
  string,
  {
    use: string;
    reason: string;
    exceptPrefix?: string[];
    onlyIfRootDir?: string;
  }
> = {
  find: { use: "fd", reason: "Use `fd` instead of `find`." },
  grep: { use: "rg", reason: "Use `rg` instead of `grep`." },
  rm: { use: "trash", reason: "Use `trash` instead of `rm`." },
  rmdir: { use: "trash", reason: "Use `trash` instead of `rmdir`." },
  git: {
    use: "jj",
    reason: "Use `jj` instead of `git`.",
    exceptPrefix: ["jj", "git"],
    onlyIfRootDir: ".jj",
  },
};

// ── State ────────────────────────────────────────────────────────────────────

const OVERRIDE_TTL_MS = 120_000;
let blocked: BlockedState | null = null;
let overrideGranted = false;
let overrideAt = 0;

function log(msg: string) {
  console.log(`[sentinel] ${msg}`);
}
function resetOverride() {
  overrideGranted = false;
  overrideAt = 0;
}
function resetBlocked() {
  blocked = null;
}

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
    // Heredoc detection: <<, <<-, << 'DELIM', << "DELIM", << DELIM
    if (cmd[i] === "<" && cmd[i + 1] === "<" && cmd[i + 2] !== "<") {
      let j = i + 2;
      // Handle <<- (strip leading tabs)
      if (cmd[j] === "-") j++;
      // Skip whitespace between << and delimiter
      while (j < cmd.length && (cmd[j] === " " || cmd[j] === "\t")) j++;
      // Check for quoted delimiter
      const quoteChar = cmd[j] === "'" || cmd[j] === '"' ? cmd[j] : null;
      if (quoteChar) j++;
      // Extract delimiter word
      let delim = "";
      while (j < cmd.length && /\w/.test(cmd[j])) delim += cmd[j++];
      if (quoteChar) j++;
      // Skip to end of heredoc if we found a valid delimiter
      if (delim) {
        result += '<<""';
        const endPattern = "\n" + delim;
        const endIdx = cmd.indexOf(endPattern, j);
        i = endIdx === -1 ? cmd.length : endIdx + endPattern.length;
        continue;
      }
      // No valid delimiter found, treat as regular text
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
  return commandNames(stripQuoted(cmd)).some((c) => names.includes(c));
}

/** Test if a multi-word prefix appears at command position in any segment. */
function isCommandPrefix(cmd: string, ...prefix: string[]): boolean {
  for (const seg of splitSegments(stripQuoted(cmd))) {
    const trimmed = seg.trim();
    if (!trimmed) continue;
    const tokens = trimmed.split(/\s+/).filter((t) => !/^\w+=/.test(t));
    const start = tokens[0] === "sudo" ? 1 : 0;
    let match = true;
    for (let i = 0; i < prefix.length; i++) {
      if (tokens[start + i] !== prefix[i]) {
        match = false;
        break;
      }
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
    const tokens = trimmed.split(/\s+/).filter((t) => !/^\w+=/.test(t));
    const start = tokens[0] === "sudo" ? 1 : 0;
    let match = true;
    for (let i = 0; i < prefix.length; i++) {
      if (tokens[start + i] !== prefix[i]) {
        match = false;
        break;
      }
    }
    if (match && tokens.length >= start + prefix.length)
      return tokens.slice(start);
  }
  return null;
}

/**
 * Check if a command has arguments beyond the command name itself.
 * Used for "unlessArgs" commands like python/node that are only
 * interactive when invoked bare (no script/flags).
 */
function hasArgs(cmd: string, cmdName: string): boolean {
  const tokens = segmentTokens(cmd, cmdName);
  // tokens[0] is the command itself, anything after is an argument
  return tokens !== null && tokens.length > 1;
}

// ── Build rules ──────────────────────────────────────────────────────────────

function buildRules(): Rule[] {
  const rules: Rule[] = [];

  // ── HARD: interactive commands ──

  // Subcommand + flag based (jj squash -i, docker exec -it, etc.)
  for (const [tool, subcommands] of Object.entries(INTERACTIVE_COMMANDS)) {
    for (const [sub, subEntry] of Object.entries(subcommands)) {
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
              return (
                tokens !== null &&
                subEntry.flags.some((f) => tokens.includes(f))
              );
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
              return (
                tokens !== null &&
                subEntry.flags.some((f) => tokens.includes(f))
              );
            },
            reason: `⛔ ${subEntry.reason}`,
          });
        }
      }
    }
  }

  // Always-interactive commands (editors, REPLs, pagers)
  for (const [cmd, entry] of Object.entries(ALWAYS_INTERACTIVE_COMMANDS)) {
    rules.push({
      name: `${cmd}-interactive`,
      tier: "hard",
      tools: ["bash"],
      test: (c) => {
        if (!isCommand(c, cmd)) return false;
        // If unlessArgs is set, only block when invoked bare (no arguments)
        if (entry.unlessArgs) return !hasArgs(c, cmd);
        return true;
      },
      reason: `⛔ ${entry.reason}`,
    });
  }

  // ── HARD: jj editor rules (logic too specific for table-driven rules) ──

  rules.push({
    name: "jj-describe-no-msg",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => {
      const tokens =
        segmentTokens(cmd, "jj", "describe") || segmentTokens(cmd, "jj", "dm");
      return tokens !== null && !tokens.includes("-m");
    },
    reason: '⛔ Opens editor. Use `jj describe -m "message"`',
  });

  rules.push({
    name: "jj-commit-no-msg",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => {
      const tokens = segmentTokens(cmd, "jj", "commit");
      return tokens !== null && !tokens.includes("-m");
    },
    reason: '⛔ Opens editor. Use `jj commit -m "message"`',
  });

  rules.push({
    name: "jj-squash-no-msg",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => {
      const tokens = segmentTokens(cmd, "jj", "squash");
      if (!tokens) return false;
      return (
        !tokens.includes("-m") &&
        !tokens.includes("-u") &&
        !tokens.includes("--use-destination-message")
      );
    },
    reason: '⛔ May open editor. Use `-m "message"` or `-u`',
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
      return [
        HOME + "/bin/",
        HOME + "/.config/",
        HOME + "/.hammerspoon/",
        HOME + "/.pi/agent/",
      ].some((m) => p.startsWith(m));
    },
    reason: "⛔ Nix-managed path. Edit ~/.dotfiles/ source instead.",
  });

  // ── HARD: nix build must output to /tmp and clean up ──

  rules.push({
    name: "nix-build-result",
    tier: "hard",
    tools: ["bash"],
    test: (cmd) => {
      if (!isCommandPrefix(cmd, "nix", "build")) return false;
      const tokens = segmentTokens(cmd, "nix", "build");
      if (!tokens) return false;
      // Allow if --no-link is present
      if (tokens.includes("--no-link")) return false;
      // Allow if -o or --out-link points to /tmp
      for (let i = 0; i < tokens.length; i++) {
        if (tokens[i] === "-o" || tokens[i] === "--out-link") {
          const target = tokens[i + 1];
          if (target && target.startsWith("/tmp/")) return false;
        }
        // Handle --out-link=/tmp/... form
        if (
          tokens[i].startsWith("--out-link=/tmp/") ||
          tokens[i].startsWith("-o=/tmp/")
        )
          return false;
      }
      // Block: would create ./result in current directory
      return true;
    },
    reason:
      "⛔ `nix build` creates ./result symlink. Use `--no-link` or `-o /tmp/<name>` and clean up after.",
  });

  // ── CONFIRM: destructive jj ──

  for (const [sub, reason] of Object.entries({
    rebase: "Can discard uncommitted changes or flatten commit history.",
    abandon: "Permanently discards changes.",
    restore: "Can overwrite uncommitted changes.",
    undo: "Can affect uncommitted work.",
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
      const hasInto =
        tokens.includes("--into") ||
        tokens.includes("--to") ||
        tokens.includes("-t");
      const hasRevision =
        tokens.includes("-r") || tokens.includes("--revision");
      const hasDestination =
        tokens.includes("-d") || tokens.includes("--destination");
      const hasInsertAfter =
        tokens.includes("-A") || tokens.includes("--insert-after");
      const hasInsertBefore =
        tokens.includes("-B") || tokens.includes("--insert-before");

      // If none of these multi-commit options are present, it's a simple squash (safe)
      if (
        !hasFrom &&
        !hasInto &&
        !hasRevision &&
        !hasDestination &&
        !hasInsertAfter &&
        !hasInsertBefore
      ) {
        return false;
      }

      // Block if any of these potentially dangerous options are used
      // User can override if they know what they're doing
      return true;
    },
    reason:
      "Squash with --from/--into/-r can flatten history. Simple `jj squash` is safe.",
  });

  // ── CONFIRM: tccutil reset without granular scoping ──
  // `tccutil reset` without a bundle-id resets a service for ALL apps,
  // forcing the user to re-grant every TCC permission. `tccutil reset All`
  // is the nuclear option — resets every service for every app.
  // Only `tccutil reset <SERVICE> <BUNDLE_ID>` is allowed without confirmation.

  rules.push({
    name: "tccutil-reset-unscoped",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => {
      const tokens = segmentTokens(cmd, "tccutil", "reset");
      if (!tokens) return false;
      // tokens = ["tccutil", "reset", <service?>, <bundle-id?>, ...]
      const service = tokens[2];
      const bundleId = tokens[3];

      // Bare `tccutil reset` — no service. Block.
      if (!service) return true;
      // `tccutil reset All` — nuclear, resets every service for every app. Block.
      if (service === "All") return true;
      // `tccutil reset <service>` without bundle-id — resets service for all apps. Block.
      if (!bundleId || bundleId.startsWith("-")) return true;

      return false;
    },
    reason:
      "`tccutil reset` without a bundle-id resets the service for ALL apps. " +
      "Use scoped form: `tccutil reset <SERVICE> <BUNDLE_ID>` (e.g. " +
      "`tccutil reset SystemPolicyAllFiles com.mitchellh.ghostty`). " +
      "Avoid `tccutil reset All` — it nukes every TCC permission for every app.",
  });

  // ── HARD: gatekeeper (secrets in diff) ──

  // Store gatekeeper findings for error message
  let gatekeeperFindings = "";

  function isPushCommand(cmd: string): boolean {
    return (
      isCommandPrefix(cmd, "jj", "push") ||
      isCommandPrefix(cmd, "jj", "git", "push") ||
      isCommandPrefix(cmd, "git", "push")
    );
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
      diff = execSync(
        "jj diff --git 2>/dev/null || git diff HEAD 2>/dev/null || echo ''",
        {
          encoding: "utf-8",
          timeout: 10000,
          stdio: ["pipe", "pipe", "pipe"],
        },
      );
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
    test: (cmd) =>
      isCommand(cmd, "deploy", "vercel", "dokploy") ||
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
    test: (cmd) =>
      isCommand(cmd, "ssh", "scp") ||
      (isCommandPrefix(cmd, "rsync") && cmdMatch(cmd, /rsync\s+.*:/)),
    reason: "Remote server access.",
  });

  // ── CONFIRM: non-nix package installs ──

  rules.push({
    name: "brew-install",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) =>
      isCommandPrefix(cmd, "brew", "install") ||
      isCommandPrefix(cmd, "brew", "cask") ||
      isCommandPrefix(cmd, "brew", "tap"),
    reason: "Non-nix install. Nix is the source of truth.",
  });

  rules.push({
    name: "global-pkg-install",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd) => {
      const stripped = stripQuoted(cmd);
      return (
        /(?:^|[;&|]\s*)npm\s+(i|install)\s+(-g|--global)\b/.test(stripped) ||
        isCommandPrefix(cmd, "pip", "install") ||
        isCommandPrefix(cmd, "cargo", "install") ||
        isCommandPrefix(cmd, "go", "install")
      );
    },
    reason: "Global package install. Check Nix first.",
  });

  rules.push({
    name: "project-pkg-install",
    tier: "confirm",
    tools: ["bash"],
    test: (cmd, path) => {
      // Allowed directories for package installs (nix-managed extensions)
      const allowedPaths = [
        `${HOME}/.dotfiles/home/common/programs/pi-coding-agent/packages`,
      ];

      // Check if current working directory is within allowed paths
      const normalizedPath = normalizePath(path || "");
      const isAllowed = allowedPaths.some(
        (allowed) =>
          normalizedPath.startsWith(`${allowed}/`) ||
          normalizedPath === allowed,
      );

      if (isAllowed) return false; // Allow in allowed directories

      // Check for cd in command (updates working directory)
      const cdMatch = cmd.match(/\bcd\s+(\S+)/);
      if (cdMatch) {
        const cdPath = normalizePath(cdMatch[1]);
        const cdAllowed = allowedPaths.some(
          (allowed) =>
            cdPath.startsWith(`${allowed}/`) ||
            cdPath === allowed ||
            cdPath === allowed,
        );
        if (cdAllowed) return false; // Allow in cd-changed directories
      }

      // mix deps.get is always allowed - standard Elixir workflow
      if (isCommandPrefix(cmd, "mix", "deps.get")) return false;
      return (
        isCommandPrefix(cmd, "npm", "install") ||
        isCommandPrefix(cmd, "npm", "i") ||
        isCommandPrefix(cmd, "npm", "add") ||
        isCommandPrefix(cmd, "yarn", "add") ||
        isCommandPrefix(cmd, "pnpm", "add") ||
        isCommandPrefix(cmd, "pnpm", "install") ||
        isCommandPrefix(cmd, "cargo", "add") ||
        isCommandPrefix(cmd, "bun", "add") ||
        isCommandPrefix(cmd, "bun", "install")
      );
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

  // ── REWRITE: command-specific tool corrections ──

  rules.push({
    name: "python-json-tool→jq",
    tier: "rewrite",
    tools: ["bash"],
    test: (cmd) => {
      for (const pythonCmd of ["python", "python3"]) {
        const tokens = segmentTokens(cmd, pythonCmd);
        if (!tokens) continue;
        if (tokens[1] === "-m" && tokens[2] === "json.tool") return true;
      }
      return false;
    },
    reason: "Use `jq .` instead of `python -m json.tool`.",
  });

  // ── REWRITE: tool corrections ──

  for (const [blocked, correction] of Object.entries(TOOL_CORRECTIONS)) {
    rules.push({
      name: `${blocked}→${correction.use}`,
      tier: "rewrite",
      tools: ["bash"],
      test: (cmd) => {
        if (!isCommand(cmd, blocked)) return false;
        // Exception: don't flag `git` when it's part of `jj git ...`
        if (correction.exceptPrefix) {
          if (isCommandPrefix(cmd, ...correction.exceptPrefix)) return false;
        }
        // Conditional: only apply if marker directory exists at repo root
        if (correction.onlyIfRootDir) {
          try {
            const cwd = process.cwd();
            // Walk up to find repo root (look for .git or the marker dir)
            let dir = cwd;
            let found = false;
            while (dir !== dirname(dir)) {
              if (existsSync(join(dir, correction.onlyIfRootDir))) {
                found = true;
                break;
              }
              // Stop at .git boundary (repo root)
              if (existsSync(join(dir, ".git"))) break;
              dir = dirname(dir);
            }
            if (!found) return false;
          } catch {
            return false;
          }
        }
        return true;
      },
      reason: correction.reason,
    });
  }

  // ── REWRITE: harness built-in tools that duplicate CLI tools ──
  // The pi harness (and some wrappers) inject built-in tools like Grep, Read, etc.
  // Block the ones that bypass our preferred CLI tools (rg, fd, etc.)

  rules.push({
    name: "Grep→rg",
    tier: "rewrite",
    tools: ["Grep"],
    test: () => true,
    reason: "Use `rg` via bash instead of the built-in Grep tool.",
  });

  // ── HARD: pipe/redirect without timeout (hang prevention) ──
  // Note: This rule is handled specially in the tool_call handler to check
  // the timeout parameter from the tool input.

  return rules;
}

// ── Pipe/redirect hang detection ─────────────────────────────────────────────

const MAX_PIPE_TIMEOUT_SECONDS = 300; // 5 minutes max

const PIPE_TARGETS = [
  "tail",
  "head",
  "tee",
  "less",
  "more",
  "cat",
  "wc",
  "sort",
  "uniq",
  "awk",
  "sed",
  "grep",
  "rg",
];

// Commands that are safe to pipe without timeout (they always terminate quickly)
const SAFE_UPSTREAM = [
  /^echo\s/, // echo always terminates
  /^printf\s/, // printf always terminates
  /^ls\b/, // ls always terminates
  /^cat\s+\S/, // cat with file argument (not stdin)
  /^fd\b/, // fd file finder
  /^rg\b/, // ripgrep
  /^jj\s/, // jj commands
  /^git\s/, // git commands (when used, e.g., in jj git)
  /^curl\s/, // curl always terminates
  /^wget\s/, // wget always terminates
  /^date\b/, // date command
  /^pwd\b/, // pwd command
  /^env\b/, // env command
  /^which\b/, // which command
  /^whoami\b/, // whoami command
  /^hostname\b/, // hostname command
  /^uname\b/, // uname command
  /^id\b/, // id command
  /^ps\b/, // ps command (snapshot, not continuous)
  /^df\b/, // df command
  /^du\b/, // du command
  /^stat\b/, // stat command
  /^file\b/, // file command
  /^timeout\s/, // explicit timeout wrapper
  /^gtimeout\s/, // GNU timeout on macOS
  /^jq\b/, // jq JSON processor
  /^yq\b/, // yq YAML processor
  /^tr\b/, // tr character translator
  /^cut\b/, // cut field extractor
  /^basename\b/, // basename path component
  /^dirname\b/, // dirname path component
  /^realpath\b/, // realpath resolver
  /^readlink\b/, // readlink symlink resolver
];

// Commands known to potentially hang when piped (wait for stdin, event loops, etc.)
const RISKY_UPSTREAM = [
  /\bnvim\s+--headless\b/, // nvim headless with vim.defer_fn hangs
  /\bnvim\s+-c\b/, // nvim with -c may not exit
  /\bvim\s+--headless\b/,
  /\bvim\s+-c\b/,
  /\bwatch\b/, // watch is continuous
  /\btail\s+-f\b/, // tail -f is continuous
  /\bjournalctl\s+-f\b/, // journalctl follow
  /\blog\s+tail\b/, // heroku/fly log tail
  /\bdocker\s+logs\s+-f\b/, // docker logs follow
  /\bkubectl\s+logs\s+-f\b/, // kubectl logs follow
];

/**
 * Check if command pipes to tail/head/etc or redirects output.
 * Returns details for the block message.
 */
function detectPipeOrRedirect(cmd: string): {
  hasPipe: boolean;
  hasRedirect: boolean;
  pipeTarget?: string;
  riskyUpstream?: string;
  isSafeUpstream: boolean;
} {
  const stripped = stripQuoted(cmd);

  // Check for pipes to common targets
  let hasPipe = false;
  let pipeTarget: string | undefined;
  for (const target of PIPE_TARGETS) {
    // Match pipe followed by target command
    const pipePattern = new RegExp(`\\|\\s*${target}(?:\\s|$)`);
    if (pipePattern.test(stripped)) {
      hasPipe = true;
      pipeTarget = target;
      break;
    }
  }

  // Check for redirects (but not heredocs which use <<)
  // Matches: >, >>, 2>, 2>>, 2>&1, &>, &>>
  const redirectPattern = /(?:^|[^<])(?:>>?|2>>?|2>&1|&>>?)/;
  const hasRedirect = redirectPattern.test(stripped);

  // Check if upstream command is known to be safe (always terminates)
  let isSafeUpstream = false;
  const trimmed = stripped.trim();
  for (const pattern of SAFE_UPSTREAM) {
    if (pattern.test(trimmed)) {
      isSafeUpstream = true;
      break;
    }
  }

  // Check for known risky upstream patterns (overrides safe check)
  let riskyUpstream: string | undefined;
  for (const pattern of RISKY_UPSTREAM) {
    if (pattern.test(stripped)) {
      riskyUpstream = pattern
        .toString()
        .replace(/^\/|\/$/g, "")
        .replace(/\\b/g, "");
      isSafeUpstream = false; // Risky overrides safe
      break;
    }
  }

  return { hasPipe, hasRedirect, pipeTarget, riskyUpstream, isSafeUpstream };
}

// ── Extension ────────────────────────────────────────────────────────────────

// ── Investigation mode ───────────────────────────────────────────────────────

const INVESTIGATE_RE =
  /^\s*(?:please\s+|can\s+you\s+|could\s+you\s+|would\s+you\s+)?(?:investigate|inspect|audit)\b/i;
const FIX_INTENT_RE =
  /\b(?:and\s+fix|then\s+fix|fix|implement|create|write|run\s+(?:it|that|those|them)|apply|commit|refactor|rewrite|change|update|delete|remove|trash|checkout|go\s+ahead|yes|yep|yeah|approved?)\b/i;
function investigationWriteKey(
  toolName: string,
  cmd: string,
  path: string,
): string | null {
  if (toolName === "edit" || toolName === "write") {
    return `${toolName}:${path || "<unknown>"}`;
  }
  if (toolName !== "bash" || !cmd) return null;

  const stripped = stripQuoted(cmd);
  const mutatesViaShell =
    /(^|[;&|()\s])(?:mv|cp|install|touch|mkdir|chmod|chown|ln|trash|rm|rsync|git\s+apply|patch|perl\s+-pi|python\d?\s+-m\s+pip)\b/.test(
      stripped,
    ) ||
    /(^|[^<])>>?\s*[^&\s]/.test(stripped) ||
    /\|\s*(?:tee|sponge)\b/.test(stripped);

  const mutatesViaPython =
    /\.write_(?:text|bytes)\s*\(/.test(cmd) ||
    /\bopen\s*\([^\n)]*,\s*["'][^"']*[wax+][^"']*["']/.test(cmd);

  if (!mutatesViaShell && !mutatesViaPython) return null;
  return `bash:${cmd.slice(0, 120)}`;
}

export default function (pi: ExtensionAPI) {
  const rules = buildRules();
  log(`${rules.length} rules loaded`);

  // ── Session-aware state ──
  let investigationMode = false;

  // Intercept user input: track investigation mode
  pi.on("input", async (event): Promise<void> => {
    // Reset investigation mode on every new user input
    investigationMode = false;

    // Skip extension-generated messages (subagent output, etc.)
    if (event.source === "extension") return;

    const text = event.text || "";

    // Detect investigation mode: "investigate X" without "and fix"
    if (INVESTIGATE_RE.test(text) && !FIX_INTENT_RE.test(text)) {
      investigationMode = true;
      log(`investigation mode: ON`);
    }
  });

  // Intercept user input for override keywords
  pi.on("input", async (event, ctx): Promise<InputEventResult | void> => {
    const text = event.text?.trim().toLowerCase() || "";

    const isOverrideCmd = ["override", "bypass", "force"].includes(text);
    const isForceOverride = ["!override", "!bypass", "!force", "!!"].includes(
      text,
    );

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
      if (ctx.hasUI)
        ctx.ui.notify(`✓ Override granted for: ${blockedRule}`, "info");
      // Signal agent to retry the blocked command
      pi.sendMessage(
        {
          customType: "sentinel_override",
          content: `✓ Override granted for **${blockedRule}**. Retry the command now.`,
          display: "user",
        },
        { triggerTurn: true },
      );
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
        pi.sendMessage(
          {
            customType: "sentinel_override",
            content: `✓ Override granted for **${blockedRule}**. Retry the command now.`,
            display: "user",
          },
          { triggerTurn: true },
        );
      } else {
        log("override rejected");
        resetBlocked();
      }
    } else {
      grantOverride();
      log("override: no UI, granted directly");
      // Signal agent to retry
      pi.sendMessage(
        {
          customType: "sentinel_override",
          content: `✓ Override granted for **${blockedRule}**. Retry the command now.`,
          display: "user",
        },
        { triggerTurn: true },
      );
    }

    return { action: "handled" };
  });

  // Intercept tool calls
  pi.on(
    "tool_call",
    async (event, _ctx): Promise<ToolCallEventResult | void> => {
      const toolName = event.toolName;
      const input = (event as ToolCallEvent).input;
      const cmd = ((input as any).command as string) || "";
      const path = ((input as any).path as string) || "";
      const timeout = (input as any).timeout as number | undefined;

      // ── Investigation mode: block writes unless user explicitly overrides ──
      if (investigationMode) {
        const writeKey = investigationWriteKey(toolName, cmd, path);
        if (writeKey) {
          if (overrideGranted && blocked?.command === writeKey) {
            if (consumeOverride()) return undefined;
          }

          blocked = {
            command: writeKey,
            rule: "Investigation mode write",
            reason:
              "The user asked for investigation-only work, so writes require explicit override.",
            timestamp: Date.now(),
          };
          log(`INVESTIGATE: blocking ${writeKey.slice(0, 80)}`);
          return {
            block: true,
            reason:
              "🔍 **Investigation mode active**\n\n" +
              "The user asked you to investigate, not to make changes.\n\n" +
              "**Agent:** Do not work around this with bash, Python heredocs, redirects, or alternate write paths. Before asking for override, explain:\n" +
              "1. Why this is not investigation-only work, or why a write is required\n" +
              "2. What file(s) or command would change\n" +
              "3. Whether the change is safe and scoped\n\n" +
              "Say `override` to allow this one write.",
          };
        }
      }

      // ── Special check: pipe/redirect hang prevention ──
      if (toolName === "bash" && cmd) {
        const pipeCheck = detectPipeOrRedirect(cmd);

        if (
          (pipeCheck.hasPipe || pipeCheck.hasRedirect) &&
          !pipeCheck.isSafeUpstream
        ) {
          // Check if timeout is missing or too long
          const hasValidTimeout =
            timeout !== undefined &&
            timeout > 0 &&
            timeout <= MAX_PIPE_TIMEOUT_SECONDS;

          if (!hasValidTimeout) {
            const issues: string[] = [];

            if (pipeCheck.riskyUpstream) {
              issues.push(
                `- **Risky upstream**: \`${pipeCheck.riskyUpstream}\` may hang or never produce output`,
              );
            }
            if (pipeCheck.hasPipe) {
              issues.push(
                `- **Pipes to**: \`${pipeCheck.pipeTarget}\` — upstream must terminate to produce output`,
              );
            }
            if (pipeCheck.hasRedirect) {
              issues.push(
                `- **Redirects output** — if upstream hangs, no error will be visible`,
              );
            }
            if (!timeout) {
              issues.push(
                `- **No timeout specified** — command could hang indefinitely`,
              );
            } else if (timeout > MAX_PIPE_TIMEOUT_SECONDS) {
              issues.push(
                `- **Timeout too long**: ${timeout}s > ${MAX_PIPE_TIMEOUT_SECONDS}s max`,
              );
            }

            log(`PIPE-HANG: ${cmd.slice(0, 80)}`);
            return {
              block: true,
              reason: `⚠️ **Potential hang detected** — command pipes/redirects output without safeguards.

${issues.join("\n")}

**Before retrying, verify:**
1. The upstream command will **actually terminate** (not an event loop, not waiting for stdin)
2. Add a **timeout ≤ ${MAX_PIPE_TIMEOUT_SECONDS}s** to the bash call

**Common failure patterns:**
- \`nvim --headless\` with \`vim.defer_fn\` — event loop doesn't pump, hangs forever
- \`tail -f\` or \`journalctl -f\` — continuous streams never terminate
- Interactive processes — wait for stdin that will never come

**Fix:** Add \`timeout: <seconds>\` parameter to the bash tool call.`,
            };
          }
        }
      }

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
          blocked = {
            command: cmd,
            rule: rule.name,
            reason: rule.reason,
            timestamp: Date.now(),
          };
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

Say \`override\` to allow.`,
          };
        }
      }

      return undefined;
    },
  );

  (globalThis as Record<string, unknown>).__sentinel = {
    get blocked() {
      return blocked;
    },
    get overrideGranted() {
      return overrideGranted;
    },
    rules: rules.map((r) => r.name),
    reset: () => {
      resetOverride();
      resetBlocked();
    },
    grant: grantOverride,
  };
}
