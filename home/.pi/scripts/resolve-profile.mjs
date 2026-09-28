#!/usr/bin/env node
/**
 * Resolve Pi startup profile and model scope from settings.json.
 *
 * Usage:
 *   resolve-profile.mjs --settings <path> --cwd <path>
 *     [--session <name>] [--explicit-profile <name>]
 *
 * Outputs shell-safe exports for the Pi wrapper.
 */
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const args = process.argv.slice(2);

function getArg(name) {
	const index = args.indexOf(name);
	return index >= 0 && index + 1 < args.length ? args[index + 1] : undefined;
}

const settingsPath = getArg("--settings");
const cwd = getArg("--cwd") || process.cwd();
const session = getArg("--session") || "";
const explicitProfile = getArg("--explicit-profile") || "";

function expandHome(value) {
	return value.startsWith("~/") ? join(homedir(), value.slice(2)) : value;
}

function globToRegExp(glob) {
	const expanded = expandHome(glob);
	let regex = "";
	let index = 0;

	while (index < expanded.length) {
		const character = expanded[index];
		if (character === "*" && expanded[index + 1] === "*") {
			if (expanded[index + 2] === "/") {
				regex += "(?:.+/)?";
				index += 3;
			} else {
				regex += ".*";
				index += 2;
			}
		} else if (character === "*") {
			regex += "[^/]*";
			index += 1;
		} else if (character === "?") {
			regex += "[^/]";
			index += 1;
		} else if ("/.+^${}()|[]\\".includes(character)) {
			regex += `\\${character}`;
			index += 1;
		} else {
			regex += character;
			index += 1;
		}
	}

	return new RegExp(`^${regex}$`);
}

function directoryProfileMatches(profile, normalizedCwd) {
	if (profile.path) {
		const path = expandHome(profile.path);
		return normalizedCwd === path || normalizedCwd.startsWith(`${path}/`);
	}
	if (profile.glob) return globToRegExp(profile.glob).test(normalizedCwd);
	return false;
}

function shellEscape(value) {
	return `'${value.replaceAll("'", `'\\''`)}'`;
}

let settings = {};
if (settingsPath && existsSync(settingsPath)) {
	try {
		settings = JSON.parse(readFileSync(settingsPath, "utf8"));
	} catch (error) {
		console.error(`pi: cannot read profile settings: ${error.message}`);
		process.exit(2);
	}
}

const multiSub = settings.multiSub || {};
const presets = new Set((multiSub.presets || []).map((preset) => preset.name));
const modelScopes = {
	...(settings.enabledProfileModels || {}),
	...(settings.enabledModelScopes || {}),
};
const knownProfile = (name) => Boolean(modelScopes[name] || presets.has(name));

let preset = "";
let modelScope = "";
let source = "";

if (explicitProfile) {
	if (!knownProfile(explicitProfile)) {
		console.error(`pi: unknown profile: ${explicitProfile}`);
		process.exit(2);
	}
	preset = explicitProfile;
	modelScope = explicitProfile;
	source = "profile-flag";
} else {
	const envPreset =
		process.env.PI_PROFILE ||
		process.env.PI_MULTI_PASS_PRESET ||
		process.env.PI_SUB_PRESET ||
		process.env.PI_PRESET ||
		"";
	if (envPreset) {
		preset = envPreset;
		modelScope = process.env.PI_MODEL_SCOPE || envPreset;
		source = "env";
	} else if (session && knownProfile(session)) {
		preset = session;
		modelScope = session;
		source = "tmux";
	} else {
		const normalizedCwd = expandHome(cwd);
		for (const profile of multiSub.directoryProfiles || []) {
			if (!directoryProfileMatches(profile, normalizedCwd)) continue;
			const name = profile.preset || profile.profile;
			if (!name) continue;
			preset = name;
			modelScope = profile.modelScope || name;
			source = "directory";
			break;
		}
	}
}

if (!preset) {
	preset = "mega";
	modelScope = "mega";
	source = "default";
}

const scopedModels = Array.isArray(modelScopes[modelScope])
	? modelScopes[modelScope]
	: [];
const models = scopedModels.join(",");

const subagentRole = process.env.PI_SUBAGENT_AGENT || "";
const subagentRoute = subagentRole
	? settings.subagentRouting?.[preset]?.[subagentRole]
	: undefined;
const subagentModel = subagentRoute?.model || "";
const subagentThinking = subagentRoute?.thinking || "";

if (subagentModel && !scopedModels.includes(subagentModel)) {
	console.error(
		`pi: subagent model ${subagentModel} is outside profile scope ${modelScope}`,
	);
	process.exit(2);
}

console.log(`export PI_PROFILE=${shellEscape(preset)}`);
console.log(`export PI_MULTI_PASS_PRESET=${shellEscape(preset)}`);
console.log(`export PI_MODEL_SCOPE=${shellEscape(modelScope)}`);
console.log(`export PI_PROFILE_SOURCE=${shellEscape(source)}`);
console.log(`export PI_MODEL_SCOPE_PATTERNS=${shellEscape(models)}`);
console.log(`export PI_SUBAGENT_MODEL=${shellEscape(subagentModel)}`);
console.log(`export PI_SUBAGENT_THINKING=${shellEscape(subagentThinking)}`);
