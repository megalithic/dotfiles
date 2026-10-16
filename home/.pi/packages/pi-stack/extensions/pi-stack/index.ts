import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { type Config, type JsonValue, DEFAULT_CONFIG, ROLES, type RoleTable, configPath, matchesActivation, modelsPath, readConfig, readRoleTable } from "./config.ts";
import { PI_STACK_AGENTS, applySections, dropSections } from "./sections.ts";
import { STATE_ENTRY, parseCommand, resolveMode } from "./state.ts";

const PACKAGE_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");

const PRIMITIVES = readFileSync(join(PACKAGE_ROOT, "references", "pi-primitives.md"), "utf8");

/** Reads the agent dir the way pi does, without importing pi's config module at load time. */
function agentDir(): string {
	return process.env.PI_CODING_AGENT_DIR ?? join(process.env.HOME ?? "", ".pi", "agent");
}

interface ModelsFile {
	[key: string]: JsonValue;
}

export default function piStack(pi: ExtensionAPI) {
	// A subagent child never runs the playbook; its agent file carries the primitive map.
	// Our own delegates still drop superseded sections, since full-tool children load every extension.
	const child = process.env.PI_SUBAGENT_AGENT;

	if (child !== undefined) {
		if (!PI_STACK_AGENTS.has(child)) return;

		let supersedes: string[] = [];

		pi.on("session_start", async (_event, ctx) => {
			try {
				supersedes = readConfig(agentDir()).supersedes;
			} catch (error) {
				ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
			}
		});
		pi.on("before_agent_start", async (event) => {
			dropSections(event.systemPromptOptions.sections, supersedes);
		});

		return;
	}

	let config: Config = DEFAULT_CONFIG;
	let roles: RoleTable = {};
	let configError: string | undefined;
	let on = false;
	let source: "override" | "auto" = "auto";

	function loadConfig(ctx: ExtensionContext) {
		try {
			config = readConfig(agentDir());
			roles = readRoleTable(agentDir());
			configError = undefined;
		} catch (error) {
			config = DEFAULT_CONFIG;
			configError = error instanceof Error ? error.message : String(error);
			ctx.ui.notify(configError, "error");
		}
	}

	function restore(ctx: ExtensionContext) {
		const autoOn = matchesActivation(ctx.cwd, config.activate);
		const resolved = resolveMode(ctx.sessionManager.getBranch(), autoOn);
		on = resolved.on;
		source = resolved.source;
		status(ctx);
	}

	function status(ctx: ExtensionContext) {
		if (!ctx.hasUI) return;
		const label = on ? `poteto ${source === "auto" ? "auto" : "on"}` : source === "override" ? "poteto off" : undefined;
		ctx.ui.setStatus("pi-stack", label);
	}

	// Handlers run grouped by extension load order, so `supersedes` only removes a section
	// written by an extension that loads before pi-stack (keep pi-stack last in packages).
	pi.on("before_agent_start", async (event) => {
		applySections(event.systemPromptOptions.sections, on, {
			packageRoot: PACKAGE_ROOT,
			config,
			roles,
			tools: event.systemPromptOptions.selectedTools,
			primitives: PRIMITIVES,
		});
	});

	pi.on("session_start", async (_event, ctx) => {
		loadConfig(ctx);
		restore(ctx);
	});

	pi.on("session_tree", async (_event, ctx) => restore(ctx));

	pi.registerCommand("poteto-mode", {
		description: "Poteto mode (pstack): on | off | auto | status",
		getArgumentCompletions: (prefix) =>
			["on", "off", "auto", "status"].flatMap((v) => (v.startsWith(prefix.trim()) ? [{ value: v, label: v }] : [])),
		handler: async (args, ctx) => {
			const cmd = parseCommand(args);

			switch (cmd.kind) {
				case "set":
					pi.appendEntry(STATE_ENTRY, { on: cmd.on });
					on = cmd.on;
					source = "override";
					status(ctx);
					ctx.ui.notify(`Poteto mode ${cmd.on ? "on" : "off"} for this session.`, "info");

					return;
				case "auto":
					pi.appendEntry(STATE_ENTRY, { on: null });
					restore(ctx);
					ctx.ui.notify(`Poteto mode follows the cwd rule: ${on ? "on" : "off"} here.`, "info");

					return;
				case "status": {
					const where = configError ? `config error: ${configError}` : `${config.activate.length} activation path(s)`;
					ctx.ui.notify(`Poteto mode ${on ? "on" : "off"} (${source}); ${where}; config ${configPath(agentDir())}`, "info");

					return;
				}

				case "invalid":
					ctx.ui.notify(`Unknown argument "${cmd.text}". Use on, off, auto, or status.`, "warning");
			}
		},
	});

	pi.registerCommand("setup-pstack", {
		description: "Write ~/.pi/agent/pi-stack/{config,models}.json from the models pi can see, then edit by hand",
		handler: async (_args, ctx) => {
			const dir = join(agentDir(), "pi-stack");
			mkdirSync(dir, { recursive: true });
			const cfgPath = configPath(agentDir());

			if (!existsSync(cfgPath)) {
				writeFileSync(cfgPath, JSON.stringify({ activate: [], supersedes: [] }, null, 2) + "\n");
			}

			const available = ctx.modelRegistry.getAvailable().map((m) => `${m.provider}/${m.id}`);
			const tablePath = modelsPath(agentDir());
			const current = existsSync(tablePath) ? JSON.parse(readFileSync(tablePath, "utf8")) : {};

			const next: ModelsFile = {
				$comment: 'One line per role: "provider/id:thinking", a list of them for panel roles (one seat per entry), or inherit-parent. Delete a line to inherit the parent model.',
				$available: available,
				...current,
			};

			for (const role of ROLES) if (next[role] === undefined) next[role] = "inherit-parent";
			writeFileSync(tablePath, JSON.stringify(next, null, 2) + "\n");
			ctx.ui.notify(`Wrote ${tablePath} (${available.length} models visible). Edit the role lines, add activation paths to ${cfgPath}, then /reload.`, "info");
		},
	});
}
