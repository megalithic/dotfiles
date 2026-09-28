import { execFileSync, spawn } from "node:child_process";
import path from "node:path";
import type { AgentMessage } from "@earendil-works/pi-agent-core";
import type { AssistantMessage, TextContent } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const NTFY_PATH = path.join(process.env.HOME || "", "bin", "ntfy");
const TELEGRAM_PREFIX = "📱 **Telegram message:**";
const NOTIFY_DELAY_MS = 3_000;
const CONNECTION_ERROR = "Connection error.";
const EMPTY_RESPONSE = "Pi is waiting for your next instruction.";

let tmuxSessionName: string | null = null;

const getTmuxSessionName = (): string | null => {
	if (tmuxSessionName !== null) return tmuxSessionName || null;
	if (!process.env.TMUX) {
		tmuxSessionName = "";
		return null;
	}

	try {
		const args = ["display-message", "-p"];
		if (process.env.TMUX_PANE) args.push("-t", process.env.TMUX_PANE);
		args.push("#{session_name}");
		tmuxSessionName = execFileSync("tmux", args, {
			encoding: "utf-8",
			timeout: 1_000,
			stdio: ["ignore", "pipe", "ignore"],
		}).trim();
	} catch {
		tmuxSessionName = "";
	}

	return tmuxSessionName || null;
};

const getSource = (): string => {
	const session = getTmuxSessionName();
	return session ? `${session} pi` : "pi";
};

const isAssistantMessage = (
	message: AgentMessage,
): message is AssistantMessage =>
	message.role === "assistant" && Array.isArray(message.content);

const assistantText = (message: AssistantMessage): string =>
	message.content
		.filter((block): block is TextContent => block.type === "text")
		.map((block) => block.text)
		.join("\n")
		.trim();

const cleanMarkdown = (text: string): string => {
	const lines = text.replace(/\r\n?/g, "\n").split("\n");
	const cleaned: string[] = [];
	let pendingBlank = false;

	for (const rawLine of lines) {
		let line = rawLine.trim();
		if (/^\s*```/.test(line) || /^\s*~~~/.test(line)) continue;
		if (/^(?:[-*_]\s*){3,}$/.test(line)) continue;

		line = line
			.replace(/^#{1,6}\s+/, "")
			.replace(/^>\s?/, "")
			.replace(/!\[([^\]]*)\]\([^)]*\)/g, "$1")
			.replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
			.replace(/\*\*|__|~~|`/g, "")
			.replace(/\s+/g, " ")
			.trim();

		if (!line || /^[-*+]+$/.test(line)) {
			pendingBlank = cleaned.length > 0;
			continue;
		}

		if (pendingBlank && cleaned.at(-1) !== "") cleaned.push("");
		pendingBlank = false;
		cleaned.push(line.replace(/^\*\s+/, "- ").replace(/^\+\s+/, "- "));
	}

	return cleaned.join("\n").trim();
};

