---
description: Extensive code review — 3 parallel reviewers (Claude Code recipe, ponytail-review, /review rubric), arbitrated by claude-fable + Jev, rendered as one artifact
argument-hint: "<pr-url|pr-number|branch|commit|uncommitted> [extra focus…]"
---

Run an extensive, read-only code review of `$1` with three independent reviewers in parallel, then have an arbiter + Jev find the consensus, and show the result as one artifact where each item keeps context, question and answer together. Never edit, commit or push the code under review. Extra focus from the caller: `${@:2}` (empty means none).

Support files (static, never regenerate them):

- `~/.dotfiles/home/.pi/scripts/code-review/claude-review-recipe.md` — Claude Code `/review` recipe, placeholder `{DIFF_FILE}`
- `~/.dotfiles/home/.pi/scripts/code-review/task-arbiter.md` — arbiter task, placeholders `{TARGET_LABEL} {BASE} {HEAD} {REVIEW_DIR}`
- `~/.dotfiles/home/.pi/scripts/code-review/render.py` — renders the artifact HTML from the review dir
- `~/.pi/agent/git/github.com/DietrichGebert/ponytail/skills/ponytail-review/SKILL.md` — ponytail-review skill (inline the body from `Review a change like` to the end)
- `~/.pi/agent/extensions/review.ts` — pi `/review` extension; extract the rubric with `re.search(r'const REVIEW_RUBRIC = \`(.*?)\`;', src, re.S)`
- Agents (global, `~/.pi/agent/agents/`): `cc-review` (claude-opus-5-5:xhigh), `ponytail-review` (gpt-6-astra:xhigh), `rubric-review` (claude-opus-5-5:xhigh), `review-arbiter` (claude-fable-5-1:xhigh). All read-only (`read, grep, find, ls`).

## 1. Resolve the target (one bash call)

- Empty `$1` → ask what to review, then stop.
- PR URL or number → `gh pr view <n> --json number,title,body,url,baseRefName,headRefName,headRefOid,state`; `git fetch origin <base> <head>`; base = merge base of `origin/<base>` and `origin/<head>`; head = `headRefOid`; label `PR #<n>: <title>`; slug `pr-<n>`.
- Branch name → `git fetch origin main <branch>`; base = `git merge-base origin/main origin/<branch>`; head = `origin/<branch>`; slug = branch.
- `uncommitted` → base = `HEAD`, head = working tree (`git diff HEAD` + untracked files via `git diff --no-index /dev/null <file>`); checkout = cwd; slug `uncommitted-<short-sha>`.
- Commit sha → base = `<sha>^`, head = `<sha>`; checkout = cwd if it contains the commit; slug = short sha.

Model ids drift: run `pi --list-models` once and, if an agent's model is missing, pass the closest id via the `model` override and say so in the final reply.

## 2. Checkout + review dir

- PR/branch targets need the head checked out so reviewers can read callers, callees and tests. Use `wt ensure <head-branch> --json` (timeout 900). `worktree_exists: true` is enough; a failed `setup` phase (DB, deps) does not matter for a read-only review — note it and continue. Never run raw `git worktree`. `checkout=$(wt path <head-branch>)`; confirm `git -C $checkout rev-parse HEAD` equals head.
- `REVIEW_DIR=~/.local/share/pi/docs/$(basename "$(git rev-parse --show-toplevel)")/<slug>-review`. Write there:
  - `diff.patch` — `git diff <base>...<head>` (for `uncommitted`: `git diff HEAD` plus untracked files)
  - `description.md` — PR title + body, or `git log <base>..<head>` for branches/commits
  - `meta.json` — `{"title":"<label> — consensus review","target":"<url or ref>","base":"<sha>","head":"<sha>","reviewers":{"A":"Claude Code /review recipe · <model>","B":"ponytail-review · <model>","C":"pi /review rubric · <model>"},"arbiter":"review-arbiter · <model>","jev_model":"<filled after step 5>"}`

## 3. Build the three task prompts

Write `common-context.md` first, then the three task files (`task-cc.md`, `task-ponytail.md`, `task-rubric.md`), each = framing line + common context + the reviewer's own method.

`common-context.md`:

