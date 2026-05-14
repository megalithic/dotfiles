/**
 * Pinvim Legacy Extension
 *
 * Deprecated compatibility shim.
 * pinvim.ts now owns pi-side nvim state, live context injection, and footer UI.
 * Keep this file only to preserve /pinvim-legacy-info during migration.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI): void {
  pi.registerCommand("pinvim-legacy-info", {
    description: "Show pinvim legacy migration note",
    handler: async (_args, ctx) => {
      const lines = [
        "pinvim_legacy is deprecated.",
        "pinvim.ts is now primary pi-side nvim extension.",
        "Use /pinvim-info for live state.",
        "bridge.ts remains transport-only until deprecation decision lands.",
      ];

      if (ctx.hasUI) {
        ctx.ui.notify(lines.join("\n"), "info");
      }
    },
  });
}
