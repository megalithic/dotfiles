import { describe, expect, test } from "bun:test";
import { _test } from "../agent/extensions/bridge.ts";

const assistant = (text: string, stopReason = "stop") => ({
	role: "assistant",
	content: [{ type: "text", text }],
	stopReason,
});

describe("bridge activity status", () => {
	test("marks completed prose as done", () => {
		_test.captureAssistantResult(assistant("All checks pass."));
		expect(_test.settledActivityState()).toBe("done");
	});

	test("marks final prose questions as input needed", () => {
		_test.captureAssistantResult(assistant("Which target should I use? **"));
		expect(_test.settledActivityState()).toBe("input_needed");
	});

	test("marks final provider failures as errors", () => {
		_test.captureAssistantResult(assistant("", "error"));
		expect(_test.settledActivityState()).toBe("error");
	});

	test("restores the prior state after a standalone prompt", () => {
		_test.updateActivityState("done", null);
		_test.beginPrompt(null);
		expect(_test.activityState()).toBe("input_needed");
		_test.endPrompt(null);
		expect(_test.activityState()).toBe("done");
	});
});
