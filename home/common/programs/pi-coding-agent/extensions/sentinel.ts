/**
 * Sentinel — tiered command guardrails with override protocol.
 *
 * Tiers:
 *   HARD    — always blocked, no override
 *   CONFIRM — blocked, user says "override"/"bypass"/"force" → UI select prompt
 *   REWRITE — blocked with clear message to use preferred tool
 *
 * Rules are bundled in this extension so activation has one source of truth.
 * Specialized logic remains for VCS editor/message checks, secrets,
 * managed/symlinked config paths, remote effects, package install guards,
 * investigation mode, and pipe/redirect hang prevention.
 */

import { execSync, spawnSync } from "node:child_process";
import {
	existsSync,
	lstatSync,
	readFileSync,
	realpathSync,
	statSync,
} from "node:fs";
import { dirname, isAbsolute, join, normalize, resolve } from "node:path";
import type {
	ExtensionAPI,
	InputEventResult,
	ToolCallEvent,
	ToolCallEventResult,
} from "@earendil-works/pi-coding-agent";

type Tier = "hard" | "confirm" | "rewrite";

interface Rule {
	name: string;
	tier: Tier;
	tools: string[];
	test: (cmd: string, path?: string) => boolean;
	reason: string | ((cmd: string, path?: string) => string);
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
	vim: { reason: "Use Write/Edit tool or heredoc." },
	nvim: { reason: "Use Write/Edit tool or heredoc." },
	nano: { reason: "Use Write/Edit tool or heredoc." },
	emacs: { reason: "Use Write/Edit tool or heredoc." },
	vi: { reason: "Use Write/Edit tool or heredoc." },
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
	}
