#!/usr/bin/env node
// Vendors upstream pstack (cursor/plugins/pstack) into ./skills and ./agents at the
// commit pinned in upstream.json, applies scripts/substitutions.json, and fails on
// any denied Cursor-only pattern that survives. Idempotent: rerun after bumping the
// pin. Usage: node scripts/sync.mjs [--check] [--from <local pstack dir>]
//   --check  rebuild into a temp dir and diff against ./skills; exit 1 on drift
//   --from   use a local checkout of cursor/plugins/pstack instead of cloning

import { execFileSync } from "node:child_process";
import { cpSync, mkdtempSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync, mkdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(dirname(fileURLToPath(import.meta.url)));

const pin = JSON.parse(readFileSync(join(root, "scripts/upstream.json"), "utf8"));

const table = JSON.parse(readFileSync(join(root, "scripts/substitutions.json"), "utf8"));

const args = process.argv.slice(2);

const check = args.includes("--check");

const fromIdx = args.indexOf("--from");

const fromDir = fromIdx >= 0 ? args[fromIdx + 1] : null;

function fetchUpstream() {
  if (fromDir) return fromDir;
  const dir = mkdtempSync(join(tmpdir(), "pi-stack-upstream-"));
  execFileSync("git", ["clone", "--quiet", "--filter=blob:none", "--no-checkout", pin.repo, dir], { stdio: "inherit" });
  execFileSync("git", ["-C", dir, "sparse-checkout", "set", pin.subdir], { stdio: "inherit" });
  execFileSync("git", ["-C", dir, "checkout", "--quiet", pin.commit], { stdio: "inherit" });

  return join(dir, pin.subdir);
}

function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);

    if (statSync(p).isDirectory()) walk(p, out);
    else out.push(p);
  }

  return out;
}

export function applyRules(text, rules) {
  let out = text;

  for (const rule of rules) {
    out = out.replace(new RegExp(rule.pattern, "gm"), rule.replace);
  }

  return out;
}

export function findDenied(text, patterns) {
  const hits = [];
  const lines = text.split("\n");

  for (const pattern of patterns) {
    const re = new RegExp(pattern);
    lines.forEach((line, i) => {
      if (re.test(line)) hits.push({ pattern, line: i + 1, text: line.trim() });
    });
  }

  return hits;
}

function build(src, dest) {
  rmSync(dest, { recursive: true, force: true });
  mkdirSync(join(dest, "skills"), { recursive: true });
  mkdirSync(join(dest, "agents"), { recursive: true });

  for (const skill of readdirSync(join(src, "skills"))) {
    if (table.exclude.skills.includes(skill)) continue;
    const target = table.exclude.rename[skill] ?? skill;
    cpSync(join(src, "skills", skill), join(dest, "skills", target), { recursive: true });
  }

  cpSync(join(src, "agents"), join(dest, "agents-upstream"), { recursive: true });
  cpSync(join(src, "LICENSE"), join(dest, "LICENSE-pstack"));
  buildAgents(dest);

  const problems = [];

  for (const file of walk(dest)) {
    if (!file.endsWith(".md")) continue;
    let text = applyRules(readFileSync(file, "utf8"), table.rules);
    const rel = relative(dest, file);
    // pi registers /skill:<name> from the frontmatter name and only warns on an invalid one.
    // Upstream's "Poteto Mode" would never resolve, so every skill takes its directory name.
    const skillDir = rel.match(/^skills\/([^/]+)\/SKILL\.md$/)?.[1];

    if (skillDir) text = text.replace(/^name: .*$/m, `name: ${skillDir}`);
    writeFileSync(file, text);

    for (const hit of findDenied(text, table.deny.patterns)) problems.push({ file: rel, ...hit });
  }

  writeFileSync(
    join(dest, "UPSTREAM.json"),
    JSON.stringify({ ...pin, syncedAt: new Date().toISOString(), rules: table.rules.map((r) => r.id) }, null, 2) + "\n",
  );

  return problems;
}

// Each agent file is its source body plus the primitive map, so a restricted child that never
// sees the parent's prompt section still knows how upstream words map to pi tools.
function buildAgents(dest) {
  const map = readFileSync(join(root, "references/pi-primitives.md"), "utf8");
  mkdirSync(join(dest, "agents"), { recursive: true });

  for (const name of readdirSync(join(root, "agents-src"))) {
    const body = readFileSync(join(root, "agents-src", name), "utf8").trimEnd();
    writeFileSync(join(dest, "agents", name), `${body}\n\n---\n\n${map.trim()}\n`);
  }
}

function diffDirs(a, b) {
  try {
    execFileSync("diff", ["-r", "--exclude=UPSTREAM.json", a, b], { stdio: "inherit" });

    return true;
  } catch {
    return false;
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const src = fetchUpstream();
  const dest = check ? mkdtempSync(join(tmpdir(), "pi-stack-check-")) : join(root, "vendor");
  const problems = build(src, dest);

  if (problems.length) {
    console.error(`sync: ${problems.length} denied pattern(s) survived substitution:`);

    for (const p of problems) console.error(`  ${p.file}:${p.line}  ${p.pattern}  ${p.text}`);
    process.exit(1);
  }

  if (check) {
    const same = diffDirs(join(root, "vendor"), dest);
    rmSync(dest, { recursive: true, force: true });

    if (!same) {
      console.error("sync --check: ./vendor differs from a fresh build. Run node scripts/sync.mjs and commit.");
      process.exit(1);
    }

    console.log("sync --check: vendor is current");
  } else {
    console.log(`synced pstack ${pin.version} (${pin.commit.slice(0, 7)}) into ${relative(process.cwd(), dest)}`);
  }
}
