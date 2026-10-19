import { describe, expect, test } from "bun:test";
import { getMarkdownTheme, initTheme, type Theme } from "@earendil-works/pi-coding-agent";
import { Value } from "typebox/value";
import { PreviewBlockRenderer } from "../agent/extensions/ask-user-question/view/components/preview/preview-block-renderer.ts";
import { MultiSelectView } from "../agent/extensions/ask-user-question/view/components/multi-select-view.ts";
import { OptionSchema, type QuestionData } from "../agent/extensions/ask-user-question/tool/types.ts";

initTheme("dark");

// SAFETY: the card views only call fg and bold on the theme.
const theme = { fg: (_color: string, text: string) => text, bold: (text: string) => text } as Theme;

const question: QuestionData = {
	question: "Which layout?",
	header: "Layout",
	multiSelect: true,
	options: [
		{ label: "Per kind", description: "One dir per kind.", preview: "CARD-ONE: .config/pi/plans" },
		{ label: "Flat", description: "FALLBACK-TWO: one dir for all.", preview: "   " },
	],
};

function block(): PreviewBlockRenderer {
	return new PreviewBlockRenderer({ question, theme, markdownTheme: getMarkdownTheme() });
}

describe("ask_user_question context cards", () => {
	test("every option must carry a non-empty preview", () => {
		expect(Value.Check(OptionSchema, { label: "A", description: "a" })).toBe(false);
		expect(Value.Check(OptionSchema, { label: "A", description: "a", preview: "" })).toBe(false);
		expect(Value.Check(OptionSchema, { label: "A", description: "a", preview: "context" })).toBe(true);
	});

	test("a blank preview falls back to the description, so the card always shows", () => {
		const renderer = block();

		expect(renderer.hasAnyPreview()).toBe(true);
		expect(renderer.renderCard(60, 1).join("\n")).toContain("FALLBACK-TWO");
	});

	test("multi-select shows the focused option's card under the list", () => {
		const view = new MultiSelectView(theme, question, block());
		const other = { active: false, checked: false, inputMode: false, inputBuffer: "", inputCursorOffset: undefined };

		view.setProps({ rows: [{ checked: false, active: true }, { checked: false, active: false }], other, nextActive: false, nextLabel: "Next" });
		const first = view.render(60).join("\n");

		view.setProps({ rows: [{ checked: false, active: false }, { checked: true, active: true }], other, nextActive: false, nextLabel: "Next" });
		const second = view.render(60).join("\n");

		expect(first).toContain("CARD-ONE");
		expect(second).toContain("FALLBACK-TWO");
		expect(second).not.toContain("CARD-ONE");
	});
});
