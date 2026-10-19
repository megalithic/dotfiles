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

	// The two files fail independently: a bad models.json must not turn activation off.
	function loadConfig(ctx: ExtensionContext) {
		const errors: string[] = [];

		try {
			config = readConfig(agentDir());
		} catch (error) {
			config = DEFAULT_CONFIG;
			errors.push(error instanceof Error ? error.message : String(error));
		}

		try {
			roles = readRoleTable(agentDir());
		} catch (error) {
			roles = {};
			errors.push(error instanceof Error ? error.message : String(error));
		}

		configError = errors.length ? errors.join("; ") : undefined;

		if (configError) ctx.ui.notify(configError, "error");
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
		const label = on ? `mega ${source === "auto" ? "auto" : "on"}` : source === "override" ? "mega off" : undefined;
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

	pi.registerCommand("mega-mode", {
		description: "Mega mode (pstack): on | off | auto | status, or a task to run in the mode",
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
					ctx.ui.notify(`Mega mode ${cmd.on ? "on" : "off"} for this session.`, "info");

					return;
				case "auto":
					pi.appendEntry(STATE_ENTRY, { on: null });
					restore(ctx);
					ctx.ui.notify(`Mega mode follows the cwd rule: ${on ? "on" : "off"} here.`, "info");

					return;
				case "status": {
					const where = configError ? `config error: ${configError}` : `${config.activate.length} activation path(s)`;
					ctx.ui.notify(`Mega mode ${on ? "on" : "off"} (${source}); ${where}; config ${configPath(agentDir())}`, "info");

					return;
				}

				case "task": {
					// Upstream's `/poteto-mode <task>`, here `/mega-mode <task>`: turn the mode on so the map is in the prompt, then run the skill.
					pi.appendEntry(STATE_ENTRY, { on: true });
					on = true;
					source = "override";
					status(ctx);

					// sendUserMessage expands /skill: only with expandPromptTemplates.
					const message = `/skill:mega-mode ${cmd.text}`;

					if (ctx.isIdle()) pi.sendUserMessage(message, { expandPromptTemplates: true });
					else pi.sendUserMessage(message, { expandPromptTemplates: true, deliverAs: "followUp" });
				}
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
			let current: RoleTable;

			try {
				current = readRoleTable(agentDir());
			} catch (error) {
				ctx.ui.notify(`${error instanceof Error ? error.message : String(error)}. Fix it, then rerun /setup-pstack.`, "error");

				return;
			}

			// Written fresh each run so $available never goes stale; role lines are kept.
			const next: ModelsFile = {
				$comment: 'Add one line per role from $roles: "provider/id:thinking", or a list of them for a panel role (one reviewer per entry; give panels two or more models). A role with no line runs on the parent model.',
				$roles: [...ROLES],
				$available: available,
				...current,
			};

			writeFileSync(tablePath, JSON.stringify(next, null, 2) + "\n");
			ctx.ui.notify(`Wrote ${tablePath} (${available.length} models visible). Edit the role lines, add activation paths to ${cfgPath}, then /reload.`, "info");
		},
	});
}
