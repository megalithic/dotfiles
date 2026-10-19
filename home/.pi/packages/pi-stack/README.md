# pi-stack

Lauren Tan's [pstack](https://github.com/cursor/plugins/tree/main/pstack) ("poteto mode") for the [pi](https://pi.dev) coding agent. It vendors the upstream skills at a pinned commit, rewrites their Cursor-only instructions for pi, and turns the mode on only in the repos you list. Here the mode is called mega mode: upstream's `poteto-mode`, `poteto-help`, and `poteto-agent` run as `mega-mode`, `mega-help`, and `mega-agent`.

pi-stack ships no tools of its own. Delegation, todos, and questions go through tools you already run, mainly `subagent` from [pi-interactive-subagents](https://github.com/amosblomqvist/pi-interactive-subagents).

## What it does

- In an activated repo, every run gets a `pi-stack` system prompt section. It tells the model to read `vendor/skills/mega-mode/SKILL.md` before rigorous work and carries the map from Cursor terms to pi tools (`references/pi-primitives.md`).
- A `pi-stack-roles` section lists the model for each pstack role, from your `models.json`.
- Sections named in `supersedes` (for example another style extension's `ponytail`) are removed while the mode is on.
- Outside activated repos, pi-stack adds nothing.
- Subagent children never run the playbook. The four agents pi-stack ships carry the map in their own prompt:
  - `general-purpose` and `mega-agent` have every tool, also drop `supersedes` sections, and never push, open PRs, write to trackers or chat, migrate shared databases, or deploy. They report back instead.
  - `pstack-reviewer` has read tools and `safe_bash`. `safe_bash` blocks only dangerous commands, so the reviewer is read-only by instruction, not by capability.
  - `comment-sicko` adds `edit`, for deleting comments.

## Install

pi-stack is not published on its own yet. Copy this directory and add its path as the last entry in `packages` in `~/.pi/agent/settings.json`:

```json
{ "packages": ["...your other packages...", "~/path/to/pi-stack"] }
```

Keep it last. pi runs `before_agent_start` handlers grouped by extension in load order, so `supersedes` removes only sections that earlier extensions wrote.

Make the agents discoverable by linking `vendor/agents/*.md` into `~/.pi/agent/agents/`.

Then run `/setup-pstack` once. It writes `~/.pi/agent/pi-stack/config.json` and `~/.pi/agent/pi-stack/models.json` and lists the models pi can see. Edit both, then `/reload`.

## Configuration

`~/.pi/agent/pi-stack/config.json`:

```json
{
  "activate": ["~/code/work/*"],
  "supersedes": ["ponytail"]
}
```

- `activate`: absolute paths or globs (`*` one segment, `**` any depth, `~` allowed). The mode is on in a matching directory and everything below it, worktrees included. Relative entries never match. Matching uses the physical path, so list real directories, not symlinks. An unknown key is an error.
- `supersedes`: prompt section names to remove while the mode is on.

`~/.pi/agent/pi-stack/models.json` maps each pstack role to `"provider/id:thinking"` or, for panel roles, a list of them (one reviewer per entry). A role with no line runs on the parent model. Give each panel role two or more models; a panel on one model is labeled "single model, not an independent panel". Keys starting with `$` are comments. Each `/setup-pstack` run rewrites `$comment`, `$roles` (the role names), and `$available` (the models pi can see) and keeps your role lines.

The two files fail independently. A broken `models.json` drops the role table but keeps activation.

## Commands

- `/mega-mode on|off|auto|status`: override the mode for this session branch, return to the `activate` rule, or show the state.
- `/mega-mode <task>`: turn the mode on for this session and run the task through the mega-mode skill. Use this outside activated repos.
- `/setup-pstack`: write or refresh the config files.
- `/skill:<name>`: run a vendored skill directly, for example `/skill:interrogate`. The map from Cursor terms to pi tools is in the prompt only while the mode is on, so outside activated repos run `/mega-mode on` first.

## Without pi-interactive-subagents

The prompt section lists any missing tool (`subagent`, `todo`, `ask_user_question`, `typesafe_evaluate`) with a fallback. Without `subagent`, the model does each delegated step itself and labels review results "single reviewer, no independent panel".

## Updating from upstream

`scripts/sync.mjs` copies upstream `skills/` into `vendor/skills/` at the commit in `scripts/upstream.json`, then applies `scripts/substitutions.json`:

- Rewrite rules, for example `Task` to `subagent`, `AskQuestion` to `ask_user_question`, and `/name` to `/skill:name`, and `poteto-*` names to `mega-*`.
- Every skill's `name:` becomes its directory name, so `/skill:mega-mode` resolves.
- Excluded skills: `make-bot-ui`, `bro`, `setup-pstack`. Renamed: `recall` to `pstack-recall`, `poteto-mode` to `mega-mode`, `poteto-help` to `mega-help`.
- The sync fails if a denied Cursor pattern survives, such as `~/.cursor/`, `Task tool`, or a `poteto` name, or if a rule matches nothing because upstream reworded its target.

It also builds `vendor/agents/` from `agents-src/` plus the primitive map.

```sh
node scripts/sync.mjs                    # clone upstream at the pin and rebuild vendor/
node scripts/sync.mjs --from <pstack>    # use a local checkout instead
node scripts/sync.mjs --check            # rebuild to a temp dir; fail if vendor/ differs
bun test tests
```

To move to a new release, change `commit` and `version` in `scripts/upstream.json`, run the sync, and fix what it reports: add a rule for a denied pattern, and fix or delete a rule that matches nothing. A failed sync leaves `vendor/` unchanged.

## Gating irreversible actions

pi-stack does not gate commands. With [pi-warden](https://github.com/DevMortimer/pi-warden) you can make the agent ask before irreversible commands. Add rules to the user config `~/.pi/agent/pi-warden/config.json`; project files cannot add `confirm` rules. The rules apply in every repo, not only activated ones:

```json
{
  "action": {
    "commandRules": [
      { "id": "git-push", "pattern": "\\bgit\\s+push\\b", "severity": "confirm" },
      { "id": "gh-write", "pattern": "\\bgh\\s+(pr\\s+(create|merge|ready|close)|release\\s+create|workflow\\s+run)\\b", "severity": "confirm" },
      { "id": "deploy", "pattern": "\\bmise\\s+(run\\s+)?deploy\\b|\\.agents/scripts/deploy\\b", "severity": "confirm" },
      { "id": "shared-db", "pattern": "(MIX_ENV=(prod|staging)|DATABASE_URL=\\S+).*\\bmix\\s+ecto\\.", "severity": "confirm" }
    ]
  }
}
```

Agents with a `tools:` line (such as `pstack-reviewer`) start with `--no-extensions`, so pi-warden does not run inside them.

pi-warden saves this file with an atomic rename, so a dotfiles symlink at that path is replaced by a plain file on the next `/warden` setting change.

## License

pi-stack is MIT. The vendored skills are copyright Lauren Tan, under the MIT license in `vendor/LICENSE-pstack`.