const lastBoundary = (
	text: string,
	minimum: number,
	maximum: number,
): number | null => {
	let boundary: number | null = null;
	let index = text.indexOf("\n\n", minimum);
	while (index !== -1 && index <= maximum) {
		boundary = index;
		index = text.indexOf("\n\n", index + 2);
	}
	if (boundary !== null) return boundary;

	const sentence = /[.!?]["')\]]?\s+/g;
	for (const match of text.matchAll(sentence)) {
		const end = (match.index ?? 0) + match[0].trimEnd().length;
		if (end >= minimum && end <= maximum) boundary = end;
	}
	if (boundary !== null) return boundary;

	index = text.lastIndexOf("\n", maximum);
	if (index >= minimum) return index;
	index = text.lastIndexOf(" ", maximum);
	return index >= minimum ? index : null;
};

const notificationExcerpt = (text: string, maxLength = 700): string => {
	const cleaned = cleanMarkdown(text);
	if (!cleaned) return EMPTY_RESPONSE;
	if (cleaned.length <= maxLength) return cleaned;

	const suffix = "...";
	const limit = maxLength - suffix.length;
	const minimum = Math.min(500, Math.floor(limit * 0.7));
	const boundary = lastBoundary(cleaned, minimum, limit) ?? limit;
	return `${cleaned.slice(0, boundary).trimEnd()}${suffix}`;
};

const normalizeErrorMessage = (message: string | undefined): string =>
	(message || "").replace(/\s+/g, " ").trim();

const asksQuestion = (text: string): boolean =>
	/\?[\s*_`"')\]]*$/.test(text.trimEnd());

type NotificationRequest = {
	title: "Pi failed" | "Input needed" | "Pi finished";
	message: string;
	urgency?: "normal" | "high";
};

type TimerHandle = ReturnType<typeof setTimeout>;
type TimerPurpose = "prompt" | "settled";

type ControllerOptions = {
	delayMs?: number;
	setTimer?: (callback: () => void, delayMs: number) => TimerHandle;
	clearTimer?: (handle: TimerHandle) => void;
};

const notificationForAssistant = (
	message: AssistantMessage,
): NotificationRequest | null => {
	const text = assistantText(message);
	if (message.stopReason === "error") {
		const error = normalizeErrorMessage(message.errorMessage);
		if (error === CONNECTION_ERROR) return null;
		return {
			title: "Pi failed",
			message: notificationExcerpt(
				error || text || "Pi failed without an error message.",
			),
			urgency: "high",
		};
	}
	if (message.stopReason === "aborted") return null;

	return {
		title: asksQuestion(text) ? "Input needed" : "Pi finished",
		message: notificationExcerpt(text),
	};
};

const createNotificationController = (
	emit: (request: NotificationRequest) => void,
	options: ControllerOptions = {},
) => {
	const delayMs = options.delayMs ?? NOTIFY_DELAY_MS;
	const setTimer = options.setTimer ?? setTimeout;
	const clearTimer = options.clearTimer ?? clearTimeout;

	let latestAssistant: AssistantMessage | null = null;
	let telegramRun = false;
	let pendingTimer: TimerHandle | null = null;
	let pendingPurpose: TimerPurpose | null = null;
	let promptNotificationSent = false;

	const cancelPending = (purpose?: TimerPurpose): void => {
		if (pendingTimer === null || (purpose && pendingPurpose !== purpose))
			return;
		clearTimer(pendingTimer);
		pendingTimer = null;
		pendingPurpose = null;
	};

	const schedule = (
		request: NotificationRequest,
		purpose: TimerPurpose,
		afterSend?: () => void,
	): void => {
		cancelPending();
		pendingPurpose = purpose;
		pendingTimer = setTimer(() => {
			pendingTimer = null;
			pendingPurpose = null;
			emit(request);
			afterSend?.();
		}, delayMs);
	};

	const capture = (message: AgentMessage): void => {
		if (isAssistantMessage(message)) latestAssistant = message;
	};

	return {
		capture,
		captureRun(messages: AgentMessage[]): void {
			for (let i = messages.length - 1; i >= 0; i--) {
				if (isAssistantMessage(messages[i])) {
					latestAssistant = messages[i];
					return;
				}
			}
		},
		input(text: string): void {
			cancelPending();
			telegramRun = text.startsWith(TELEGRAM_PREFIX);
		},
		agentStart(): void {
			cancelPending();
			latestAssistant = null;
			promptNotificationSent = false;
		},
		uiPromptStart(hasUI: boolean, title?: string): void {
			if (!hasUI || telegramRun) return;
			cancelPending();
			emit({
				title: "Input needed",
				message: notificationExcerpt(
					title || "Pi is waiting for your response.",
				),
			});
			promptNotificationSent = true;
		},
		uiPromptEnd(): void {
			cancelPending("prompt");
		},
		settled(hasUI: boolean): void {
			cancelPending();
			const suppress = telegramRun;
			telegramRun = false;
			if (!hasUI || !latestAssistant || suppress) return;

			const request = notificationForAssistant(latestAssistant);
			if (!request) return;
			if (request.title === "Input needed" && promptNotificationSent) return;
			schedule(request, "settled");
		},
		cancelPending,
		shutdown(): void {
			cancelPending();
			latestAssistant = null;
			telegramRun = false;
		},
	};
};

const notificationArgs = (request: NotificationRequest): string[] => {
	const args = [
		"send",
		"-t",
		request.title,
		"-m",
		request.message,
		"-s",
		getSource(),
		"--presence-routing",
	];
	if (request.urgency) args.push("-u", request.urgency);
	return args;
};

const notify = (request: NotificationRequest): void => {
	const args = notificationArgs(request);

	try {
		const child = spawn(NTFY_PATH, args, { stdio: "ignore", detached: true });
		child.once("error", () => undefined);
		child.unref();
	} catch {
		// Notifications are best-effort and must never interrupt Pi.
	}
};

export const _test = {
	CONNECTION_ERROR,
	TELEGRAM_PREFIX,
	assistantText,
	asksQuestion,
	cleanMarkdown,
	createNotificationController,
	normalizeErrorMessage,
	notificationArgs,
	notificationExcerpt,
	notificationForAssistant,
};

export default function (pi: ExtensionAPI): void {
	const controller = createNotificationController(notify);
	let unsubscribeTerminalInput: (() => void) | null = null;

	pi.on("session_start", (_event, ctx) => {
		unsubscribeTerminalInput?.();
		unsubscribeTerminalInput =
			ctx.mode === "tui"
				? ctx.ui.onTerminalInput(() => {
						controller.cancelPending();
						return undefined;
					})
				: null;
	});

	pi.on("input", (event) => {
		controller.input(event.text);
	});

	pi.on("agent_start", () => {
		controller.agentStart();
	});

	pi.on("message_end", (event) => {
		controller.capture(event.message);
	});

	pi.on("agent_end", (event) => {
		controller.captureRun(event.messages);
	});

	pi.on("ui_prompt_start", (event, ctx) => {
		controller.uiPromptStart(ctx.hasUI, event.title);
	});

	pi.on("ui_prompt_end", () => {
		controller.uiPromptEnd();
	});

	pi.on("agent_settled", (_event, ctx) => {
		controller.settled(ctx.hasUI);
	});

	pi.on("session_shutdown", () => {
		unsubscribeTerminalInput?.();
		unsubscribeTerminalInput = null;
		controller.shutdown();
	});
}
