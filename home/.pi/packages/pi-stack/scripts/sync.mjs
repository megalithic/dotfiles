#!/usr/bin/env node
// Vendors upstream pstack (cursor/plugins/pstack) into ./vendor at the commit pinned in
// upstream.json, applies scripts/substitutions.json, and fails on any denied Cursor-only
// pattern that survives or any rule that matches nothing. Builds in a temp dir and replaces
// ./vendor only when the build is clean. Usage: node scripts/sync.mjs [--check] [--from <dir>]
//   --check  rebuild into a temp dir and diff against ./vendor; exit 1 on drift
//   --from   use a local checkout of cursor/plugins/pstack instead of cloning

import { execFileSync } from "node:child_process";
import { cpSync, mkdtempSync, readdirSync, readFileSync, realpathSync, rmSync, statSync, writeFileSync, mkdirSync } from "node:fs";
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

if (fromIdx >= 0 && !fromDir) {
  console.error("sync: --from needs a directory");
  process.exit(1);
}

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

export function applyRules(text, rules, used = new Set()) {
  let out = text;

  for (const rule of rules) {
    const re = new RegExp(rule.pattern, "gm");

    if (re.test(out)) used.add(rule.id);
    out = out.replace(re, rule.replace);
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
  mkdirSync(join(dest, "skills"), { recursive: true });

  for (const skill of readdirSync(join(src, "skills"))) {
    if (table.exclude.skills.includes(skill)) continue;
    const target = table.exclude.rename[skill] ?? skill;
    cpSync(join(src, "skills", skill), join(dest, "skills", target), { recursive: true });
  }

  cpSync(join(src, "agents"), join(dest, "agents-upstream"), { recursive: true });
  cpSync(join(src, "LICENSE"), join(dest, "LICENSE-pstack"));

  const problems = [];
  const used = new Set();

  for (const file of [...walk(join(dest, "skills")), ...walk(join(dest, "agents-upstream"))]) {
    if (!file.endsWith(".md")) continue;
    let text = applyRules(readFileSync(file, "utf8"), table.rules, used);
    const rel = relative(dest, file);
    // pi registers /skill:<name> from the frontmatter name and only warns on an invalid one.
    // Upstream's `name: Poteto Mode` would never resolve, so every skill takes its directory name (mega-mode).
    const skillDir = rel.match(/^skills\/([^/]+)\/SKILL\.md$/)?.[1];

    if (skillDir) text = text.replace(/^name: .*$/m, `name: ${skillDir}`);
    writeFileSync(file, text);

    for (const hit of findDenied(text, table.deny.patterns)) problems.push({ file: rel, ...hit });
  }

  // A rule that matches nothing means upstream reworded its target; fix or delete the rule.
  for (const rule of table.rules) {
    if (!used.has(rule.id)) problems.push({ file: "scripts/substitutions.json", line: 0, pattern: rule.id, text: "rule matched nothing" });
  }

  // After the rule pass: the map's left column names Cursor terms on purpose.
  buildAgents(dest);

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

// realpath both sides: through a symlinked package dir, argv[1] is the link path.
if (process.argv[1] && realpathSync(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const src = fetchUpstream();
  const dest = mkdtempSync(join(tmpdir(), "pi-stack-build-"));
  const vendor = join(root, "vendor");
  const problems = build(src, dest);

  if (problems.length) {
    rmSync(dest, { recursive: true, force: true });
    console.error(`sync: ${problems.length} problem(s): denied patterns that survived substitution, or rules that matched nothing. ./vendor is unchanged:`);

    for (const p of problems) console.error(`  ${p.file}:${p.line}  ${p.pattern}  ${p.text}`);
    process.exit(1);
  }

  if (check) {
    const same = diffDirs(vendor, dest);
    rmSync(dest, { recursive: true, force: true });

    if (!same) {
      console.error("sync --check: ./vendor differs from a fresh build. Run node scripts/sync.mjs and commit.");
      process.exit(1);
    }

    console.log("sync --check: vendor is current");
  } else {
    rmSync(vendor, { recursive: true, force: true });
    cpSync(dest, vendor, { recursive: true });
    rmSync(dest, { recursive: true, force: true });
    console.log(`synced pstack ${pin.version} (${pin.commit.slice(0, 7)}) into ${relative(process.cwd(), vendor)}`);
  }
}
