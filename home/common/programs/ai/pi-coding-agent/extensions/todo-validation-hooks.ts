/**
 * Todo Validation Hooks — runs validation before todo updates/closes
 *
 * Validates the codebase is in a working state before allowing todo status changes.
 *
 * Priority order:
 * 1. Project-specific scripts (package.json, justfile, Makefile)
 * 2. Project-specific tools (biome.json, .eslintrc, etc.)
 * 3. Global fallback tools (shellcheck, luacheck, etc.)
 *
 * Validation runs for:
 * - "update" action (when changing status to done/closed)
 * - "close" action
 *
 * Skips validation for:
 * - "create", "get", "list", "append", "claim", "release", "delete"
 * - Updates that don't change status (just title/body/tags)
 * - Status changes to open/blocked/wontfix
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { execSync, spawnSync } from "child_process";
import { existsSync, readFileSync, readdirSync } from "fs";
import { join, resolve, extname } from "path";

// Actions that require validation
const VALIDATE_ACTIONS = new Set(["update", "close"]);

// Status changes that don't need validation
const SKIP_STATUSES = new Set(["open", "blocked", "wontfix"]);

interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
  ranProjectScripts?: boolean;
}

// ============================================================================
// Utility Functions
// ============================================================================

function hasCommand(cmd: string): boolean {
  try {
    execSync(`which ${cmd}`, { encoding: "utf-8", timeout: 5000, stdio: "pipe" });
    return true;
  } catch {
    return false;
  }
}

function runCommand(
  cmd: string,
  args: string[],
  cwd: string,
  timeout = 30000
): { ok: boolean; output: string; code: number | null } {
  try {
    const result = spawnSync(cmd, args, {
      cwd,
      encoding: "utf-8",
      timeout,
      stdio: ["pipe", "pipe", "pipe"],
      shell: true,
    });
    const output = (result.stdout || "") + (result.stderr || "");
    return { ok: result.status === 0, output, code: result.status };
  } catch (e: unknown) {
    const error = e as { message?: string };
    return { ok: false, output: error.message || "Command failed", code: null };
  }
}

function readJsonFile(path: string): Record<string, unknown> | null {
  try {
    const content = readFileSync(path, "utf-8");
    return JSON.parse(content);
  } catch {
    return null;
  }
}

function findFiles(dir: string, extensions: string[], maxDepth = 5): string[] {
  const files: string[] = [];
  const seen = new Set<string>();

  function walk(current: string, depth: number) {
    if (depth > maxDepth) return;

    try {
      const entries = readdirSync(current, { withFileTypes: true });
      for (const entry of entries) {
        if (entry.isDirectory()) {
          const skip = [
            "node_modules", ".git", "_build", "deps", "__pycache__",
            ".elixir_ls", "dist", "build", ".next", ".nuxt", "coverage"
          ];
          if (skip.includes(entry.name)) continue;
          walk(join(current, entry.name), depth + 1);
        } else if (entry.isFile()) {
          const ext = extname(entry.name).toLowerCase();
          if (extensions.includes(ext)) {
            const fullPath = join(current, entry.name);
            const realPath = resolve(fullPath);
            if (!seen.has(realPath)) {
              seen.add(realPath);
              files.push(fullPath);
            }
          }
        }
      }
    } catch {
      // Skip unreadable directories
    }
  }

  walk(dir, 0);
  return files;
}

// ============================================================================
// Project Script Detection
// ============================================================================

interface ProjectScripts {
  lint?: string;
  check?: string;
  validate?: string;
  typecheck?: string;
  test?: string;
  biome?: string;
}

function detectPackageJsonScripts(cwd: string): ProjectScripts {
  const scripts: ProjectScripts = {};
  const pkgPath = join(cwd, "package.json");

  if (!existsSync(pkgPath)) return scripts;

  const pkg = readJsonFile(pkgPath);
  if (!pkg || typeof pkg.scripts !== "object") return scripts;

  const pkgScripts = pkg.scripts as Record<string, string>;

  // Look for common validation scripts
  const scriptMappings: Record<keyof ProjectScripts, string[]> = {
    lint: ["lint", "lint:check", "eslint", "biome:lint"],
    check: ["check", "biome:check", "biome check"],
    validate: ["validate", "verify"],
    typecheck: ["typecheck", "type-check", "tsc", "tsc:check"],
    test: ["test", "test:unit"],
    biome: ["biome", "biome:ci"],
  };

  for (const [key, candidates] of Object.entries(scriptMappings)) {
    for (const candidate of candidates) {
      if (pkgScripts[candidate]) {
        scripts[key as keyof ProjectScripts] = candidate;
        break;
      }
    }
  }

  return scripts;
}

function detectJustfileTargets(cwd: string): string[] {
  const justfile = join(cwd, "justfile");
  if (!existsSync(justfile)) return [];

  try {
    const content = readFileSync(justfile, "utf-8");
    const targets: string[] = [];

    // Match target definitions: `target-name:` at start of line
    const regex = /^([a-z][a-z0-9_-]*)\s*:/gim;
    let match;
    while ((match = regex.exec(content)) !== null) {
      targets.push(match[1]);
    }

    return targets;
  } catch {
    return [];
  }
}

function detectMakefileTargets(cwd: string): string[] {
  const makefile = join(cwd, "Makefile");
  if (!existsSync(makefile)) return [];

  try {
    const content = readFileSync(makefile, "utf-8");
    const targets: string[] = [];

    // Match target definitions
    const regex = /^([a-z][a-z0-9_-]*)\s*:/gim;
    let match;
    while ((match = regex.exec(content)) !== null) {
      targets.push(match[1]);
    }

    return targets;
  } catch {
    return [];
  }
}

// ============================================================================
// Project Tool Detection
// ============================================================================

interface ProjectTools {
  biome: boolean;
  eslint: boolean;
  prettier: boolean;
  typescript: boolean;
  elixir: boolean;
  python: boolean;
  lua: boolean;
  nix: boolean;
}

function detectProjectTools(cwd: string): ProjectTools {
  return {
    biome: existsSync(join(cwd, "biome.json")) || existsSync(join(cwd, "biome.jsonc")),
    eslint:
      existsSync(join(cwd, ".eslintrc.json")) ||
      existsSync(join(cwd, ".eslintrc.js")) ||
      existsSync(join(cwd, "eslint.config.js")) ||
      existsSync(join(cwd, "eslint.config.mjs")),
    prettier:
      existsSync(join(cwd, ".prettierrc")) ||
      existsSync(join(cwd, ".prettierrc.json")) ||
      existsSync(join(cwd, "prettier.config.js")),
    typescript: existsSync(join(cwd, "tsconfig.json")),
    elixir: existsSync(join(cwd, "mix.exs")),
    python:
      existsSync(join(cwd, "pyproject.toml")) ||
      existsSync(join(cwd, "setup.py")) ||
      existsSync(join(cwd, "ruff.toml")),
    lua: cwd.includes(".dotfiles") || existsSync(join(cwd, ".luacheckrc")),
    nix: existsSync(join(cwd, "flake.nix")),
  };
}

// ============================================================================
// Validation Runners
// ============================================================================

function runProjectScripts(cwd: string, scripts: ProjectScripts): ValidationResult {
  const result: ValidationResult = { valid: true, errors: [], warnings: [], ranProjectScripts: false };

  // Priority: check > lint > typecheck
  const toRun: string[] = [];
  if (scripts.check) toRun.push(scripts.check);
  else {
    if (scripts.lint) toRun.push(scripts.lint);
    if (scripts.typecheck) toRun.push(scripts.typecheck);
  }

  if (toRun.length === 0) return result;

  result.ranProjectScripts = true;

  for (const script of toRun) {
    // Determine package manager
    const pm = existsSync(join(cwd, "pnpm-lock.yaml"))
      ? "pnpm"
      : existsSync(join(cwd, "yarn.lock"))
        ? "yarn"
        : existsSync(join(cwd, "bun.lockb"))
          ? "bun"
          : "npm";

    const { ok, output } = runCommand(pm, ["run", script], cwd, 120000);

    if (!ok) {
      result.valid = false;
      // Extract meaningful error lines
      const errorLines = output
        .split("\n")
        .filter((l) => l.includes("error") || l.includes("Error") || l.includes("✖") || l.includes("✗"))
        .slice(0, 15);
      result.errors.push(`\`${pm} run ${script}\` failed:`, ...errorLines);
    }
  }

  return result;
}

function runJustTargets(cwd: string, targets: string[]): ValidationResult {
  const result: ValidationResult = { valid: true, errors: [], warnings: [], ranProjectScripts: false };

  // Look for validation-related targets
  const validationTargets = ["check", "lint", "validate", "verify", "typecheck"].filter((t) =>
    targets.includes(t)
  );

  if (validationTargets.length === 0) return result;

  result.ranProjectScripts = true;

  // Run first matching target (usually "check" is comprehensive)
  const target = validationTargets[0];
  const { ok, output } = runCommand("just", [target], cwd, 120000);

  if (!ok) {
    result.valid = false;
    const errorLines = output
      .split("\n")
      .filter((l) => l.includes("error") || l.includes("Error"))
      .slice(0, 15);
    result.errors.push(`\`just ${target}\` failed:`, ...errorLines);
  }

  return result;
}

function runBiome(cwd: string): ValidationResult {
  const result: ValidationResult = { valid: true, errors: [], warnings: [] };

  // Prefer npx/pnpm to use project-local biome
  const pm = existsSync(join(cwd, "pnpm-lock.yaml")) ? "pnpm" : "npx";
  const { ok, output } = runCommand(pm, ["biome", "check", "."], cwd, 60000);

  if (!ok) {
    result.valid = false;
    const errorLines = output
      .split("\n")
      .filter((l) => l.includes("✖") || l.includes("error") || l.includes("×"))
      .slice(0, 15);
    result.errors.push(...errorLines);
  }

  return result;
}

function detectMixTasks(cwd: string): string[] {
  // Check for .check.exs (ex_check config) or common validation tasks
  const tasks: string[] = [];

  // ex_check is a common Elixir tool that runs comprehensive checks
  if (existsSync(join(cwd, ".check.exs"))) {
    tasks.push("check");
  }

  // Check mix.exs for deps that indicate available tasks
  const mixExs = join(cwd, "mix.exs");
  if (existsSync(mixExs)) {
    try {
      const content = readFileSync(mixExs, "utf-8");

      // Look for common check dependencies
      if (content.includes(":credo")) tasks.push("credo");
      if (content.includes(":dialyxir")) tasks.push("dialyzer");
      if (content.includes(":ex_check")) tasks.push("check");
      if (content.includes(":sobelow")) tasks.push("sobelow");
    } catch {
      // Ignore read errors
    }
  }

  return tasks;
}

function runElixirValidation(cwd: string): ValidationResult {
  const result: ValidationResult = { valid: true, errors: [], warnings: [] };

  if (!hasCommand("mix")) {
    result.warnings.push("mix not available (install elixir via mise)");
    return result;
  }

  const mixTasks = detectMixTasks(cwd);

  // Prefer `mix check` if available (ex_check runs comprehensive suite)
  if (mixTasks.includes("check")) {
    const { ok, output } = runCommand("mix", ["check"], cwd, 180000);

    if (!ok) {
      result.valid = false;
      const errorLines = output
        .split("\n")
        .filter((l) =>
          l.includes("error") ||
          l.includes("Error") ||
          l.includes("✗") ||
          l.includes("failed") ||
          l.includes("warning:")
        )
        .slice(0, 15);
      result.errors.push("`mix check` failed:", ...errorLines);
    }
    return result;
  }

  // Fallback: run individual checks

  // 1. Compile check (fast, catches syntax errors)
  const { ok: compileOk, output: compileOutput } = runCommand(
    "mix",
    ["compile", "--warnings-as-errors"],
    cwd,
    120000
  );

  if (!compileOk) {
    result.valid = false;
    const errorLines = compileOutput
      .split("\n")
      .filter((l) => l.includes("error:") || l.includes("** (") || l.includes("undefined"))
      .slice(0, 10);
    result.errors.push(...errorLines);
    return result; // Don't continue if compile fails
  }

  // 2. Credo (if available)
  if (mixTasks.includes("credo")) {
    const { ok, output } = runCommand("mix", ["credo", "--strict"], cwd, 60000);
    if (!ok) {
      // Credo failures are warnings, not blocking errors
      const issues = output
        .split("\n")
        .filter((l) => l.includes("┃") || l.includes("warning"))
        .slice(0, 5);
      result.warnings.push(...issues);
    }
  }

  // 3. Dialyzer (if available and not too slow)
  // Skip by default - it's very slow. Uncomment if desired:
  // if (mixTasks.includes("dialyzer")) {
  //   const { ok, output } = runCommand("mix", ["dialyzer"], cwd, 300000);
  //   if (!ok) {
  //     result.warnings.push("Dialyzer found issues");
  //   }
  // }

  return result;
}

function runTypeScriptValidation(cwd: string): ValidationResult {
  const result: ValidationResult = { valid: true, errors: [], warnings: [] };

  const pm = existsSync(join(cwd, "pnpm-lock.yaml")) ? "pnpm" : "npx";
  const { ok, output } = runCommand(pm, ["tsc", "--noEmit"], cwd, 60000);

  if (!ok && output.includes("error TS")) {
    result.valid = false;
    const errorLines = output
      .split("\n")
      .filter((l) => l.includes("error TS"))
      .slice(0, 10);
    result.errors.push(...errorLines);
  }

  return result;
}

function runShellValidation(cwd: string): ValidationResult {
  const result: ValidationResult = { valid: true, errors: [], warnings: [] };

  if (!hasCommand("shellcheck")) {
    return result; // Silent skip
  }

  const files = findFiles(cwd, [".sh", ".bash"]);
  if (files.length === 0) return result;

  const { ok, output } = runCommand("shellcheck", ["--severity=error", ...files.slice(0, 50)], cwd);

  if (!ok) {
    result.valid = false;
    const errorLines = output
      .split("\n")
      .filter((l) => l.includes("error:") || l.includes("SC"))
      .slice(0, 10);
    result.errors.push(...errorLines);
  }

  return result;
}

function runLuaValidation(cwd: string): ValidationResult {
  const result: ValidationResult = { valid: true, errors: [], warnings: [] };

  const files = findFiles(cwd, [".lua"]);
  if (files.length === 0) return result;

  // Try stylua check first (fast)
  if (hasCommand("stylua")) {
    const { ok } = runCommand("stylua", ["--check", ...files.slice(0, 50)], cwd);
    if (!ok) {
      result.warnings.push("Lua formatting issues (run: stylua .)");
    }
  }

  // luacheck for actual errors
  if (hasCommand("luacheck")) {
    const { ok, output } = runCommand(
      "luacheck",
      ["--globals", "hs", "spoon", "_G", "PATH", "U", "S", "--no-unused-args", ...files.slice(0, 50)],
      cwd
    );

    if (!ok) {
      const errorLines = output
        .split("\n")
        .filter((l) => l.includes(": error:") || l.includes("(E"))
        .slice(0, 10);
      if (errorLines.length > 0) {
        result.valid = false;
        result.errors.push(...errorLines);
      }
    }
  }

  return result;
}

function runHammerspoonValidation(): ValidationResult {
  const result: ValidationResult = { valid: true, errors: [], warnings: [] };

  // Check if HS is running
  try {
    execSync("pgrep -x Hammerspoon", { encoding: "utf-8", timeout: 5000, stdio: "pipe" });
  } catch {
    result.warnings.push("Hammerspoon not running (cannot validate)");
    return result;
  }

  // Quick syntax check
  try {
    const checkScript = `
      local ok, err = pcall(function()
        local f = io.open(hs.configdir .. "/init.lua", "r")
        if f then
          local content = f:read("*a")
          f:close()
          local fn, parseErr = load(content, "init.lua", "t", {})
          if not fn then error("Syntax: " .. (parseErr or "?")) end
        end
      end)
      print(ok and "OK" or ("ERROR: " .. tostring(err)))
    `;

    const output = execSync(`hs -c '${checkScript.replace(/'/g, "'\"'\"'")}'`, {
      encoding: "utf-8",
      timeout: 10000,
    });

    if (output.includes("ERROR:")) {
      result.valid = false;
      result.errors.push(output.trim());
    }
  } catch (e: unknown) {
    const err = e as { stderr?: string; message?: string };
    if ((err.stderr || err.message || "").includes("error")) {
      result.valid = false;
      result.errors.push(`HS validation failed: ${(err.stderr || err.message || "").slice(0, 200)}`);
    }
  }

  return result;
}

// ============================================================================
// Main Validation Logic
// ============================================================================

function runValidations(cwd: string): ValidationResult {
  const combined: ValidationResult = { valid: true, errors: [], warnings: [] };

  // Detect what's available
  const pkgScripts = detectPackageJsonScripts(cwd);
  const justTargets = detectJustfileTargets(cwd);
  const tools = detectProjectTools(cwd);

  // 1. Try project scripts first (most comprehensive)
  const scriptResult = runProjectScripts(cwd, pkgScripts);
  if (scriptResult.ranProjectScripts) {
    combined.errors.push(...scriptResult.errors);
    combined.warnings.push(...scriptResult.warnings);
    if (!scriptResult.valid) combined.valid = false;

    // If project scripts ran, we trust them - skip individual tool checks
    // (the project's lint/check scripts should cover everything)
    return combined;
  }

  // 2. Try justfile targets
  const justResult = runJustTargets(cwd, justTargets);
  if (justResult.ranProjectScripts) {
    combined.errors.push(...justResult.errors);
    combined.warnings.push(...justResult.warnings);
    if (!justResult.valid) combined.valid = false;
    return combined;
  }

  // 3. No project scripts - run individual tool checks

  // Biome (covers JS/TS/JSON/CSS)
  if (tools.biome) {
    const r = runBiome(cwd);
    combined.errors.push(...r.errors);
    combined.warnings.push(...r.warnings);
    if (!r.valid) combined.valid = false;
  }

  // TypeScript (if no biome and has tsconfig)
  if (!tools.biome && tools.typescript) {
    const r = runTypeScriptValidation(cwd);
    combined.errors.push(...r.errors);
    combined.warnings.push(...r.warnings);
    if (!r.valid) combined.valid = false;
  }

  // Elixir
  if (tools.elixir) {
    const r = runElixirValidation(cwd);
    combined.errors.push(...r.errors);
    combined.warnings.push(...r.warnings);
    if (!r.valid) combined.valid = false;
  }

  // Lua (dotfiles)
  if (tools.lua) {
    const r = runLuaValidation(cwd);
    combined.errors.push(...r.errors);
    combined.warnings.push(...r.warnings);
    if (!r.valid) combined.valid = false;

    // Also run Hammerspoon validation
    if (cwd.includes(".dotfiles")) {
      const hsResult = runHammerspoonValidation();
      combined.errors.push(...hsResult.errors);
      combined.warnings.push(...hsResult.warnings);
      if (!hsResult.valid) combined.valid = false;
    }
  }

  // Shell scripts (always check if shellcheck available)
  const shellResult = runShellValidation(cwd);
  combined.errors.push(...shellResult.errors);
  combined.warnings.push(...shellResult.warnings);
  if (!shellResult.valid) combined.valid = false;

  return combined;
}

// ============================================================================
// Extension Entry Point
// ============================================================================

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "todo") return;

    const input = event.input as { action?: string; status?: string };
    const action = input.action;

    // Only validate for update/close actions
    if (!action || !VALIDATE_ACTIONS.has(action)) return;

    // Skip if just changing metadata
    if (action === "update" && !input.status) return;

    // Skip certain status changes
    if (input.status && SKIP_STATUSES.has(input.status.toLowerCase())) return;

    // Run validations
    ctx.ui.setStatus("todo-validation", "🔍 Validating...");
    const result = runValidations(ctx.cwd);
    ctx.ui.setStatus("todo-validation", undefined);

    // Show warnings
    if (result.warnings.length > 0) {
      ctx.ui.notify(`⚠️ ${result.warnings.slice(0, 3).join("\n")}`, "warning");
    }

    // Block on failure
    if (!result.valid) {
      const errorList = result.errors.slice(0, 12).map((e) => `• ${e}`).join("\n");

      return {
        block: true,
        reason: `🛑 **Validation failed** — fix before updating todo:

${errorList}

**Detection priority:**
1. package.json scripts (lint, check, typecheck)
2. justfile targets (check, lint, validate)
3. Project tools (biome.json, tsconfig.json, mix.exs)
4. Global tools (shellcheck, luacheck)`,
      };
    }
  });
}
