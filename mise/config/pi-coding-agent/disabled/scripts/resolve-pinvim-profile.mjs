#!/usr/bin/env node
/**
 * Resolve pinvim startup profile from settings.json directoryProfiles.
 *
 * Usage: resolve-pinvim-profile.mjs --settings <path> --cwd <path> [--session <name>] [--explicit-profile <name>]
 *
 * Outputs shell-safe exports for:
 *   PI_PROFILE, PI_MULTI_PASS_PRESET, PI_MODEL_SCOPE, PI_PROFILE_SOURCE
 *
 * Precedence:
 *   1. --explicit-profile (pinvim --profile flag)
 *   2. Pre-existing explicit env vars (PI_PROFILE, PI_MULTI_PASS_PRESET, etc.)
 *   3. tmux session name (only if it matches a known preset)
 *   4. directoryProfiles (glob/path matching cwd)
 *   5. default "mega"
 */
import { readFileSync, existsSync } from "fs";
import { join } from "path";
import { homedir } from "os";

const args = process.argv.slice(2);
function getArg(name) {
  const idx = args.indexOf(name);
  return idx >= 0 && idx + 1 < args.length ? args[idx + 1] : undefined;
}

const settingsPath = getArg("--settings");
const cwd = getArg("--cwd") || process.cwd();
const session = getArg("--session") || "";
const explicitProfile = getArg("--explicit-profile") || "";

function expandHome(value) {
  if (value.startsWith("~/")) return join(homedir(), value.slice(2));
  return value;
}

function globToRegExp(glob) {
  const expanded = expandHome(glob);
  let regex = "";
  let i = 0;
  while (i < expanded.length) {
    const ch = expanded[i];
    if (ch === "*" && expanded[i + 1] === "*") {
      if (expanded[i + 2] === "/") {
        regex += "(?:.+/)?";
        i += 3;
      } else {
        regex += ".*";
        i += 2;
      }
    } else if (ch === "*") {
      regex += "[^/]*";
      i += 1;
    } else if (ch === "?") {
      regex += "[^/]";
      i += 1;
    } else if ("/.+^${}()|[]\\\\".includes(ch)) {
      regex += "\\" + ch;
      i += 1;
    } else {
      regex += ch;
      i += 1;
    }
  }
  return new RegExp("^" + regex + "$");
}

function dirProfileMatches(profile, normalizedCwd) {
  if (profile.path) {
    const p = expandHome(profile.path);
    return normalizedCwd === p || normalizedCwd.startsWith(p + "/");
  }
  if (profile.glob) {
    return globToRegExp(profile.glob).test(normalizedCwd);
  }
  return false;
}

function shellEscape(str) {
  return "'" + str.replace(/'/g, "'\\''") + "'";
}

// Load settings.json
let multiSub = null;
let knownPresetNames = new Set();
let enabledModelScopes = {};

if (settingsPath && existsSync(settingsPath)) {
  try {
    const raw = JSON.parse(readFileSync(settingsPath, "utf-8"));
    multiSub = raw?.multiSub || null;
    if (multiSub?.presets) {
      for (const p of multiSub.presets) knownPresetNames.add(p.name);
    }
    if (raw?.enabledModelScopes) enabledModelScopes = raw.enabledModelScopes;
  } catch {
    /* ignore */
  }
}

const normalizedCwd = expandHome(cwd);
const hasModelScope = (name) =>
  !!(enabledModelScopes[name] || knownPresetNames.has(name));

// Precedence resolution
let preset = "";
let modelScope = "";
let source = "";

// 1. --profile flag
if (explicitProfile) {
  preset = explicitProfile;
  modelScope = explicitProfile;
  source = "profile-flag";
}
// 2. Pre-existing explicit env vars (already in environment, not set by wrapper)
else if (
  process.env.PI_PROFILE ||
  process.env.PI_MULTI_PASS_PRESET ||
  process.env.PI_SUB_PRESET ||
  process.env.PI_PRESET
) {
  preset =
    process.env.PI_MULTI_PASS_PRESET ||
    process.env.PI_PROFILE ||
    process.env.PI_SUB_PRESET ||
    process.env.PI_PRESET ||
    "";
  modelScope = process.env.PI_MODEL_SCOPE || preset;
  source = "env";
}
// 3. tmux session (only if it matches a known preset/scope)
else if (session && hasModelScope(session)) {
  preset = session;
  modelScope = session;
  source = "tmux";
}
// 4. Directory profiles
else if (multiSub?.directoryProfiles) {
  for (const profile of multiSub.directoryProfiles) {
    if (!dirProfileMatches(profile, normalizedCwd)) continue;
    const name = profile.preset || profile.profile;
    if (!name) continue;
    preset = name;
    modelScope = profile.modelScope || name;
    source = "directory";
    break;
  }
}

// 5. Default
if (!preset) {
  preset = "mega";
  modelScope = "mega";
  source = "default";
}

// Output shell-safe exports
console.log(`export PI_PROFILE=${shellEscape(preset)}`);
console.log(`export PI_MULTI_PASS_PRESET=${shellEscape(preset)}`);
console.log(`export PI_MODEL_SCOPE=${shellEscape(modelScope)}`);
console.log(`export PI_PROFILE_SOURCE=${shellEscape(source)}`);
