/**
 * Single import surface for UI strings. Upstream backs `t` with rpiv-i18n; this copy
 * is English only, so `t(key, fallback)` returns the inline English literal.
 */

import { ROW_INTENT_META, type SentinelKind } from "./row-intent.js";

export function t(_key: string, fallback: string): string {
	return fallback;
}

export function displayLabel(kind: SentinelKind): string {
	return t(`sentinel.${kind}`, ROW_INTENT_META[kind].label);
}
