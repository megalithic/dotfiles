// @ts-nocheck
/**
 * Shared command-capture glue for Heimdall adapters.
 *
 * Heimdall gives Pi agents access to extension slash-command behavior by
 * loading a target extension's exported factory, capturing selected
 * registerCommand handlers, and invoking those exact handlers from tools.
 * It is extension-agnostic; adapters only map typed tool parameters to each
 * command's argument string.
 */

import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type {
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";

type ToolDetailValue = string | number | boolean;

export interface TextToolResult {
	content: { type: "text"; text: string }[];
	details?: Record<string, ToolDetailValue>;
}

export interface CapturedCommand {
	name: string;
	description?: string;
	handler: (args: string, ctx: ExtensionContext) => void | Promise<void>;
}

interface ExtensionModule {
	default?: (pi: ExtensionAPI) => void | Promise<void>;
}

export interface CommandCaptureOptions {
	/**
	 * Adapter-specific isolation for factory initialization side effects.
	 * Called immediately before the factory; returned cleanup always runs.
	 */
	isolateFactory?: () => void | (() => void);
	/**
	 * Forward only lifecycle hooks required by captured handlers. Index is
	 * zero-based per event name; all hooks are suppressed by default.
	 */
	forwardEvent?: (eventName: string, index: number) => boolean;
}

export function textResult(
	text: string,
	details?: Record<string, ToolDetailValue>,
): TextToolResult {
	const result: TextToolResult = { content: [{ type: "text", text }] };
	if (details) result.details = details;
	return result;
}

export function errorText(err: unknown): string {
	return err instanceof Error ? err.message : String(err);
}

export const PI_NPM_MODULES = join(
	homedir(),
	".pi",
	"agent",
	"npm",
	"node_modules",
);

/** Import a Pi-installed package module without crashing extension startup. */
export async function importPiPackageModule<T>(
	relPath: string,
): Promise<
	{ module: T; error?: undefined } | { module?: undefined; error: string }
> {
	const abs = join(PI_NPM_MODULES, relPath);
	if (!existsSync(abs)) {
		return {
			error: `Package module not found: ${abs}. Is the package installed via Pi?`,
		};
	}
	try {
		return { module: (await import(abs)) as T };
	} catch (err) {
		return { error: `Failed to load ${relPath}: ${errorText(err)}` };
	}
}

const IGNORED_REGISTRATIONS = new Set([
	"registerFlag",
	"registerMessageRenderer",
	"registerProvider",
	"registerShortcut",
	"registerTool",
	"unregisterProvider",
]);

const EVENT_LISTENER_METHODS = new Set([
	"addListener",
	"off",
	"on",
	"once",
	"prependListener",
	"removeAllListeners",
	"removeListener",
]);

/**
 * Load an extension factory and capture selected slash-command handlers.
 *
 * Registration and lifecycle hooks are suppressed so Heimdall does not load a
 * duplicate copy of the target extension's tools, flags, shortcuts, or event
 * handlers. Runtime API calls made later by captured command handlers delegate
 * to Heimdall's real ExtensionAPI, including sendUserMessage follow-ups.
 */
export async function captureExtensionCommands(
	pi: ExtensionAPI,
	packageEntry: string,
	requiredNames: readonly string[],
	options: CommandCaptureOptions = {},
): Promise<
	| { commands: Map<string, CapturedCommand>; error?: undefined }
	| { commands?: undefined; error: string }
> {
	const imported = await importPiPackageModule<ExtensionModule>(packageEntry);
	if (!imported.module) return { error: imported.error };
	if (typeof imported.module.default !== "function") {
		return { error: `${packageEntry} has no default extension factory export.` };
	}

	const commands = new Map<string, CapturedCommand>();
	const realEvents =
		typeof pi.events === "object" && pi.events !== null ? pi.events : {};
	const eventFacade = new Proxy(realEvents, {
		get(target, property) {
			if (typeof property === "string" && EVENT_LISTENER_METHODS.has(property)) {
				return () => undefined;
			}
			const value = Reflect.get(target, property, target);
			return typeof value === "function" ? value.bind(target) : value;
		},
	});
	const eventRegistrationCounts = new Map<string, number>();
	const captureApi = new Proxy(pi, {
		get(target, property) {
			if (property === "registerCommand") {
				return (
					name: string,
					options: {
						description?: string;
						handler?: CapturedCommand["handler"];
					},
				) => {
					if (typeof options?.handler === "function") {
						commands.set(name, {
							name,
							description: options.description,
							handler: options.handler,
						});
					}
				};
			}
			if (property === "on") {
				return (eventName: string, handler: (...args: unknown[]) => unknown) => {
					const index = eventRegistrationCounts.get(eventName) ?? 0;
					eventRegistrationCounts.set(eventName, index + 1);
					if (options.forwardEvent?.(eventName, index)) {
						return target.on(eventName, handler);
					}
					return undefined;
				};
			}
			if (property === "events") return eventFacade;
			if (typeof property === "string" && IGNORED_REGISTRATIONS.has(property)) {
				return () => undefined;
			}
			const value = Reflect.get(target, property, target);
			return typeof value === "function" ? value.bind(target) : value;
		},
	}) as ExtensionAPI;

	let restoreFactoryState: void | (() => void);
	try {
		restoreFactoryState = options.isolateFactory?.();
		await imported.module.default(captureApi);
	} catch (err) {
		return {
			error: `Failed to initialize ${packageEntry} for command capture: ${errorText(err)}`,
		};
	} finally {
		restoreFactoryState?.();
	}

	const missing = requiredNames.filter((name) => !commands.has(name));
	if (missing.length > 0) {
		return {
			error: `${packageEntry} did not register required command(s): ${missing.join(", ")}.`,
		};
	}
	return { commands };
}
