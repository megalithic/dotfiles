// @ts-nocheck
/**
 * Heimdall adapter for @plannotator/pi-extension.
 *
 * Loads Plannotator's exported extension factory, captures its real
 * /plannotator-review, /plannotator-annotate, and /plannotator-last handlers,
 * then exposes typed agent tools that invoke those handlers. Plannotator keeps
 * ownership of browser startup, asynchronous decisions, configured prompts,
 * cross-session fallback, notifications, flags, and errors.
 *
 * Verified against @plannotator/pi-extension 0.27.9.
 */

import type {
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import {
	type CapturedCommand,
	captureExtensionCommands,
	errorText,
	textResult,
} from "./lib.ts";

const PACKAGE_ENTRY = "@plannotator/pi-extension/index.ts";
const COMMAND_NAMES = [
	"plannotator-review",
	"plannotator-annotate",
	"plannotator-last",
] as const;

let capturedPromise: ReturnType<typeof captureExtensionCommands> | undefined;

type PlannotatorGlobal = typeof globalThis & {
	__plannotatorCurrentPiSession?: { current?: unknown };
};

type ArgumentResult =
	| { value: string; error?: undefined }
	| { value?: undefined; error: string };

type CapturedNotification = {
	message: string;
	type: "info" | "warning" | "error";
};

function isolatePlannotatorFactory(): () => void {
	const global = globalThis as PlannotatorGlobal;
	const hadStore = Object.prototype.hasOwnProperty.call(
		global,
		"__plannotatorCurrentPiSession",
	);
	const originalStore = global.__plannotatorCurrentPiSession;
	const originalCurrent = originalStore?.current;
	return () => {
		if (!hadStore) {
			global.__plannotatorCurrentPiSession = undefined;
			return;
		}
		const store = global.__plannotatorCurrentPiSession ?? originalStore ?? {};
		store.current = originalCurrent;
		global.__plannotatorCurrentPiSession = store;
	};
}

function loadCommands(pi: ExtensionAPI) {
	if (!capturedPromise) {
		capturedPromise = captureExtensionCommands(pi, PACKAGE_ENTRY, COMMAND_NAMES, {
			isolateFactory: isolatePlannotatorFactory,
			// Plannotator's first start/shutdown hooks maintain the global current-
			// session router used by background browser feedback. Later start hooks
			// are plan-mode lifecycle and must stay suppressed.
			forwardEvent: (eventName, index) =>
				(eventName === "session_start" || eventName === "session_shutdown") &&
				index === 0,
		});
	}
	return capturedPromise;
}

function quoteArgument(value: string): ArgumentResult {
	const trimmed = value.trim();
	if (!trimmed) return { value: "" };
	const needsQuotes = /\s/.test(trimmed) || trimmed.startsWith("--");
	if (!needsQuotes) return { value: trimmed };
	if (!trimmed.includes('"')) return { value: `"${trimmed}"` };
	if (!trimmed.includes("'")) return { value: `'${trimmed}'` };
	return {
		error:
			"Target contains whitespace plus both quote characters; pass exact rawArgs instead.",
	};
}

function captureNotifications(ctx: ExtensionContext): {
	ctx: ExtensionContext;
	notifications: CapturedNotification[];
} {
	const notifications: CapturedNotification[] = [];
	const ui = new Proxy(ctx.ui, {
		get(target, property) {
			if (property === "notify") {
				return (message: string, type: CapturedNotification["type"] = "info") => {
					notifications.push({ message, type });
					return target.notify(message, type);
				};
			}
			const value = Reflect.get(target, property, target);
			return typeof value === "function" ? value.bind(target) : value;
		},
	});
	const commandContext = new Proxy(ctx, {
		get(target, property) {
			if (property === "ui") return ui;
			const value = Reflect.get(target, property, target);
			return typeof value === "function" ? value.bind(target) : value;
		},
	});
	return { ctx: commandContext, notifications };
}

async function invokeCommand(
	pi: ExtensionAPI,
	name: (typeof COMMAND_NAMES)[number],
	args: string,
	ctx: ExtensionContext,
) {
	const captured = await loadCommands(pi);
	if (!captured.commands) {
		capturedPromise = undefined;
		return textResult(`Error: Plannotator bridge unavailable. ${captured.error}`);
	}
	const command: CapturedCommand | undefined = captured.commands.get(name);
	if (!command) {
		return textResult(`Error: Plannotator did not register /${name}.`);
	}
	try {
		const observed = captureNotifications(ctx);
		await command.handler(args, observed.ctx);
		const startupError = observed.notifications.findLast(
			(notification) => notification.type === "error",
		);
		if (startupError) {
			return textResult(`/${name}: ${startupError.message}`, { invoked: true });
		}
		const opened = observed.notifications.findLast((notification) =>
			/\bopened\b/i.test(notification.message),
		);
		if (opened) {
			return textResult(
				`${opened.message} Submitted feedback will arrive as a follow-up message.`,
				{ pending: true },
			);
		}
		return textResult(
			`Invoked /${name}. Plannotator did not report an open browser session; check its notifications for the outcome.`,
			{ invoked: true },
		);
	} catch (err) {
		return textResult(`Error: /${name} failed: ${errorText(err)}`);
	}
}

function reviewArgs(params: {
	prUrl?: string;
	vcsType?: "git" | "gitbutler";
	useLocal?: boolean;
	rawArgs?: string;
}): ArgumentResult {
	if (params.rawArgs?.trim()) return { value: params.rawArgs.trim() };
	const args: string[] = [];
	if (params.prUrl?.trim()) {
		const quoted = quoteArgument(params.prUrl);
		if (!quoted.value) return quoted;
		args.push(quoted.value);
	}
	if (params.vcsType) args.push(`--${params.vcsType}`);
	if (params.useLocal === false) args.push("--no-local");
	if (params.useLocal === true) args.push("--local");
	return { value: args.join(" ") };
}

function annotateArgs(params: {
	target?: string;
	gate?: boolean;
	json?: boolean;
	renderHtml?: boolean;
	renderMarkdown?: boolean;
	noJina?: boolean;
	app?: boolean;
	static?: boolean;
	rawArgs?: string;
}): ArgumentResult {
	if (params.rawArgs?.trim()) return { value: params.rawArgs.trim() };
	if (!params.target?.trim()) {
		return { error: "target or rawArgs is required." };
	}
	const args: string[] = [];
	if (params.gate) args.push("--gate");
	if (params.json) args.push("--json");
	if (params.renderHtml) args.push("--render-html");
	if (params.renderMarkdown) args.push("--markdown");
	if (params.noJina) args.push("--no-jina");
	if (params.app) args.push("--app");
	if (params.static) args.push("--static");
	const quoted = quoteArgument(params.target);
	if (!quoted.value) return quoted;
	args.push(quoted.value);
	return { value: args.join(" ") };
}

function registerReviewTool(pi: ExtensionAPI): void {
	pi.registerTool({
		name: "plannotator_review",
		label: "Plannotator Review",
		description:
			"Invoke Plannotator's real /plannotator-review command. It opens the non-blocking code-review browser for current changes or a PR URL; the UI handles commit/branch/diff selection. " +
			"Submitted feedback arrives asynchronously as a follow-up message with Plannotator's configured prompts.",
		parameters: Type.Object({
			prUrl: Type.Optional(
				Type.String({ description: "Pull request URL to review." }),
			),
			vcsType: Type.Optional(
				Type.Union([Type.Literal("git"), Type.Literal("gitbutler")], {
					description:
						"Force the same VCS provider flag accepted by the slash command.",
				}),
			),
			useLocal: Type.Optional(
				Type.Boolean({ description: "Use local checkout for PR review." }),
			),
			rawArgs: Type.Optional(
				Type.String({
					description:
						"Exact argument string for /plannotator-review. Overrides structured fields.",
				}),
			),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const built = reviewArgs(params as Parameters<typeof reviewArgs>[0]);
			if (built.error) {
				return textResult(`Error: ${built.error}`);
			}
			return invokeCommand(pi, "plannotator-review", built.value, ctx);
		},
	});
}

function registerAnnotateTool(pi: ExtensionAPI): void {
	pi.registerTool({
		name: "plannotator_annotate",
		label: "Plannotator Annotate",
		description:
			"Invoke Plannotator's real /plannotator-annotate command for a file, folder, URL, or live app. It returns after opening the browser; submitted annotations arrive asynchronously as configured follow-up feedback.",
		parameters: Type.Object({
			target: Type.Optional(
				Type.String({
					description: "File, folder, URL, @reference, or live-app target.",
				}),
			),
			gate: Type.Optional(Type.Boolean({ description: "Pass --gate." })),
			json: Type.Optional(Type.Boolean({ description: "Pass --json." })),
			renderHtml: Type.Optional(
				Type.Boolean({ description: "Pass --render-html." }),
			),
			renderMarkdown: Type.Optional(
				Type.Boolean({ description: "Pass --markdown." }),
			),
			noJina: Type.Optional(Type.Boolean({ description: "Pass --no-jina." })),
			app: Type.Optional(Type.Boolean({ description: "Pass --app." })),
			static: Type.Optional(Type.Boolean({ description: "Pass --static." })),
			rawArgs: Type.Optional(
				Type.String({
					description:
						"Exact argument string for /plannotator-annotate. Overrides structured fields and supports future command flags.",
				}),
			),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const built = annotateArgs(params as Parameters<typeof annotateArgs>[0]);
			if (built.error) {
				return textResult(`Error: ${built.error}`);
			}
			return invokeCommand(pi, "plannotator-annotate", built.value, ctx);
		},
	});
}

function registerLastTool(pi: ExtensionAPI): void {
	pi.registerTool({
		name: "plannotator_annotate_last",
		label: "Plannotator Annotate Last",
		description:
			"Invoke Plannotator's real /plannotator-last command for the previous assistant response. It returns after opening the browser; submitted annotations arrive asynchronously as configured follow-up feedback.",
		parameters: Type.Object({
			gate: Type.Optional(Type.Boolean({ description: "Pass --gate." })),
			rawArgs: Type.Optional(
				Type.String({
					description:
						"Exact argument string for /plannotator-last. Overrides gate.",
				}),
			),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const typed = params as { gate?: boolean; rawArgs?: string };
			const args = typed.rawArgs?.trim() || (typed.gate ? "--gate" : "");
			return invokeCommand(pi, "plannotator-last", args, ctx);
		},
	});
}

export function registerPlannotatorTools(pi: ExtensionAPI): void {
	registerReviewTool(pi);
	registerAnnotateTool(pi);
	registerLastTool(pi);
}