> = {
	find: { use: "fd", reason: "Use `fd` instead of `find`." },
	grep: { use: "rg", reason: "Use `rg` instead of `grep`." },
	rm: { use: "trash", reason: "Use `trash` instead of `rm`." },
	rmdir: { use: "trash", reason: "Use `trash` instead of `rmdir`." },
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
	return p.replace(/^~\//, `${HOME}/`).replace(/^\$HOME\//, `${HOME}/`);
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
				const endPattern = `\n${delim}`;
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
function _splitSegments(stripped: string): string[] {
	return stripped.split(/\s*(?:\|\||&&|[|;]|\$\()\s*/);
}

interface Invocation {
	name: string;
	tokens: string[];
	raw: string;
}

function basename(cmd: string): string {
	return (
		cmd
			.replace(/^['"]|['"]$/g, "")
			.split("/")
			.pop() || cmd
	);
}

function escapeRegExp(text: string): string {
	return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function shellWords(script: string): string[] {
	const words: string[] = [];
	let cur = "";
	let quote: string | null = null;

	for (let i = 0; i < script.length; i++) {
		const ch = script[i];
		if (quote) {
			if (ch === quote) {
				quote = null;
				continue;
			}
			if (quote === '"' && ch === "\\" && i + 1 < script.length) {
				cur += script[++i];
				continue;
			}
			cur += ch;
			continue;
		}
		if (ch === "'" || ch === '"') {
			quote = ch;
			continue;
		}
		if (/\s/.test(ch)) {
			if (cur) {
				words.push(cur);
				cur = "";
			}
			continue;
		}
		cur += ch;
	}
	if (cur) words.push(cur);
	return words;
}

function splitTopLevel(script: string): string[] {
	const segments: string[] = [];
	let cur = "";
	let quote: string | null = null;
	for (let i = 0; i < script.length; i++) {
		const ch = script[i];
		if (quote) {
			cur += ch;
			if (ch === "\\" && quote === '"' && i + 1 < script.length)
				cur += script[++i];
			else if (ch === quote) quote = null;
			continue;
		}
		if (ch === "'" || ch === '"') {
			quote = ch;
			cur += ch;
			continue;
		}
		if (ch === "|" || ch === ";" || ch === "&" || ch === "\n") {
			if (cur.trim()) segments.push(cur.trim());
			cur = "";
			if ((ch === "|" || ch === "&") && script[i + 1] === ch) i++;
			continue;
		}
		cur += ch;
	}
	if (cur.trim()) segments.push(cur.trim());
	return segments;
}

function extractCommandSubscripts(script: string): string[] {
	const nested: string[] = [];
	for (const match of script.matchAll(/\$\(([^()]+)\)|`([^`]+)`/g)) {
		nested.push(match[1] || match[2]);
	}
	return nested;
}

function isEnvAssignment(word: string): boolean {
	return /^[A-Za-z_][A-Za-z0-9_]*=/.test(word);
}

function normalizeWords(words: string[]): string[] {
	let idx = 0;
	while (idx < words.length) {
		const word = words[idx];
		const base = basename(word || "");
		if (!word) {
			idx++;
			continue;
		}
		if (isEnvAssignment(word)) {
			idx++;
			continue;
		}
		if (base === "sudo" || base === "command") {
			idx++;
			while (idx < words.length && words[idx]?.startsWith("-")) idx++;
			if (words[idx] === "--") idx++;
			continue;
		}
		if (base === "env") {
			idx++;
			while (idx < words.length) {
				const envWord = words[idx];
				if (isEnvAssignment(envWord)) {
					idx++;
					continue;
				}
				if (envWord === "--") {
					idx++;
					continue;
				}
				if (envWord?.startsWith("-")) {
					idx++;
					continue;
				}
				break;
			}
			continue;
		}
		break;
	}
	return words.slice(idx);
}

function collectInvocations(script: string, depth = 0): Invocation[] {
	if (depth > 3) return [];
	const invocations: Invocation[] = [];
	for (const inner of extractCommandSubscripts(script)) {
		invocations.push(...collectInvocations(inner, depth + 1));
	}
	for (const segment of splitTopLevel(script)) {
		const words = normalizeWords(
			shellWords(segment).map((w) =>
				w.replace(/^[({]+/, "").replace(/[)}]+$/, ""),
			),
		);
		if (!words.length) continue;

		const shell = basename(words[0]);
		if (["sh", "bash", "zsh"].includes(shell)) {
			const cIdx = words.findIndex((w) => /^-[A-Za-z]*c[A-Za-z]*$/.test(w));
			const commandIdx =
				cIdx >= 0 && words[cIdx + 1] === "--" ? cIdx + 2 : cIdx + 1;
			if (cIdx >= 0 && words[commandIdx]) {
				invocations.push(...collectInvocations(words[commandIdx], depth + 1));
				continue;
			}
		}

		if (basename(words[0]) === "xargs") {
			const commandIdx = words.findIndex(
				(w, i) =>
					i > 0 &&
					!w.startsWith("-") &&
					!["-0", "-I", "-n", "-P"].includes(words[i - 1]),
			);
			if (commandIdx > 0) {
				const nested = normalizeWords(words.slice(commandIdx));
				if (nested.length)
					invocations.push({
						name: basename(nested[0]),
						tokens: nested,
						raw: segment,
					});
			}
		}

		invocations.push({ name: basename(words[0]), tokens: words, raw: segment });
	}
	return invocations;
}

/** Extract command names after unwrapping sudo/env/command/shell -c/xargs. */
function commandNames(cmd: string): string[] {
	return collectInvocations(cmd).map((inv) => inv.name);
}

/** Test if a pattern matches in stripped (non-quoted) command text. */
function cmdMatch(cmd: string, pattern: RegExp): boolean {
	return pattern.test(stripQuoted(cmd));
}

/** Test if any of the given names appear as a command (first token of a segment). */
function isCommand(cmd: string, ...names: string[]): boolean {
	return commandNames(cmd).some((c) => names.includes(c));
}

/** Test if a multi-word prefix appears at command position in any segment. */
function isCommandPrefix(cmd: string, ...prefix: string[]): boolean {
	return collectInvocations(cmd).some((inv) => {
		if (inv.tokens.length < prefix.length) return false;
		return prefix.every(
			(part, idx) =>
				(idx === 0 ? basename(inv.tokens[idx]) : inv.tokens[idx]) === part,
		);
	});
}

/** Get all tokens for a segment matching a command prefix. */
function segmentTokens(cmd: string, ...prefix: string[]): string[] | null {
	for (const inv of collectInvocations(cmd)) {
		if (inv.tokens.length < prefix.length) continue;
		if (
			prefix.every(
				(part, idx) =>
					(idx === 0 ? basename(inv.tokens[idx]) : inv.tokens[idx]) === part,
			)
		)
			return inv.tokens;
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

function isBareInteractiveTool(cmd: string, tool: string): boolean {
	const tokens = segmentTokens(cmd, tool);
	if (!tokens) return false;
	if (tool === "mysql") {
		return !tokens.some(
			(t) => t === "-e" || t === "--execute" || t.startsWith("--execute="),
		);
	}
	if (tool === "psql") {
		return !tokens.some(
			(t) =>
				t === "-c" ||
				t === "--command" ||
				t.startsWith("--command=") ||
				t === "-f" ||
				t === "--file" ||
				t.startsWith("--file="),
		);
	}
	if (tool === "sqlite3") {
		// `sqlite3 DB` is interactive; `sqlite3 DB SQL` is not.
		return tokens.length < 3;
	}
	return true;
}

function resolveTargetPath(rawPath: string, cwd = process.cwd()): string {
	let expanded = rawPath;
	if (expanded === "~" || expanded === "$HOME") expanded = HOME;
	else if (expanded.startsWith("~/")) expanded = `${HOME}/${expanded.slice(2)}`;
	else if (expanded.startsWith("$HOME/"))
		expanded = `${HOME}/${expanded.slice(6)}`;
	return normalize(isAbsolute(expanded) ? expanded : resolve(cwd, expanded));
}

const SHELL_CONFIG_FILES = [
	".zshrc",
	".bashrc",
	".bash_profile",
	".profile",
	".zprofile",
	".zshenv",
	".zlogin",
	".inputrc",
	".config/fish/config.fish",
];
const SYSTEM_PATH_PREFIXES = [
	"/usr/",
	"/Library/",
	"/System/",
	"/opt/",
	"/etc/",
	"/var/",
	"/bin/",
	"/sbin/",
	"/private/",
];

function pathRisk(path: string): string | null {
	const p = resolveTargetPath(path);
	if (SHELL_CONFIG_FILES.some((file) => p === join(HOME, file))) {
		return "shell config";
	}
	if (
		SYSTEM_PATH_PREFIXES.some(
			(prefix) => p === prefix.slice(0, -1) || p.startsWith(prefix),
		)
	) {
		return "system path";
	}
	return null;
}

function bashRiskLabels(cmd: string): string[] {
	const labels = new Set<string>();
	const stripped = stripQuoted(cmd);
	const scanText = [
		stripped,
		...collectInvocations(cmd).map((inv) => stripQuoted(inv.raw)),
	].join("\n");
	const homePrefix = escapeRegExp(HOME);
	const shellConfigTarget = new RegExp(
		`(?:>>?|tee\\b[^\\n|]*)\\s*(?:(?:~|\\$HOME|${homePrefix})/)?\\.?(?:zshrc|bashrc|bash_profile|profile|zprofile|zshenv|zlogin|inputrc)\\b`,
	);
	if (
		/\b(?:curl|wget)\b[^\n|]*\|\s*(?:(?:\/\S+\/)?sudo\s+)?(?:\/\S+\/)?(?:bash|sh|zsh)\b/.test(
			scanText,
		)
	) {
		labels.add("remote-pipe-exec");
	}
	if (/(^|[;&|()\s])(?:\/\S+\/)?sudo\b/.test(scanText))
		labels.add("privilege-escalation");
	if (
		/\b(?:crontab\s+-|systemctl\s+enable|launchctl\s+(?:load|bootstrap))\b/.test(
			scanText,
		)
	) {
		labels.add("persistence");
	}
	if (
		/\b(?:cp|mv|install|ln)\b[^\n|;]*\s\/usr\/local\/(?:bin|sbin|lib)\/?/.test(
			scanText,
		)
	) {
		labels.add("system-binary-install");
	}
	if (shellConfigTarget.test(scanText)) {
		labels.add("shell-config-write");
	}
	return [...labels];
}

function isDestructiveSystemRm(cmd: string): boolean {
	const tokens = segmentTokens(cmd, "rm");
	if (!tokens) return false;
	const hasRecursive = tokens.some(
		(t) => t === "--recursive" || /^-[A-Za-z]*[rR]/.test(t),
	);
	const hasForce = tokens.some(
		(t) => t === "--force" || /^-[A-Za-z]*f/.test(t),
	);
	if (!hasRecursive || !hasForce) return false;
	return tokens.slice(1).some((target) => {
		const p =
			target === "~" || target.startsWith("~/") || target.startsWith("$HOME")
				? resolveTargetPath(target)
				: target;
		return (
			p === HOME ||
			SYSTEM_PATH_PREFIXES.some(
				(prefix) => p === prefix.slice(0, -1) || p.startsWith(prefix),
			)
		);
	});
}

function scriptExecutionTargets(cmd: string, cwd: string): string[] {
	const targets: string[] = [];
	for (const inv of collectInvocations(cmd)) {
		const [name, ...args] = inv.tokens;
		if (["bash", "sh", "zsh"].includes(basename(name))) {
			const target = args.find((arg) => !arg.startsWith("-"));
			if (target) targets.push(resolveTargetPath(target, cwd));
			continue;
		}
		if (name.startsWith(".") || name.includes("/")) {
			targets.push(resolveTargetPath(name, cwd));
		}
	}
	return targets;
}

function scanScriptRisks(path: string): string[] {
	try {
		if (!existsSync(path) || statSync(path).isDirectory()) return [];
		const body = readFileSync(path, "utf-8");
		const risks: string[] = [];
		if (/\b(?:curl|wget)\b[^\n|]*\|\s*(?:sudo\s+)?(?:bash|sh|zsh)\b/.test(body))
			risks.push("remote-pipe-exec");
		if (/\beval\b/.test(body)) risks.push("eval");
		if (/\bcurl\b[^\n]*\b-X\s*POST\b/.test(body))
			risks.push("possible-exfiltration");
		if (/\brm\s+-[A-Za-z]*r[A-Za-z]*f\b/.test(body))
			risks.push("recursive-delete");
		if (/\bchmod\s+777\b/.test(body)) risks.push("chmod-777");
		if (/\bsudo\b/.test(body)) risks.push("privilege-escalation");
		if (
			/\b(?:crontab\s+-|systemctl\s+enable|launchctl\s+(?:load|bootstrap))\b/.test(
				body,
			)
		)
			risks.push("persistence");
		return risks;
	} catch {
		return [];
	}
}

// ── Conceptual classifiers ──────────────────────────────────────────────────

function ruleReason(rule: Rule, cmd: string, path?: string): string {
	return typeof rule.reason === "function"
		? rule.reason(cmd, path)
		: rule.reason;
}

function hasMessageOption(tokens: string[]): boolean {
	return (
		tokens.includes("-m") ||
		tokens.includes("--message") ||
		tokens.some((t) => t.startsWith("--message="))
	);
}

function interactiveBlockReason(cmd: string): string | null {
	for (const [tool, subcommands] of Object.entries(INTERACTIVE_COMMANDS)) {
		for (const [sub, entry] of Object.entries(subcommands)) {
			if (sub === "__base__") {
				if (entry.flags.length === 0 && isBareInteractiveTool(cmd, tool)) {
					return `⛔ ${entry.reason}`;
				}
				const tokens = segmentTokens(cmd, tool);
				if (tokens && entry.flags.some((flag) => tokens.includes(flag))) {
					return `⛔ ${entry.reason}`;
				}
				continue;
			}

			if (entry.flags.length === 0) {
				if (isCommandPrefix(cmd, tool, sub)) return `⛔ ${entry.reason}`;
				continue;
			}

			const tokens = segmentTokens(cmd, tool, sub);
			if (tokens && entry.flags.some((flag) => tokens.includes(flag))) {
				return `⛔ ${entry.reason}`;
			}
		}
	}

	for (const [tool, entry] of Object.entries(ALWAYS_INTERACTIVE_COMMANDS)) {
		if (!isCommand(cmd, tool)) continue;
		if (entry.unlessArgs && hasArgs(cmd, tool)) continue;
		return `⛔ ${entry.reason}`;
	}

	return null;
}

function vcsEditorBlockReason(cmd: string): string | null {
	const describeTokens =
		segmentTokens(cmd, "jj", "describe") || segmentTokens(cmd, "jj", "dm");
	if (describeTokens && !hasMessageOption(describeTokens)) {
		return '⛔ Opens editor. Use `jj describe -m "message"`';
	}

	const commitTokens = segmentTokens(cmd, "jj", "commit");
	if (commitTokens && !hasMessageOption(commitTokens)) {
		return '⛔ Opens editor. Use `jj commit -m "message"`';
	}

	const squashTokens = segmentTokens(cmd, "jj", "squash");
	if (
		squashTokens &&
		!hasMessageOption(squashTokens) &&
		!squashTokens.includes("-u") &&
		!squashTokens.includes("--use-destination-message")
	) {
		return '⛔ May open editor. Use `-m "message"` or `-u`';
	}

	if (isCommandPrefix(cmd, "jj", "split")) {
		return "⛔ Inherently interactive. Use separate commits.";
	}

	return null;
}

const MANAGED_CONFIG_PREFIXES = [
	`${HOME}/bin/`,
	`${HOME}/.config/`,
	`${HOME}/.hammerspoon/`,
	`${HOME}/.pi/agent/`,
];

function managedConfigWriteReason(path?: string): string | null {
	if (!path) return null;
	const p = normalizePath(path);
	if (MANAGED_CONFIG_PREFIXES.some((prefix) => p.startsWith(prefix))) {
		return "⛔ Managed config path. Edit the owning source in ~/.dotfiles/ or the active dotfiles owner instead.";
	}

	try {
		let cur = p;
		while (cur && cur !== dirname(cur)) {
			if (existsSync(cur) && lstatSync(cur).isSymbolicLink()) {
				const target = realpathSync(cur);
				if (
					target.startsWith("/nix/store/") ||
					target.startsWith(`${HOME}/.dotfiles/`)
				) {
					return "⛔ Symlinked managed config path. Edit the source path, not the linked target.";
				}
			}
			cur = dirname(cur);
		}
	} catch {
		return null;
	}

	return null;
}

function nixBuildResultUnsafe(cmd: string): boolean {
	if (!isCommandPrefix(cmd, "nix", "build")) return false;
	const tokens = segmentTokens(cmd, "nix", "build");
	if (!tokens) return false;
	if (tokens.includes("--no-link")) return false;
	for (let i = 0; i < tokens.length; i++) {
		if (tokens[i] === "-o" || tokens[i] === "--out-link") {
			const target = tokens[i + 1];
			if (target?.startsWith("/tmp/")) return false;
		}
		if (
			tokens[i].startsWith("--out-link=/tmp/") ||
			tokens[i].startsWith("-o=/tmp/")
		) {
			return false;
		}
	}
	return true;
}

function historyDestructiveReason(cmd: string): string | null {
	const jjReasons: Record<string, string> = {
		rebase: "Can discard uncommitted changes or flatten commit history.",
		abandon: "Permanently discards changes.",
		restore: "Can overwrite uncommitted changes.",
		undo: "Can affect uncommitted work.",
	};
	for (const [sub, reason] of Object.entries(jjReasons)) {
		if (isCommandPrefix(cmd, "jj", sub)) return reason;
	}

	const squashTokens = segmentTokens(cmd, "jj", "squash");
	if (squashTokens) {
		const broadOptions = [
			"--from",
			"-f",
			"--into",
			"--to",
			"-t",
			"-r",
			"--revision",
			"-d",
			"--destination",
			"-A",
			"--insert-after",
			"-B",
			"--insert-before",
		];
		if (squashTokens.some((token) => broadOptions.includes(token))) {
			return "Squash with --from/--into/-r can flatten history. Simple `jj squash` is safe.";
		}
	}

	if (isCommandPrefix(cmd, "git", "rebase"))
		return "Git rebase rewrites history.";
	if (isCommandPrefix(cmd, "git", "reset"))
		return "Git reset can discard or move history.";
	if (isCommandPrefix(cmd, "git", "clean"))
		return "Git clean permanently removes untracked files.";
	const checkoutTokens = segmentTokens(cmd, "git", "checkout");
	if (checkoutTokens?.some((t) => t === "-f" || t === "--force")) {
		return "Forced checkout can overwrite local changes.";
	}
	const switchTokens = segmentTokens(cmd, "git", "switch");
	if (switchTokens?.some((t) => t === "-f" || t === "--force")) {
		return "Forced switch can overwrite local changes.";
	}
	const commitTokens = segmentTokens(cmd, "git", "commit");
	if (commitTokens?.some((t) => t === "--amend" || t.startsWith("--fixup"))) {
		return "Git commit option can rewrite or reshape history.";
	}

	return null;
}

function isPushCommand(cmd: string): boolean {
	return (
		isCommandPrefix(cmd, "jj", "push") ||
		isCommandPrefix(cmd, "jj", "git", "push") ||
		isCommandPrefix(cmd, "git", "push")
	);
}

function remoteEffectsReason(cmd: string): string | null {
	if (isPushCommand(cmd)) return "Push to remote.";
	if (
		isCommand(cmd, "deploy", "vercel", "dokploy") ||
		isCommandPrefix(cmd, "fly", "deploy") ||
		isCommandPrefix(cmd, "netlify", "deploy") ||
		isCommandPrefix(cmd, "kubectl", "apply") ||
		isCommandPrefix(cmd, "terraform", "apply") ||
		isCommandPrefix(cmd, "pulumi", "up")
	) {
		return "Deployment command.";
	}
	if (
		isCommand(cmd, "ssh", "scp") ||
		(isCommandPrefix(cmd, "rsync") && cmdMatch(cmd, /rsync\s+.*:/))
	) {
		return "Remote server access.";
	}
	return null;
}

const PACKAGE_INSTALL_ALLOWED_PATHS = [
	`${HOME}/.dotfiles/home/common/programs/pi-coding-agent/packages`,
];

function isAllowedPackageInstallLocation(path?: string): boolean {
	const normalizedPath = normalizePath(path || "");
	return PACKAGE_INSTALL_ALLOWED_PATHS.some(
		(allowed) =>
			normalizedPath === allowed || normalizedPath.startsWith(`${allowed}/`),
	);
}

function cdTarget(cmd: string, cwd?: string): string | null {
	const match = cmd.match(/(?:^|[;&|]\s*)cd\s+([^;&|\n]+)/);
	if (!match) return null;
	return resolveTargetPath(
		match[1].trim().replace(/^['"]|['"]$/g, ""),
		cwd || process.cwd(),
	);
}

function packageInstallReason(cmd: string, cwd?: string): string | null {
	if (isCommandPrefix(cmd, "mix", "deps.get")) return null;
	if (isAllowedPackageInstallLocation(cwd)) return null;
	const cdPath = cdTarget(cmd, cwd);
	if (cdPath && isAllowedPackageInstallLocation(cdPath)) return null;

	if (
		isCommandPrefix(cmd, "brew", "install") ||
		isCommandPrefix(cmd, "brew", "cask") ||
		isCommandPrefix(cmd, "brew", "tap")
	) {
		return "Homebrew install/tap changes external package state; prefer managed repo config when durable.";
	}

	const npmInstall =
		segmentTokens(cmd, "npm", "install") || segmentTokens(cmd, "npm", "i");
	if (npmInstall?.some((t) => t === "-g" || t === "--global")) {
		return "Global package install changes user-level tooling; prefer managed config when durable.";
	}
	if (
		isCommandPrefix(cmd, "pip", "install") ||
		isCommandPrefix(cmd, "pip3", "install") ||
		isCommandPrefix(cmd, "cargo", "install") ||
		isCommandPrefix(cmd, "go", "install")
	) {
		return "Global package install changes user-level tooling; prefer managed config when durable.";
	}

	if (
		isCommandPrefix(cmd, "npm", "install") ||
		isCommandPrefix(cmd, "npm", "i") ||
		isCommandPrefix(cmd, "npm", "add") ||
		isCommandPrefix(cmd, "yarn", "add") ||
		isCommandPrefix(cmd, "pnpm", "add") ||
		isCommandPrefix(cmd, "pnpm", "install") ||
		isCommandPrefix(cmd, "cargo", "add") ||
		isCommandPrefix(cmd, "bun", "add") ||
		isCommandPrefix(cmd, "bun", "install")
	) {
		return "Project dependency install changes lockfiles or dependency state; confirm scope first.";
	}

	if (isCommand(cmd, "npx", "bunx")) {
		return "One-shot package runner downloads or executes package code; confirm source first.";
	}

	return null;
}

function preferredToolRewriteReason(cmd: string): string | null {
	for (const pythonCmd of ["python", "python3"]) {
		const tokens = segmentTokens(cmd, pythonCmd);
		if (tokens?.[1] === "-m" && tokens[2] === "json.tool") {
			return "Use `jq .` instead of `python -m json.tool`.";
		}
	}

	for (const [blocked, correction] of Object.entries(TOOL_CORRECTIONS)) {
		if (isCommand(cmd, blocked)) return correction.reason;
	}

	return null;
}

function tccResetUnscoped(cmd: string): boolean {
	const tokens = segmentTokens(cmd, "tccutil", "reset");
	if (!tokens) return false;
	const service = tokens[2];
	const bundleId = tokens[3];
	if (!service) return true;
	if (service === "All") return true;
	return !bundleId || bundleId.startsWith("-");
}

// ── Build rules ──────────────────────────────────────────────────────────────

function buildRules(): Rule[] {
	let gatekeeperFindings = "";

	function checkDiffForSecrets(): { blocked: boolean; findings: string } {
		try {
			execSync("which gatekeeper", { encoding: "utf-8", stdio: "pipe" });
		} catch {
			log("gatekeeper not found, skipping secrets check");
			return { blocked: false, findings: "" };
		}

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
		} catch (_e) {
			log("failed to get diff for gatekeeper check");
			return { blocked: false, findings: "" };
		}

		if (!diff.trim()) return { blocked: false, findings: "" };

		try {
			const result = spawnSync("gatekeeper", ["--stdin", "--severity=high"], {
				input: diff,
				encoding: "utf-8",
				timeout: 30000,
			});

			if (result.status === 2) {
				return { blocked: true, findings: result.stdout || "Secrets detected" };
			}
			return { blocked: false, findings: "" };
		} catch (e) {
			log(`gatekeeper error: ${e}`);
			return { blocked: false, findings: "" };
		}
	}

	return [
		{
			name: "hard-interactive",
			tier: "hard",
			tools: ["bash"],
			test: (cmd) => interactiveBlockReason(cmd) !== null,
			reason: (cmd) =>
				interactiveBlockReason(cmd) || "⛔ Interactive command blocked.",
		},
		{
			name: "hard-vcs-editor",
			tier: "hard",
			tools: ["bash"],
			test: (cmd) => vcsEditorBlockReason(cmd) !== null,
			reason: (cmd) =>
				vcsEditorBlockReason(cmd) || "⛔ VCS command would open an editor.",
		},
		{
			name: "hard-managed-config-write",
			tier: "hard",
			tools: ["write", "edit"],
			test: (_cmd, path) => managedConfigWriteReason(path) !== null,
			reason: (_cmd, path) =>
				managedConfigWriteReason(path) ||
				"⛔ Managed/symlinked config path. Edit the source instead.",
		},
		{
			name: "hard-nix-build-result",
			tier: "hard",
			tools: ["bash"],
			test: (cmd) => nixBuildResultUnsafe(cmd),
			reason:
				"⛔ `nix build` creates ./result symlink. Use `--no-link` or `-o /tmp/<name>` and clean up after.",
		},
		{
			name: "hard-destructive-system-rm",
			tier: "hard",
			tools: ["bash"],
			test: (cmd) => isDestructiveSystemRm(cmd),
			reason:
				"⛔ Destructive recursive delete targeting home or system path. Use scoped `trash` only after explicit user approval.",
		},
		{
			name: "hard-secret-tools",
			tier: "hard",
			tools: ["bash"],
			test: (cmd) => isCommand(cmd, "pass", "gpg"),
			reason: "⛔ Secret tool access blocked.",
		},
		{
			name: "hard-gatekeeper-secrets",
			tier: "hard",
			tools: ["bash"],
			test: (cmd) => {
				if (!isPushCommand(cmd)) return false;
				const check = checkDiffForSecrets();
				if (!check.blocked) return false;
				gatekeeperFindings = check.findings;
				return true;
			},
			reason: () =>
				`⛔ **Secrets detected in diff!**\n\n\`\`\`\n${gatekeeperFindings}\`\`\`\n\n**Remove the secrets before pushing.** This cannot be overridden.`,
		},
		{
			name: "confirm-security-sensitive-bash",
			tier: "confirm",
			tools: ["bash", "write", "edit"],
			test: (cmd, path) =>
				bashRiskLabels(cmd).length > 0 || Boolean(path && pathRisk(path)),
			reason: (cmd, path) => {
				const labels = bashRiskLabels(cmd);
				if (labels.length > 0) {
					return `Security-sensitive shell operation (${labels.join(", ")}).`;
				}
				const risk = path ? pathRisk(path) : null;
				return risk
					? `Writes to ${risk} require explicit approval.`
					: "Security-sensitive operation requires explicit approval.";
			},
		},
		{
			name: "confirm-remote-effects",
			tier: "confirm",
			tools: ["bash"],
			test: (cmd) => remoteEffectsReason(cmd) !== null,
			reason: (cmd) => remoteEffectsReason(cmd) || "Remote side effect.",
		},
		{
			name: "confirm-package-install",
			tier: "confirm",
			tools: ["bash"],
			test: (cmd, path) => packageInstallReason(cmd, path) !== null,
			reason: (cmd, path) =>
				packageInstallReason(cmd, path) ||
				"Package install requires confirmation.",
		},
		{
			name: "confirm-history-destructive",
			tier: "confirm",
			tools: ["bash"],
			test: (cmd) => historyDestructiveReason(cmd) !== null,
			reason: (cmd) =>
				historyDestructiveReason(cmd) || "History-changing command.",
		},
		{
			name: "confirm-tcc-reset",
			tier: "confirm",
			tools: ["bash"],
			test: (cmd) => tccResetUnscoped(cmd),
			reason:
				"`tccutil reset` without a bundle-id resets the service for ALL apps. Use scoped form: `tccutil reset <SERVICE> <BUNDLE_ID>` (e.g. `tccutil reset SystemPolicyAllFiles com.mitchellh.ghostty`). Avoid `tccutil reset All` — it nukes every TCC permission for every app.",
		},
		{
			name: "rewrite-preferred-tools",
			tier: "rewrite",
			tools: ["bash"],
			test: (cmd) => preferredToolRewriteReason(cmd) !== null,
			reason: (cmd) => preferredToolRewriteReason(cmd) || "Use preferred tool.",
		},
		{
			name: "rewrite-builtin-grep",
			tier: "rewrite",
			tools: ["Grep"],
			test: () => true,
			reason: "Use `rg` via bash instead of the built-in Grep tool.",
		},
	];
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
	/^git\s/, // git commands are snapshot-style and terminate
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
	/^\s*(?:please\s+|can\s+you\s+|could\s+you\s+|would\s+you\s+)?(?:investigate|inspect|audit|check)\b/i;
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
	const sessionWrites = new Set<string>();

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
	pi.on("input", async (event, ctx): Promise<InputEventResult | undefined> => {
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
		async (event, ctx): Promise<ToolCallEventResult | undefined> => {
			const toolName = event.toolName;
			const input = (event as ToolCallEvent).input as Record<string, unknown>;
			const cmd = typeof input.command === "string" ? input.command : "";
			const rawPath = typeof input.path === "string" ? input.path : "";
			const cwd = ctx.cwd || process.cwd();
			const pathForRule = toolName === "bash" ? cwd : rawPath;
			const timeout =
				typeof input.timeout === "number" ? input.timeout : undefined;

			// ── Investigation mode: block writes unless user explicitly overrides ──
			if (investigationMode) {
				const writeKey = investigationWriteKey(toolName, cmd, rawPath);
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

			// ── Session write/execute correlation ──
			if (toolName === "bash" && cmd) {
				for (const target of scriptExecutionTargets(cmd, cwd)) {
					if (!sessionWrites.has(target)) continue;
					const risks = scanScriptRisks(target);
					if (risks.length === 0) continue;
					if (overrideGranted && blocked?.command === cmd) {
						if (consumeOverride()) return undefined;
					}
					blocked = {
						command: cmd,
						rule: "session-written-script",
						reason: `Session-written script has risky patterns: ${risks.join(", ")}`,
						timestamp: Date.now(),
					};
					log(`SESSION-EXEC: ${target}`);
					return {
						block: true,
						reason: `🔒 **session-written-script** — Script written in this session contains risky patterns: ${risks.join(", ")}

**Script:** \`${target}\`
**Command:** \`${cmd}\`

Explain why execution is needed, what it does, and say \`override\` to allow once.`,
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
				if (!rule.test(cmd, pathForRule)) continue;

				const reason = ruleReason(rule, cmd, pathForRule);

				if (rule.tier === "hard") {
					log(`HARD [${rule.name}]: ${(cmd || rawPath).slice(0, 60)}`);
					return { block: true, reason };
				}

				if (rule.tier === "rewrite") {
					log(`REWRITE [${rule.name}]: ${cmd.slice(0, 60)}`);
					return { block: true, reason: `⚙️ ${reason}` };
				}

				if (rule.tier === "confirm") {
					const confirmKey = cmd || rawPath;
					if (overrideGranted && blocked?.command === confirmKey) {
						if (consumeOverride()) return undefined;
					}
					blocked = {
						command: confirmKey,
						rule: rule.name,
						reason,
						timestamp: Date.now(),
					};
					log(`CONFIRM [${rule.name}]: ${confirmKey.slice(0, 60)}`);
					const cmdPreview =
						confirmKey.length > 200
							? `${confirmKey.slice(0, 200)}...`
							: confirmKey;
					return {
						block: true,
						reason: `🔒 **${rule.name}** — ${reason}

**Command:** \`${cmdPreview}\`

**Agent:** Before asking for override, explain to the user:
1. What this command does
2. Why it was blocked (${reason})
3. Whether it's safe to override in this context

Say \`override\` to allow.`,
					};
				}
			}

			if ((toolName === "write" || toolName === "edit") && rawPath) {
				sessionWrites.add(resolveTargetPath(rawPath, cwd));
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
