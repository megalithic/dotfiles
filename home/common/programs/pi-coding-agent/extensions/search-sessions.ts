/**
 * Session history search extension: BM25 ranking across past pi conversations.
 * Reads a pre-built index from ~/.cache/pi-session-index.json.
 */

import { Type } from "@sinclair/typebox";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

// ── BM25 engine ──────────────────────────────────────────────────────────────

const K1 = 1.2;
const B = 0.75;

interface IndexEntry {
  date: string;
  project: string;
  title: string;
  content: string;
  path: string;
}

interface IndexMeta {
  df: Map<string, number>;
  avgTitleLen: number;
  avgContentLen: number;
}

interface Index {
  version: number;
  built: string;
  entries: IndexEntry[];
}

function tokenize(text: string): string[] {
  return text
    .toLowerCase()
    .split(/\W+/)
    .filter((t) => t.length > 1);
}

function computeMeta(entries: IndexEntry[]): IndexMeta {
  const df = new Map<string, number>();
  let totalTitleLen = 0;
  let totalContentLen = 0;

  for (const entry of entries) {
    const titleTokens = new Set(tokenize(entry.title));
    const contentTokens = new Set(tokenize(entry.content));
    totalTitleLen += titleTokens.size || 1;
    totalContentLen += contentTokens.size || 1;
    for (const t of titleTokens) df.set(t, (df.get(t) || 0) + 1);
    for (const t of contentTokens) df.set(t, (df.get(t) || 0) + 1);
  }

  return {
    df,
    avgTitleLen: totalTitleLen / entries.length,
    avgContentLen: totalContentLen / entries.length,
  };
}

function bm25Score(
  queryTerms: string[],
  entry: IndexEntry,
  df: Map<string, number>,
  N: number,
  avgTitleLen: number,
  avgContentLen: number,
): number {
  const titleTokens = tokenize(entry.title);
  const contentTokens = tokenize(entry.content);
  const titleLen = titleTokens.length || 1;
  const contentLen = contentTokens.length || 1;

  // Build term frequency maps
  const titleTF = new Map<string, number>();
  for (const t of titleTokens) titleTF.set(t, (titleTF.get(t) || 0) + 1);
  const contentTF = new Map<string, number>();
  for (const t of contentTokens) contentTF.set(t, (contentTF.get(t) || 0) + 1);

  let totalScore = 0;

  for (const term of queryTerms) {
    const termDF = df.get(term) || 0;
    if (termDF === 0) continue;
    const idf = Math.log((N - termDF + 0.5) / (termDF + 0.5));

    // Title score
    const ttf = titleTF.get(term) || 0;
    const titleScore =
      (ttf * (K1 + 1)) / (ttf + K1 * (1 - B + (B * titleLen) / avgTitleLen));

    // Content score
    const ctf = contentTF.get(term) || 0;
    const contentScore =
      (ctf * (K1 + 1)) /
      (ctf + K1 * (1 - B + (B * contentLen) / avgContentLen));

    totalScore += idf * (titleScore * 3.0 + contentScore * 1.0);
  }

  return totalScore;
}

// ── Index cache ──────────────────────────────────────────────────────────────

const INDEX_PATH = join(homedir(), ".cache", "pi-session-index.json");
let cachedIndex: Index | null = null;
let cachedMeta: IndexMeta | null = null;

async function loadIndex(): Promise<{ index: Index; meta: IndexMeta }> {
  if (cachedIndex && cachedMeta)
    return { index: cachedIndex, meta: cachedMeta };
  try {
    const raw = await readFile(INDEX_PATH, "utf-8");
    cachedIndex = JSON.parse(raw) as Index;
    cachedMeta = computeMeta(cachedIndex.entries);
    return { index: cachedIndex, meta: cachedMeta };
  } catch {
    throw new Error(
      "Session index not found. Run build-session-index manually or wait for the launchd timer. " +
        "or wait for the launchd timer to build it.",
    );
  }
}

