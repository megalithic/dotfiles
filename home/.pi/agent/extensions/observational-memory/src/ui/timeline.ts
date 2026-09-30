import type { Config } from "../config.js";
import {
	entryIndexById,
	foldLedger,
	isObservationsRecordedEntry,
	rawTokensAfterIndex,
	rawTokensSinceObservationCoverage,
	type Entry,
} from "../ledger/index.js";

/** Glyphs for the timeline strip. */
const GLYPH = {
	consolidated: "▓", // observations promoted to .memory (long-term)
	partial: "▚", // chunk straddling the pool-target boundary (some obs promoted)
	pool: "▒", // observed, still in the short-term buffer
	raw: "░", // raw history not yet distilled into observations
	cut: "┊", // compaction cutoff (verbatim tail began here)
	tip: "▶", // live branch tip
} as const;

/** A committed observation chunk, in branch order. */
type Chunk = { coversUpToIndex: number; timestamps: string[] };

function fmtK(tokens: number): string {
	if (tokens < 1000) return `${tokens}`;
	return `${(tokens / 1000).toFixed(1)}k`;
}

function collectChunks(branch: Entry[]): Chunk[] {
	const indexById = entryIndexById(branch);
	const chunks: Chunk[] = [];
	for (const entry of branch) {
		if (!isObservationsRecordedEntry(entry)) continue;
		const coversUpToIndex = indexById.get(entry.data.coversUpToId);
		if (coversUpToIndex === undefined) continue;
		chunks.push({ coversUpToIndex, timestamps: entry.data.observations.map((o) => o.timestamp) });
	}
	return chunks;
}

/** Branch indices of every compaction entry's `firstKeptEntryId` (the verbatim-tail cutoffs). */
function compactionCutIndices(branch: Entry[]): number[] {
	const indexById = entryIndexById(branch);
	const cuts: number[] = [];
	for (const entry of branch) {
		if (entry.type !== "compaction") continue;
		const idx = entry.firstKeptEntryId ? indexById.get(entry.firstKeptEntryId) : undefined;
		if (idx !== undefined) cuts.push(idx);
	}
	return cuts;
}

function chunkGlyph(chunk: Chunk, dropped: Set<string>): string {
	let droppedCount = 0;
	for (const ts of chunk.timestamps) if (dropped.has(ts)) droppedCount++;
	if (droppedCount === 0) return GLYPH.pool;
	if (droppedCount === chunk.timestamps.length) return GLYPH.consolidated;
	return GLYPH.partial;
}

function wrap(cells: string[], width: number): string {
	if (cells.length === 0) return "";
	const rows: string[] = [];
	for (let i = 0; i < cells.length; i += width) rows.push(cells.slice(i, i + width).join(""));
	return rows.join("\n");
}

/**
 * Render the full session as a horizontal strip, one cell per ~`chunkTokens` of raw history:
 * the tiered pipeline reads left→right as consolidated (`.memory`) → pool → raw, with
 * compaction cutoffs overlaid and the live tip at the end. The live next-observer/pool token
 * gauges live in the footer status, not here.
 *
 * Scale is *raw history* tokens (physical session), not live-context tokens. Full history is
 * rendered and wrapped across as many rows as needed.
 */
export function renderTimeline(branch: Entry[], config: Config, width = 60): string {
	const folded = foldLedger(branch);
	const dropped = folded.droppedObservationTimestamps;
	const chunks = collectChunks(branch);

	// Base cells: one per chunk, then the raw (unobserved) tail.
	const cells: string[] = chunks.map((chunk) => chunkGlyph(chunk, dropped));
	const tailTokens = rawTokensSinceObservationCoverage(branch);
	const tailCells = tailTokens > 0 ? Math.ceil(tailTokens / config.chunkTokens) : 0;
	for (let i = 0; i < tailCells; i++) cells.push(GLYPH.raw);

	// Overlay compaction cuts. A cut maps to the number of chunk cells whose boundary precedes
	// it (cutoffs are snapped to chunk boundaries, so this is exact in the common case); cuts in
	// the raw tail are clamped to the pool/raw seam. Insert right-to-left to keep positions valid.
	const cutPositions = compactionCutIndices(branch)
		.map((cutIdx) => {
			let pos = 0;
			for (const chunk of chunks) if (chunk.coversUpToIndex < cutIdx) pos++;
			return Math.min(pos, cells.length);
		})
		.sort((a, b) => b - a);
	for (const pos of cutPositions) cells.splice(pos, 0, GLYPH.cut);

	const consolidatedChunks = chunks.filter((c) => chunkGlyph(c, dropped) === GLYPH.consolidated).length;
	const poolChunks = chunks.filter((c) => chunkGlyph(c, dropped) === GLYPH.pool).length;
	const rawTotal = rawTokensAfterIndex(branch, -1);
	const compactions = cutPositions.length;

	const strip = cells.length > 0 ? `${wrap(cells, width)}${GLYPH.tip}` : "(timeline empty)";

	return [
		`om timeline · 1 cell ≈ ${fmtK(config.chunkTokens)} tok · ${fmtK(rawTotal)} raw · ${compactions} compaction${compactions === 1 ? "" : "s"}`,
		strip,
		``,
		`  ${GLYPH.consolidated} .memory (${consolidatedChunks})   ${GLYPH.pool} pool (${poolChunks})   ${GLYPH.raw} raw   ${GLYPH.cut} compaction cut   ${GLYPH.tip} tip`,
	].join("\n");
}
