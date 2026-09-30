/**
 * Deterministic rendering of the long-term memory map (Phase B), from topic-file front-matter.
 *
 * Two consumers, both model-free and throwaway (regenerated, never edited incrementally — so
 * the projection cannot decay):
 *   - renderIndexFile: the orchestrator-owned INDEX.md on disk, re-rendered after each
 *     consolidation so live `ls`/`grep` truth leads the pushed map.
 *   - renderMemoryMap: the "memory map" section of the compaction injection block, built live
 *     from disk at each compaction and handed to renderSummary().
 */
import type { Topic } from "./paths.js";

function summaryOf(topic: Topic): string {
	const s = (topic.summary ?? "").trim();
	return s.length > 0 ? s : "(no summary)";
}

function titleOf(topic: Topic): string {
	const t = (topic.title ?? "").trim();
	return t.length > 0 ? t : topic.filename;
}

/** The on-disk INDEX.md content. Orchestrator-owned; the consolidator never writes it. */
export function renderIndexFile(topics: Topic[]): string {
	const parts: string[] = ["# Memory index", ""];
	if (topics.length === 0) {
		parts.push("_No topics yet._");
		return `${parts.join("\n")}\n`;
	}
	parts.push("Durable memory topics for this project. Read a file for its full current state.", "");
	for (const topic of topics) {
		const updated = topic.updated ? ` · updated ${topic.updated}` : "";
		parts.push(`## ${titleOf(topic)}`);
		parts.push(`- \`${topic.path}\`${updated}`);
		parts.push(`- ${summaryOf(topic)}`);
		parts.push("");
	}
	return `${parts.join("\n").trimEnd()}\n`;
}

/**
 * The compaction injection block's memory-map section. Returns undefined when there are no
 * topics (renderSummary then omits the section entirely). Each line is `path · summary
 * (updated …)` plus a thin orientation header — enough for the master to know a file exists
 * and decide whether to read it.
 */
export function renderMemoryMap(topics: Topic[]): string | undefined {
	if (topics.length === 0) return undefined;
	const lines: string[] = [
		"## Memory map",
		"Durable long-term notes live in `.memory/`. Read a file when a topic below looks relevant; these summaries are intentionally terse.",
	];
	for (const topic of topics) {
		const updated = topic.updated ? ` (updated ${topic.updated})` : "";
		lines.push(`- \`${topic.path}\` — ${summaryOf(topic)}${updated}`);
	}
	return lines.join("\n");
}