// ── Extension ────────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "search_sessions",
    label: "Search session history",
    description:
      "Search past pi conversations using BM25 ranking. Searches user messages, assistant text, and compaction summaries.",
    promptSnippet: "Search past pi conversations with search_sessions.",
    promptGuidelines: [
      "When the user references past conversations ('we discussed X', 'remember when'), use search_sessions.",
      "Use read_session to get the full conversation for a result path.",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Search terms (space-separated)" }),
      project: Type.Optional(
        Type.String({
          description: "Filter to project name substring",
        }),
      ),
      days: Type.Optional(
        Type.Number({
          description: "Only sessions from last N days",
        }),
      ),
    }),

    async execute(_id, params) {
      const { index, meta } = await loadIndex();
      const entries = index.entries;
      const N = entries.length;
      if (N === 0) {
        return {
          content: [{ type: "text", text: "Session index is empty." }],
        };
      }

      const queryTerms = tokenize(params.query);
      if (queryTerms.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: "Query too short. Use words longer than 1 character.",
            },
          ],
        };
      }

      // Apply filters and score
      const now = Date.now();
      const dayMs = 86400000;

      let candidates = entries;
      if (params.project) {
        const projLower = params.project.toLowerCase();
        candidates = candidates.filter((e) =>
          e.project.toLowerCase().includes(projLower),
        );
      }
      if (params.days) {
        const cutoff = new Date(now - params.days * dayMs)
          .toISOString()
          .slice(0, 10);
        candidates = candidates.filter((e) => e.date >= cutoff);
      }

      // Score and rank using precomputed meta
      const scored = candidates
        .map((entry) => ({
          entry,
          score: bm25Score(
            queryTerms,
            entry,
            meta.df,
            N,
            meta.avgTitleLen,
            meta.avgContentLen,
          ),
        }))
        .filter((r) => r.score > 0)
        .sort((a, b) => b.score - a.score)
        .slice(0, 10);

      if (scored.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: `No matching sessions found for "${params.query}".`,
            },
          ],
        };
      }

      const text = scored
        .map((r, i) => {
          const e = r.entry;
          const title =
            e.title.length > 100 ? e.title.slice(0, 100) + "..." : e.title;
          return [
            `### ${i + 1}. ${title}`,
            `Date: ${e.date} | Project: ${e.project} | Score: ${r.score.toFixed(2)}`,
            `Path: ${e.path}`,
          ].join("\n");
        })
        .join("\n\n");

      return { content: [{ type: "text", text }] };
    },
  });

  pi.registerTool({
    name: "read_session",
    label: "Read session file",
    description:
      "Read a past pi conversation from a session file path. Returns condensed user/assistant message pairs.",
    promptSnippet:
      "read_session(path) — read a full conversation from session history",
    parameters: Type.Object({
      path: Type.String({
        description: "Session file path from search results",
      }),
      max_messages: Type.Optional(
        Type.Number({
          description: "Max message pairs to return (default 20)",
          default: 20,
        }),
      ),
    }),

    async execute(_id, params) {
      const maxMessages = params.max_messages ?? 20;
      const truncateAt = Math.min(2000, Math.floor(10000 / maxMessages));

      let raw: string;
      try {
        raw = await readFile(params.path, "utf-8");
      } catch {
        return {
          content: [
            {
              type: "text",
              text: `Cannot read session file: ${params.path}`,
            },
          ],
        };
      }

      const lines = raw.trim().split("\n");
      const messages: { role: string; text: string }[] = [];

      for (const line of lines) {
        try {
          const obj = JSON.parse(line);
          if (obj.type === "message" && obj.message) {
            const { role, content } = obj.message;
            if (role !== "user" && role !== "assistant") continue;
            if (!Array.isArray(content)) continue;

            const texts = content
              .filter(
                (c: { type: string }) =>
                  c.type === "text" &&
                  !(c as { text?: string }).text?.startsWith("<thinking>"),
              )
              .map((c: { text: string }) => c.text)
              .filter((t: string) => t && t.trim().length > 0);

            if (texts.length > 0) {
              for (const text of texts) {
                messages.push({ role, text });
              }
            }
          }
        } catch {
          // skip malformed lines
        }
      }

      // Truncate to max message pairs (2 messages = 1 pair)
      const limited = messages.slice(0, maxMessages * 2);

      const formatted = limited
        .map((m) => {
          const label = m.role === "user" ? "**User**" : "**Assistant**";
          const text =
            m.text.length > truncateAt
              ? m.text.slice(0, truncateAt) + "\n... (truncated)"
              : m.text;
          return `${label}: ${text}`;
        })
        .join("\n\n---\n\n");

      const header = `Session: ${params.path}\nMessages: ${limited.length}/${messages.length}\n`;

      return {
        content: [{ type: "text", text: header + "\n" + formatted }],
      };
    },
  });
}