```
## Review target
- <label> — <url or ref>
- Base <base sha> (merge base); head <head sha>
- Your working directory IS the head checkout (clean). Read any file to see connected code (callers, callees, tests, agent_docs/*.md, AGENTS.md).
- Pre-generated unified diff: <REVIEW_DIR>/diff.patch (<n> lines, <files> files, +<add>/-<del>)
- Change description: <REVIEW_DIR>/description.md
- Stack: <one line, e.g. Elixir / Phoenix LiveView / Ecto / Oban>
- Extra focus from the caller: <${@:2} or "none">

You are read-only: read/grep/find/ls only, no shell, no write tool. Do not ask questions; state assumptions and continue. Do not stop early: read the whole diff and the code it touches.

## Machine-readable appendix (required)
After the human-readable report, append a fenced ```json block: an array with every finding you reported, same order, shape:
[{"id":"F1","file":"path","line":42,"title":"short","severity":"critical|high|medium|low","category":"correctness|security|data-loss|concurrency|test-coverage|conventions|reuse|simplification|efficiency|altitude|other","summary":"1-3 sentences","scenario":"concrete input/state -> wrong outcome, or concrete cost","fix":"smallest fix","verified_by":"read code|inferred"}]
```

- `task-cc.md`: "You are running the Claude Code `/review` recipe below, inline, as a single reviewer. Follow it exactly." + common context + the recipe with `{DIFF_FILE}` replaced by the diff path.
- `task-ponytail.md`: "Run the ponytail-review skill (reproduced below) on the change described after it. The review is the full report the user asked for." + common context + `## The ponytail-review skill` + skill body.
- `task-rubric.md`: rubric + `\n\n---\n\nPlease perform a code review with the following focus:\n\n` + "Review <label> against base <base>. You have no shell: instead of `git diff`, read the pre-generated diff named below, then read the touched files in your working directory. Provide prioritized, actionable findings." + common context.

## 4. Spawn the reviewers, then end the turn

One codemode call: read the three task files, `Promise.allSettled` three `subagent` calls with `cwd: checkout`, names `cc-review`, `ponytail-review`, `rubric-review`. Then end the turn with a two-line status. Do not poll, sleep, or read session files — results arrive as steer messages.

As each result arrives, save it verbatim: `report-cc.md`, `report-ponytail.md`, `report-rubric.md`. If a reviewer failed or returned no JSON appendix, record that in `meta.json` under `"missing"` and continue with what exists.

## 5. Arbiter, then Jev

When all three reports are saved: instantiate `task-arbiter.md` (replace the four placeholders), spawn `review-arbiter` with `cwd: checkout`, end the turn.

On the arbiter result, split it into three files: the markdown before `## Engineer summary` → `arbiter-summary.md`; the `## Engineer summary` section (heading excluded) → `engineer-summary.md`; the JSON array → `arbiter.json` (validate with `python3 -m json.tool`; if the JSON is broken, fix only the syntax, never the content). If the arbiter omitted the engineer summary, resume it with `subagent_message` and ask for that section only; do not write it yourself.

Jev (`typesafe_evaluate`, operator opt-in already on; 20 attempts per session, no retries — batch carefully):

- ≤ 8 clusters per call (32-question cap). State `{"clusters":{"C1":{title,file,line,severity,verdict,consensus,context,question,answer},…}}` with only that batch; keep under 64 KiB (drop `raised_by` and trim `context.code` to 15 lines if needed).
- Per cluster, name the field in every instruction:
  - `C1_defect` noul: "Does clusters.C1 describe a real defect introduced by this change (not pre-existing, not a style preference), given the quoted code?"
  - `C1_resolves` noul: "Does clusters.C1.answer directly resolve clusters.C1.question using evidence from the quoted code?"
  - `C1_fix_minimal` noul: "Is clusters.C1.answer.fix the smallest change that fully resolves the item?"
  - `C1_severity` score, criteria `["cosmetic","minor","should fix before merge","blocks merge"]`: "How severe is the problem in clusters.C1 if shipped as-is?"
- Save `jev.json` as `{"C1":{"defect":p,"resolves":p,"fix_minimal":p,"severity":"<chosen level>"},…}` and put the returned `model` id into `meta.json.jev_model`. Report Jev numbers as the model's judgments, never replace them with your own.

## 6. Render and reply

- `python3 ~/.dotfiles/home/.pi/scripts/code-review/render.py <REVIEW_DIR>` → `consensus.html`.
- `artifact` action=create, kind=html, `path` = that file, title `<slug> consensus review`. If the user must choose what to fix, attach one `decisions` entry per blocker/should-fix item instead of asking in the terminal.
- Final reply, in this order:
  1. Artifact URL and one line: arbiter verdict + counts per severity.
  2. **The engineer summary, verbatim, inside a fenced markdown block** so it can be copied straight into Slack or a GitHub PR comment. This is required on every run: a concise summary of the required / recommended / beneficial changes, followed by the rest of the review's suggestions, written for the PR author. Never paraphrase it in prose instead of pasting it.
  3. Model substitutions and what was not checked (e.g. "no DB in the review worktree", missing reports, unverifiable external contracts).
  Leave the worktree in place unless asked; mention `wt prune <branch>` as the cleanup. Do not post the summary to GitHub or Slack yourself; the user decides where it goes.
