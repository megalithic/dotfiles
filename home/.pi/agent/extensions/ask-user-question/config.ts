/** Key spec for the overlay collapse/expand shortcut, e.g. `"ctrl+]"`, or `"off"`. */
export type CollapseKeySpec = string;

export const DEFAULT_COLLAPSE_KEY: CollapseKeySpec = "ctrl+]";

export const COLLAPSE_KEY_OFF: CollapseKeySpec = "off";

/** Display form of a key spec: each `+`-part capitalized (`"ctrl+]"` -> `"Ctrl+]"`). Never feed it back to `matchesKey`. */
export function formatKeySpecForDisplay(spec: CollapseKeySpec): string {
	return spec
		.split("+")
		.map((part) => part.charAt(0).toUpperCase() + part.slice(1))
		.join("+");
}
