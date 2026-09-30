/**
 * Per-session memory resolution + fork seeding.
 *
 * Durable long-term memory is scoped under `.memory/<sessionId>/` (see `sessionMemoryRoot`) so
 * two sessions in the same project never share consolidator output. The session id is the
 * immutable session-header UUID (survives /name, /resume, /tree) read via
 * `sessionManager.getSessionId()` — never the filename UUID (which can diverge) or the display
 * name (which /name mutates).
 *
 * On a fork/clone/new-with-parent, the short-term ledger travels with the new session, so we
 * seed the long-term tier to match: copy the parent's memory root in once, on first touch.
 * Seeding is idempotent — once the dir exists it is never re-seeded, so resume and /tree never
 * disturb it. The transient `.runs/` IPC directory is excluded.
 */
import { cpSync, existsSync, readFileSync, renameSync, rmSync } from "node:fs";
import { basename, sep } from "node:path";
import { sessionMemoryRoot } from "./paths.js";

type SessionCtx = {
	cwd: string;
	sessionManager: {
		getSessionId: () => string;
		getHeader?: () => { id?: string; cwd?: string; parentSession?: string } | null | undefined;
	};
};

/** Read a session file's header id (first JSONL line). Undefined on any parse/IO failure. */
function readSessionHeaderId(file: string): string | undefined {
	try {
		const firstLine = readFileSync(file, "utf-8").split("\n", 1)[0] ?? "";
		const header = JSON.parse(firstLine) as { type?: string; id?: string } | undefined;
		return typeof header?.id === "string" ? header.id : undefined;
	} catch {
		return undefined;
	}
}

/**
 * Resolve the parent session's memory root for fork/clone seeding, or undefined when there is
 * no parent or the parent kept no memory under this project. The parent is discovered via the
 * durable `parentSession` lineage in this session's header.
 */
function parentMemoryRoot(ctx: SessionCtx): string | undefined {
	const parentFile = ctx.sessionManager.getHeader?.()?.parentSession;
	if (!parentFile) return undefined;
	const parentId = readSessionHeaderId(parentFile);
	if (!parentId) return undefined;
	const root = sessionMemoryRoot(ctx.cwd, parentId);
	return existsSync(root) ? root : undefined;
}

/** True for any path inside a `.runs` directory (transient IPC; never seeded). */
function isRunsPath(p: string): boolean {
	return basename(p) === ".runs" || p.includes(`${sep}.runs${sep}`);
}

/**
 * Resolve this session's `.memory/<sessionId>/` root, seeding it from the parent session on
 * first touch (fork/clone/new-with-parent). Idempotent: once the dir exists it is returned
 * untouched. Returns the absolute root. When there is no parent memory, the root is NOT created
 * here — the first durable write (INDEX/topic/journey) lazily creates it via `atomicWrite`.
 */
export function ensureSessionMemory(ctx: SessionCtx): string {
	const sessionId = ctx.sessionManager.getSessionId();
	const root = sessionMemoryRoot(ctx.cwd, sessionId);
	if (existsSync(root)) return root;

	const parent = parentMemoryRoot(ctx);
	if (parent) {
		// Copy parent memory (minus transient .runs/) via temp+rename so a concurrent reader never
		// observes a half-seeded directory.
		const tmp = `${root}.seed-tmp-${process.pid}-${Date.now()}`;
		try {
			cpSync(parent, tmp, { recursive: true, filter: (src) => !isRunsPath(src) });
			renameSync(tmp, root);
		} catch {
			try {
				rmSync(tmp, { recursive: true, force: true });
			} catch {
				/* best-effort cleanup */
			}
		}
	}
	return root;
}
