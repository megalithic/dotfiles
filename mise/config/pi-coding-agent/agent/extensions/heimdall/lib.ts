/**
 * heimdall/lib.ts - shared glue for heimdall adapters.
 *
 * Heimdall bridges other pi extensions' exported functions into agent-callable
 * tools (pi upstream intentionally blocks agents from dispatching slash
 * commands; see .tickets/dot-4vhu.md). Each bridged extension gets its own
 * adapter file next to this one; this module holds only the shared pieces.
 */

import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export interface TextToolResult {
	content: { type: "text"; text: string }[];
	details?: Record<string, unknown>;
}

export function textResult(
	text: string,
	details?: Record<string, unknown>,
): TextToolResult {
	return { content: [{ type: "text", text }], ...(details ? { details } : {}) };
}

export function errorText(err: unknown): string {
	return err instanceof Error ? err.message : String(err);
}

export const PI_NPM_MODULES = join(
	homedir(),
	".pi",
	"agent",
	"npm",
	"node_modules",
);

/**
 * Import a module from a pi-installed npm package by absolute path.
 *
 * User extensions in ~/.pi/agent/extensions cannot resolve pi-installed
 * packages by bare specifier: node's walk-up resolution from the extension
 * file never reaches ~/.pi/agent/npm/node_modules. Pi loads extensions with
 * jiti, so importing the package's TypeScript source by absolute path works.
 *
 * Never throws: returns the module or an error string, so a missing or
 * incompatible target package degrades to a clear tool error instead of
 * crashing session startup.
 */
export async function importPiPackageModule<T>(
	relPath: string,
): Promise<{ module: T; error?: undefined } | { module?: undefined; error: string }> {
	const abs = join(PI_NPM_MODULES, relPath);
	if (!existsSync(abs)) {
		return { error: `Package module not found: ${abs}. Is the package installed via pi?` };
	}
	try {
		return { module: (await import(abs)) as T };
	} catch (err) {
		return { error: `Failed to load ${relPath}: ${errorText(err)}` };
	}
}
