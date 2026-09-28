import { describe, expect, test } from "bun:test";
import fs from "node:fs";
import path from "node:path";

const script = path.join(import.meta.dir, "../scripts/bootstrap-pi.sh");
const url = "http://localhost:${PHX_PORT}/tidewave/mcp";
const generated = { type: "streamable-http", url, lifecycle: "keep-alive" };

// mise tasks run whichever `bash` is on PATH; macOS /bin/bash is 3.2.
const shells = [...new Set(["/bin/bash", Bun.which("bash")].filter((s): s is string => !!s && fs.existsSync(s)))];

for (const bash of shells) {
  const fixture = (config?: object) => {
    const cwd = fs.mkdtempSync("/tmp/pi-bootstrap-test-");
    expect(Bun.spawnSync(["git", "init", "--quiet", cwd]).exitCode).toBe(0);
    fs.mkdirSync(path.join(cwd, ".pi"));
    const mcp = path.join(cwd, ".pi/mcp.json");
    const guidance = path.join(cwd, ".pi/APPEND_SYSTEM.md");
    fs.writeFileSync(path.join(cwd, "AGENTS.md"), "Project-owned guidance\n");
    fs.writeFileSync(guidance, "Keep project notes\n");
    if (config) fs.writeFileSync(mcp, JSON.stringify(config));
    return {
      cwd, mcp, guidance,
      run: () => Bun.spawnSync([bash, script], { cwd }),
      read: () => JSON.parse(fs.readFileSync(mcp, "utf8")),
      files: () => fs.readdirSync(path.join(cwd, ".pi")).sort(),
    };
  };

  describe(`Pi bootstrap runtime Tidewave migration (${bash})`, () => {
    test("parses", () => {
      const result = Bun.spawnSync([bash, "-n", script]);
      expect(result.stderr.toString()).toBe("");
      expect(result.exitCode).toBe(0);
    });

    test("creates the opt-in URL without a configured duplicate and is repeatable", () => {
      const h = fixture();
      expect(h.run().exitCode).toBe(0);
      expect(h.read()).toEqual({ mcpServers: {}, pidewave: { url } });
      const guidance = fs.readFileSync(h.guidance, "utf8");
      expect(guidance).toStartWith("Keep project notes\n\n<!-- mise-tmpl-gen:elixir:begin -->");
      expect(guidance).toEndWith("<!-- mise-tmpl-gen:elixir:end -->\n");
      expect(guidance).toContain("pidewave.url");
      expect(guidance).toContain("Cmd+Shift+C stays inactive until connected");
      expect(fs.readFileSync(path.join(h.cwd, "AGENTS.md"), "utf8")).toBe("Project-owned guidance\n");
      expect(h.run().exitCode).toBe(0);
      expect(fs.readFileSync(h.guidance, "utf8")).toBe(guidance);
      expect(h.files()).toEqual(["APPEND_SYSTEM.md", "mcp.json"]);
    });

    test("creates .pi and runs from a subdirectory", () => {
      const h = fixture();
      fs.rmSync(path.join(h.cwd, ".pi"), { recursive: true });
      fs.mkdirSync(path.join(h.cwd, "lib/deep"), { recursive: true });
      expect(Bun.spawnSync([bash, script], { cwd: path.join(h.cwd, "lib/deep") }).exitCode).toBe(0);
      expect(h.read()).toEqual({ mcpServers: {}, pidewave: { url } });
      expect(fs.readFileSync(h.guidance, "utf8")).toStartWith("<!-- mise-tmpl-gen:elixir:begin -->");
    });

    test("migrates only the generated server and preserves unrelated MCP settings", () => {
      const other = { command: "example-mcp", disabled: true };
      const h = fixture({ mcpServers: { tidewave: generated, other }, settings: { directTools: false } });
      expect(h.run().exitCode).toBe(0);
      expect(h.read()).toEqual({ mcpServers: { other }, settings: { directTools: false }, pidewave: { url } });
    });

    test("refuses custom or disabled Tidewave entries before replacing either file", () => {
      for (const tidewave of [
        { ...generated, url: "http://localhost:4567/tidewave/mcp" },
        { ...generated, disabled: true },
        { ...generated, headers: { "X-Example": "keep" } },
        null,
      ]) {
        const h = fixture({ mcpServers: { tidewave } });
        const original = fs.readFileSync(h.mcp, "utf8");
        const result = h.run();
        expect(result.exitCode).not.toBe(0);
        expect(result.stderr.toString()).toContain("custom tidewave definition");
        expect(fs.readFileSync(h.mcp, "utf8")).toBe(original);
        expect(fs.readFileSync(h.guidance, "utf8")).toBe("Keep project notes\n");
        expect(h.files()).toEqual(["APPEND_SYSTEM.md", "mcp.json"]);
      }
    });

    test("preserves manually migrated URLs across later bootstrap runs", () => {
      const url = "http://localhost:4567/tidewave/mcp";
      const h = fixture({ mcpServers: {}, pidewave: { url } });
      expect(h.run().exitCode).toBe(0);
      expect(h.read().pidewave.url).toBe(url);
      expect(h.run().exitCode).toBe(0);
      expect(h.read().pidewave.url).toBe(url);
    });

    test("rejects malformed opt-in URLs before replacing either file", () => {
      for (const url of ["", null, false, 4567, {}]) {
        const h = fixture({ pidewave: { url } });
        const original = fs.readFileSync(h.mcp, "utf8");
        expect(h.run().exitCode).not.toBe(0);
        expect(fs.readFileSync(h.mcp, "utf8")).toBe(original);
        expect(fs.readFileSync(h.guidance, "utf8")).toBe("Keep project notes\n");
      }
    });

    test("rejects duplicated generated blocks", () => {
      const h = fixture();
      expect(h.run().exitCode).toBe(0);
      const once = fs.readFileSync(h.guidance, "utf8");
      fs.writeFileSync(h.guidance, once + once);
      expect(h.run().exitCode).not.toBe(0);
      expect(fs.readFileSync(h.guidance, "utf8")).toBe(once + once);
    });

    test("retains malformed-file and symlink safeguards", () => {
      for (const text of ["{", ""]) {
        const malformed = fixture();
        fs.writeFileSync(malformed.mcp, text);
        expect(malformed.run().exitCode).not.toBe(0);
        expect(fs.readFileSync(malformed.mcp, "utf8")).toBe(text);
        expect(fs.readFileSync(malformed.guidance, "utf8")).toBe("Keep project notes\n");
      }

      const linked = fixture();
      const target = path.join(linked.cwd, "external.json");
      fs.writeFileSync(target, "{}");
      fs.symlinkSync(target, linked.mcp);
      expect(linked.run().exitCode).not.toBe(0);
      expect(fs.readFileSync(target, "utf8")).toBe("{}");
      expect(fs.readFileSync(linked.guidance, "utf8")).toBe("Keep project notes\n");
    });
  });
}
