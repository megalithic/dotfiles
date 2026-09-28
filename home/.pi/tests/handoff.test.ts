import { describe, expect, test } from "bun:test";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import { initTheme, type ExtensionAPI, type ExtensionCommandContext, type ModelRegistry, type Theme } from "@earendil-works/pi-coding-agent";
import { getKeybindings, type Component, type TUI } from "@earendil-works/pi-tui";
import handoff from "../agent/extensions/handoff.ts";

initTheme("dark");

type ThinkingLevel = ExtensionCommandContext["thinkingLevel"];

type Request = Parameters<ModelRegistry["streamSimple"]>;

function harness(stopReason: AssistantMessage["stopReason"] = "aborted") {
	const calls: Request[] = [];
	const notifications: string[] = [];
	let thinkingLevel: ThinkingLevel = "low";

	let handler: (args: string, ctx: ExtensionCommandContext) => Promise<void> = async () => {
		throw new Error("Handoff command was not registered");
	};

	const pi: Pick<ExtensionAPI, "registerCommand"> = {
		registerCommand(name, command) {
			expect(name).toBe("handoff");
			handler = command.handler;
		},
	};

	// SAFETY: the extension factory only registers its command on this API.
	handoff(pi as ExtensionAPI);

	const response: AssistantMessage = {
		role: "assistant",
		content: [],
		api: "openai-responses",
		provider: "test-provider",
		model: "test-model",
		usage: {
			input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0,
			cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
		},
		stopReason,
		errorMessage: stopReason === "error" ? "Test provider failed" : undefined,
		timestamp: 0,
	};

	// SAFETY: this command-only context supplies the methods handoff uses before
	// a cancelled/failed generation; newSession fails if generation proceeds.
	const ctx = {
		hasUI: true,
		mode: "tui",
		model: { id: "test-model", provider: "test-provider" },
		get thinkingLevel() { return thinkingLevel; },
		sessionManager: {
			getBranch: () => [{ type: "message", message: { role: "user", content: "Existing context", timestamp: 0 } }],
			getSessionFile: () => undefined,
			getHeader: () => undefined,
		},
		modelRegistry: {
			streamSimple(...args: Request) {
				calls.push(args);

				return { result: async () => response };
			},
		},
		ui: {
			notify: (message: string) => notifications.push(message),
			custom: async <T>(factory: (tui: TUI, theme: Theme, keybindings: ReturnType<typeof getKeybindings>, done: (result: T) => void) => (Component & { dispose?(): void }) | Promise<Component & { dispose?(): void }>) => {
				let component: Awaited<ReturnType<typeof factory>> | undefined;

				try {
					return await new Promise<T>((resolve) => {
						// SAFETY: BorderedLoader only requests renders; no terminal is started.
						const tui = { requestRender() {} } as TUI;
						// SAFETY: the loader only uses the theme's fg method in this test.
						const theme = { fg: (_color: string, text: string) => text } as Parameters<typeof factory>[1];
						const built = factory(tui, theme, getKeybindings(), resolve);

						Promise.resolve(built).then((value) => { component = value; });
					});
				} finally {
					component?.dispose?.();
				}
			},
		},
		newSession: async () => { throw new Error("Must not replace the session after failed generation"); },
	} as ExtensionCommandContext;

	return {
		calls,
		notifications,
		ctx,
		setThinking: (level: ThinkingLevel) => { thinkingLevel = level; },
		run: () => handler("Continue the task", ctx),
	};
}

describe("handoff thinking level", () => {
	test.each<ThinkingLevel>(["off", "minimal", "low", "medium", "high", "xhigh", "max"])("passes current %s reasoning through the model registry", async (level) => {
		const h = harness();
		h.setThinking(level);

		await h.run();

		expect(h.calls).toHaveLength(1);
		const [model, context, options] = h.calls[0];

		expect(model).toBe(h.ctx.model);
		expect(options?.reasoning).toBe(level === "off" ? undefined : level);
		expect(options?.signal).toBeInstanceOf(AbortSignal);
		expect(context.messages[0].content).toEqual([
			{ type: "text", text: expect.stringContaining("Existing context") },
		]);
		expect(h.notifications).toEqual(["Cancelled"]);
	});

	test("reads the latest setting again on each invocation", async () => {
		const h = harness();
		await h.run();
		h.setThinking("max");
		await h.run();
		h.setThinking("off");
		await h.run();

		expect(h.calls.map((call) => call[2]?.reasoning)).toEqual(["low", "max", undefined]);
	});

	test("reports registry failures without creating a session", async () => {
		const h = harness("error");
		h.setThinking("high");

		await h.run();

		expect(h.notifications).toEqual(["Handoff failed: Test provider failed"]);
	});
});
