/**
 * Project guidance
 *
 * Adds `<cwd>/.pi/AGENTS.md` to the project context, next to the repo's own
 * AGENTS.md. Template bootstrap scripts generate that gitignored file (see
 * config/mise/tmpls/elixir/scripts/bootstrap-pi.sh). Pi's native
 * `.pi/APPEND_SYSTEM.md` would replace the global APPEND_SYSTEM.md instead of
 * adding to it, so generated guidance lives here.
 *
 * Disable with PI_PROJECT_GUIDANCE_DISABLE=1.
 */

import fs from "node:fs";
import path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", (event) => {
    if (process.env.PI_PROJECT_GUIDANCE_DISABLE === "1") return;
    const file = path.join(event.systemPromptOptions.cwd, ".pi", "AGENTS.md");
    let content: string;

    try {
      content = fs.readFileSync(file, "utf8");
    } catch {
      return; // absent or unreadable: nothing to add
    }

    // Mutate instead of returning systemPrompt so Pi can send a prompt delta.
    event.systemPromptOptions.contextFiles.push({ path: file, content });
  });
}
