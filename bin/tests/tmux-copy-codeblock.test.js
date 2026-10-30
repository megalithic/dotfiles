// bun test bin/tests/tmux-copy-codeblock.test.js
import { expect, test } from "bun:test";
import { chmodSync, mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const SCRIPT = join(import.meta.dir, "..", "tmux-copy-codeblock");
const ID = "01a1-test-session";

// Fake HOME with one pi session, and a fake tmux that reports it for pane %1.
function sandbox(markdown) {
  const home = mkdtempSync(join(tmpdir(), "codeblock-"));
  const sessions = join(home, ".pi/agent/sessions/--proj--");
  mkdirSync(sessions, { recursive: true });
  const entry = { type: "message", message: { role: "assistant", content: [{ type: "text", text: markdown }] } };
  writeFileSync(join(sessions, `2026-01-01_${ID}.jsonl`), `${JSON.stringify(entry)}\n`);
  const bin = join(home, "bin");
  mkdirSync(bin);
  writeFileSync(join(bin, "tmux"), `#!/bin/sh\n[ "$4" = "%1" ] && echo ${ID}\n`);
  chmodSync(join(bin, "tmux"), 0o755);
  return { HOME: home, PATH: `${bin}:${process.env.PATH}` };
}

function run(screen, env, pane = "%1") {
  const out = Bun.spawnSync([SCRIPT], { stdin: Buffer.from(screen), env: { ...env, FASTCOPY_TARGET_PANE_ID: pane } });
  expect(out.stderr.toString()).toBe("");
  return out.stdout.toString();
}

const pad = (line) => `${line.padEnd(40)}│`; // pi pads to the pane edge, then the scrollbar

test("pi pane: exact code from the session despite wrapping, tabs and scrollbar", () => {
  const code = "def run(x):\n\tif x:   # tab + spaces\n\n\t\treturn some_function_name(argument_one, argument_two)";
  const env = sandbox(`Try this:\n\n\`\`\`python\n${code}\n\`\`\`\n\nDone.`);
  const screen = [
    " ```python",
    "   def run(x):",
    "      if x:   # tab + spaces",
    "",
    "         return some_function_name(",
    " argument_one, argument_two)",
    " ```",
  ].map(pad).join("\n");
  expect(run(screen, env)).toBe(code);
});

test("pi pane: fence inside a list item, with a longer closing fence", () => {
  const env = sandbox("1. Run:\n\n   ~~~~bash\n   cd /tmp\n     ls ~~~\n   ~~~~~\n2. Done");
  const screen = ["    ```bash", "      cd /tmp", "        ls ~~~", "    ```"].map(pad).join("\n");
  expect(run(screen, env)).toBe("cd /tmp\n  ls ~~~");
});

test("pi pane: rebuilds from the screen when the session has no match", () => {
  const env = sandbox("no code here");
  const screen = [" ```sh", "   echo one", "     indented", "   echo a very long", " wrapped line", " ```"]
    .map(pad)
    .join("\n");
  expect(run(screen, env)).toBe("echo one\n  indented\necho a very long wrapped line");
});

test("other pane: strips only the fence indent", () => {
  const env = sandbox("");
  const screen = "  ```js\n  if (a) {\n    b();\n  }\n  ```";
  expect(run(screen, env, "%2")).toBe("if (a) {\n  b();\n}");
});
