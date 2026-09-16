import { describe, expect, test } from "bun:test";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import { _test } from "../agent/extensions/notify.ts";

const assistant = (
	text: string,
	stopReason: AssistantMessage["stopReason"] = "stop",
	errorMessage?: string,
): AssistantMessage =>
	({
		role: "assistant",
		content: [{ type: "text", text }],
		stopReason,
		errorMessage,
		timestamp: Date.now(),
	}) as AssistantMessage;

const harness = () => {
	const notifications: Array<{
		title: string;
		message: string;
		urgency?: string;
	}> = [];
	const timers = new Map<number, () => void>();
	let nextTimer = 1;

	const controller = _test.createNotificationController(
		(request) => notifications.push(request),
		{
			delayMs: 3_000,
			setTimer: ((callback: () => void) => {
				const id = nextTimer++;
				timers.set(id, callback);
				return id;
			}) as never,
			clearTimer: ((id: number) => timers.delete(id)) as never,
		},
	);

	return {
		controller,
		notifications,
		pending: () => timers.size,
		flush: () => {
			const callbacks = [...timers.values()];
			timers.clear();
			for (const callback of callbacks) callback();
		},
	};
};

describe("notify lifecycle", () => {
	test("sends one successful completion after settlement", () => {
		const h = harness();
		h.controller.agentStart();
		h.controller.capture(assistant("Changed the gateway. Tests pass."));
		h.controller.settled(true);

		expect(h.pending()).toBe(1);
		expect(h.notifications).toHaveLength(0);
		h.flush();
		expect(h.notifications).toEqual([
			{
				title: "Pi finished",
				message: "Changed the gateway. Tests pass.",
			},
		]);
	});

	test("suppresses a final normalized connection failure", () => {
		const h = harness();
		h.controller.agentStart();
		h.controller.capture(assistant("", "error", "  Connection   error.\n"));
		h.controller.settled(true);

		expect(h.pending()).toBe(0);
		expect(h.notifications).toHaveLength(0);
	});

	test("reports other final failures with useful text", () => {
		const h = harness();
		h.controller.agentStart();
		h.controller.capture(
			assistant("", "error", "Authentication failed: token expired."),
		);
		h.controller.settled(true);
		h.flush();

		expect(h.notifications).toEqual([
			{
				title: "Pi failed",
				message: "Authentication failed: token expired.",
				urgency: "high",
			},
		]);
	});

	test("uses the successful result after an automatic retry", () => {
		const h = harness();
		h.controller.agentStart();
		h.controller.capture(assistant("", "error", "Connection error."));

		h.controller.agentStart();
		h.controller.capture(assistant("Retry succeeded and the files are saved."));
		h.controller.settled(true);
		h.flush();

		expect(h.notifications).toEqual([
			{
				title: "Pi finished",
				message: "Retry succeeded and the files are saved.",
			},
		]);
	});

	test("cancels the only pending notification on input", () => {
		const h = harness();
		h.controller.agentStart();
		h.controller.capture(assistant("Done."));
		h.controller.settled(true);
		expect(h.pending()).toBe(1);

		h.controller.input("next task");
		expect(h.pending()).toBe(0);
		h.flush();
		expect(h.notifications).toHaveLength(0);
	});

	test("suppresses the complete Telegram run regardless of duration", () => {
		const h = harness();
		h.controller.input(`${_test.TELEGRAM_PREFIX}\ncheck status`);
		h.controller.agentStart();
		h.controller.capture(assistant("Status checked."));
		h.controller.uiPromptStart(true, "Choose an option");
		h.controller.settled(true);

		expect(h.pending()).toBe(0);
		expect(h.notifications).toHaveLength(0);

		h.controller.input("local request");
		h.controller.agentStart();
		h.controller.capture(assistant("Local request finished."));
		h.controller.settled(true);
		h.flush();
		expect(h.notifications.at(-1)?.title).toBe("Pi finished");
	});

	test("notifies for a question and avoids a duplicate structured prompt", () => {
		const h = harness();
		h.controller.agentStart();
		h.controller.uiPromptStart(true, "Choose a deployment target");
		expect(h.notifications.at(-1)?.title).toBe("Input needed");

		h.controller.capture(assistant("Which target should I use?"));
		h.controller.settled(true);
		expect(h.pending()).toBe(0);
		expect(h.notifications).toHaveLength(1);
	});
});

describe("notification command", () => {
	test("opts into presence-based Telegram routing", () => {
		expect(
			_test.notificationArgs({
				title: "Pi finished",
				message: "Done.",
			}),
		).toContain("--presence-routing");
	});
});

describe("notification excerpts", () => {
	test("removes Markdown noise, keeps bullets, and truncates at a useful boundary", () => {
		const paragraph =
			"This is a complete explanation of the implementation and why it works. ".repeat(
				12,
			);
		const input = [
			"# Result",
			"---",
			"```ts",
			"const answer = 42;",
			"```",
			"* Kept the existing bridge protocol.",
			"* Added focused lifecycle tests.",
			"",
			paragraph,
			"A trailing sentence that should not be needed.",
		].join("\n");

		const excerpt = _test.notificationExcerpt(input);
		expect(excerpt).not.toContain("```");
		expect(excerpt).not.toContain("---");
		expect(excerpt).toContain("- Kept the existing bridge protocol.");
		expect(excerpt).toContain("const answer = 42;");
		expect(excerpt.length).toBeGreaterThanOrEqual(500);
		expect(excerpt.length).toBeLessThanOrEqual(700);
		expect(excerpt.endsWith("...")).toBe(true);
	});
});
