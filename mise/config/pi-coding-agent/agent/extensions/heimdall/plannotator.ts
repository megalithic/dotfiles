/**
 * heimdall/plannotator.ts - agent tools bridging @plannotator/pi-extension.
 *
 * Plannotator's slash commands (/plannotator-review, /plannotator-annotate,
 * /plannotator-last) are user-only; agents cannot dispatch slash commands.
 * These tools call the same exported browser-session functions directly and
 * block until the user submits a decision in the UI, so their feedback comes
 * back as the tool result — no polling, no watchers.
 *
 * Couples to internal exports of @plannotator/pi-extension (not a documented
 * contract). The import is lazy and guarded: a missing or incompatible
 * plannotator install turns into a clear tool error, never a startup crash.
 * Verified against @plannotator/pi-extension 0.27.9.
 */

import { readFileSync, statSync } from "node:fs";
import { isAbsolute, resolve } from "node:path";
import type {
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { errorText, importPiPackageModule, textResult } from "./lib.ts";

// Mirrors plannotator's MAX_ANNOTATABLE_FILE_BYTES.
const MAX_ANNOTATABLE_FILE_BYTES = 2 * 1024 * 1024;

// Matches BROWSER_SESSION_STOPPED in plannotator's browser-session-error.ts.
const BROWSER_SESSION_STOPPED = "PlannotatorBrowserSessionStopped";

interface AnnotateDecision {
	feedback: string;
	exit?: boolean;
	approved?: boolean;
}

interface ReviewDecision {
	approved: boolean;
	feedback?: string;
	annotations?: unknown[];
	exit?: boolean;
}

interface BrowserDecisionSession<T> {
	url: string;
	waitForDecision: () => Promise<T>;
	stop: () => void;
}

interface ReviewOptions {
	prUrl?: string;
	diffType?: string;
	vcsType?: string;
	useLocal?: boolean;
}

interface PlannotatorBrowser {
	startCodeReviewBrowserSession(
		ctx: ExtensionContext,
		options?: ReviewOptions,
	): Promise<BrowserDecisionSession<ReviewDecision>>;
	startMarkdownAnnotationSession(
		ctx: ExtensionContext,
		filePath: string,
		markdown: string,
		mode: "annotate" | "annotate-folder" | "annotate-last" | "annotate-app",
		folderPath?: string,
	): Promise<BrowserDecisionSession<AnnotateDecision>>;
	startLastMessageAnnotationSession(
		ctx: ExtensionContext,
		lastText: string,
	): Promise<BrowserDecisionSession<AnnotateDecision>>;
	getLastAssistantMessageText(ctx: ExtensionContext): string | null;
	hasReviewBrowserHtml(): boolean;
	hasPlanBrowserHtml(): boolean;
}

let cachedModule: PlannotatorBrowser | undefined;

async function loadPlannotator(): Promise<
	{ module: PlannotatorBrowser; error?: undefined } | { module?: undefined; error: string }
> {
	if (cachedModule) return { module: cachedModule };
	const result = await importPiPackageModule<PlannotatorBrowser>(
		"@plannotator/pi-extension/plannotator-browser.ts",
	);
	if (result.module) cachedModule = result.module;
	return result;
}

function isSessionStopped(err: unknown): boolean {
	return err instanceof Error && err.name === BROWSER_SESSION_STOPPED;
}

/**
 * Open a session, wire tool-call abort to session.stop(), and await the
 * user's decision. A stopped session (abort, port preemption, closed tab)
 * resolves to null instead of throwing.
 */
async function awaitDecision<T>(
	session: BrowserDecisionSession<T>,
	signal: AbortSignal | undefined,
): Promise<T | null> {
	const onAbort = () => session.stop();
	signal?.addEventListener("abort", onAbort, { once: true });
	try {
		return await session.waitForDecision();
	} catch (err) {
		if (isSessionStopped(err)) return null;
		throw err;
	} finally {
		signal?.removeEventListener("abort", onAbort);
	}
}

function annotateResult(decision: AnnotateDecision | null, subject: string) {
	if (decision === null || decision.exit) {
		return textResult(`${subject} annotation session closed without feedback.`, {
			exit: true,
		});
	}
	if (decision.approved) {
		return textResult(
			decision.feedback
				? `Approved with notes:\n\n${decision.feedback}`
				: "Approved (no comments).",
			{ approved: true },
		);
	}
	return textResult(
		decision.feedback ||
			`${subject} annotation session closed without feedback.`,
		{ approved: false },
	);
}

export function registerPlannotatorTools(pi: ExtensionAPI): void {
	pi.registerTool({
		name: "plannotator_review",
		label: "Plannotator Review",
		description:
			"Open Plannotator's interactive code review browser UI for the user and wait for their decision. " +
			"Use when asked to open a review of changes (unstaged/staged/uncommitted work, a commit, a branch, or a PR URL). " +
			"Blocks until the user approves, sends annotations, or closes the session; their feedback is returned as the tool result. " +
			"Defaults to reviewing current uncommitted changes when no options are given.",
		parameters: Type.Object({
			prUrl: Type.Optional(
				Type.String({
					description: "Pull request URL to review instead of local changes.",
				}),
			),
			diffType: Type.Optional(
				Type.String({
					description:
						"What to diff: 'uncommitted' (default), 'staged', 'unstaged', 'last-commit', 'branch', 'since-base', 'merge-base', 'all', or 'commit:<sha>'.",
				}),
			),
			vcsType: Type.Optional(
				Type.String({
					description: "Force a VCS provider: 'auto', 'git', 'gitbutler', 'jj', or 'p4'.",
				}),
			),
			useLocal: Type.Optional(
				Type.Boolean({
					description: "For PR reviews: use the local checkout instead of fetching.",
				}),
			),
		}),
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const loaded = await loadPlannotator();
			if (!loaded.module) {
				return textResult(`Error: plannotator bridge unavailable. ${loaded.error}`);
			}
			const mod = loaded.module;
			if (!ctx.hasUI) {
				return textResult(
					"Error: Plannotator code review requires an interactive session (no UI available).",
				);
			}
			if (!mod.hasReviewBrowserHtml()) {
				return textResult("Error: Plannotator code review UI assets are not available.");
			}
			try {
				const { prUrl, diffType, vcsType, useLocal } = params as ReviewOptions;
				const session = await mod.startCodeReviewBrowserSession(ctx, {
					prUrl,
					diffType,
					vcsType,
					useLocal,
				});
				ctx.ui.notify(`Code review opened: ${session.url}`, "info");
				const decision = await awaitDecision(session, signal);
				if (decision === null || decision.exit) {
					return textResult("Code review session closed without a decision.", {
						exit: true,
					});
				}
				if (decision.approved) {
					return textResult(
						decision.feedback
							? `Review approved with notes:\n\n${decision.feedback}`
							: "Review approved (no comments).",
						{ approved: true },
					);
				}
				return textResult(
					decision.feedback || "Review closed without feedback.",
					{ approved: false, annotationCount: decision.annotations?.length ?? 0 },
				);
			} catch (err) {
				return textResult(`Error: failed to run code review: ${errorText(err)}`);
			}
		},
	});

	pi.registerTool({
		name: "plannotator_annotate",
		label: "Plannotator Annotate",
		description:
			"Open a markdown/text file or a folder in Plannotator's annotation browser UI and wait for the user's inline comments. " +
			"Use when asked to send a document (research notes, plan, report) to plannotator for feedback. " +
			"Blocks until the user submits; their annotations come back as the tool result.",
		parameters: Type.Object({
			path: Type.String({
				description:
					"File or folder to annotate. Relative paths resolve against the working directory.",
			}),
		}),
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const loaded = await loadPlannotator();
			if (!loaded.module) {
				return textResult(`Error: plannotator bridge unavailable. ${loaded.error}`);
			}
			const mod = loaded.module;
			if (!ctx.hasUI) {
				return textResult(
					"Error: Plannotator annotation requires an interactive session (no UI available).",
				);
			}
			if (!mod.hasPlanBrowserHtml()) {
				return textResult("Error: Plannotator annotation UI assets are not available.");
			}

			const inputPath = (params as { path: string }).path?.trim();
			if (!inputPath) {
				return textResult("Error: path is required.");
			}
			const absolutePath = isAbsolute(inputPath)
				? inputPath
				: resolve(ctx.cwd, inputPath);

			let stats: ReturnType<typeof statSync>;
			try {
				stats = statSync(absolutePath);
			} catch {
				return textResult(`Error: ${absolutePath} does not exist.`);
			}

			try {
				let session: BrowserDecisionSession<AnnotateDecision>;
				if (stats.isDirectory()) {
					session = await mod.startMarkdownAnnotationSession(
						ctx,
						absolutePath,
						"",
						"annotate-folder",
						absolutePath,
					);
				} else {
					if (stats.size > MAX_ANNOTATABLE_FILE_BYTES) {
						return textResult(
							`Error: file too large to annotate (max 2MB): ${absolutePath}`,
						);
					}
					const markdown = readFileSync(absolutePath, "utf-8");
					session = await mod.startMarkdownAnnotationSession(
						ctx,
						absolutePath,
						markdown,
						"annotate",
					);
				}
				ctx.ui.notify(`Annotation opened: ${session.url}`, "info");
				const decision = await awaitDecision(session, signal);
				return annotateResult(decision, absolutePath);
			} catch (err) {
				return textResult(`Error: failed to open annotation UI: ${errorText(err)}`);
			}
		},
	});

	pi.registerTool({
		name: "plannotator_annotate_last",
		label: "Plannotator Annotate Last",
		description:
			"Open the last assistant message in Plannotator's annotation browser UI and wait for the user's inline comments. " +
			"Use when the user wants to annotate or give structured feedback on your previous response. " +
			"Blocks until the user submits; their annotations come back as the tool result.",
		parameters: Type.Object({}),
		async execute(_toolCallId, _params, signal, _onUpdate, ctx) {
			const loaded = await loadPlannotator();
			if (!loaded.module) {
				return textResult(`Error: plannotator bridge unavailable. ${loaded.error}`);
			}
			const mod = loaded.module;
			if (!ctx.hasUI) {
				return textResult(
					"Error: Plannotator annotation requires an interactive session (no UI available).",
				);
			}
			if (!mod.hasPlanBrowserHtml()) {
				return textResult("Error: Plannotator annotation UI assets are not available.");
			}
			const lastText = mod.getLastAssistantMessageText(ctx);
			if (!lastText) {
				return textResult("Error: no assistant message found in this session.");
			}
			try {
				const session = await mod.startLastMessageAnnotationSession(ctx, lastText);
				ctx.ui.notify(`Last-message annotation opened: ${session.url}`, "info");
				const decision = await awaitDecision(session, signal);
				return annotateResult(decision, "Last message");
			} catch (err) {
				return textResult(`Error: failed to open annotation UI: ${errorText(err)}`);
			}
		},
	});
}
