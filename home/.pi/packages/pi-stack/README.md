# pi-stack

Lauren Tan's [pstack](https://github.com/cursor/plugins/tree/main/pstack) ("poteto mode") for the [pi](https://pi.dev) coding agent. It vendors the upstream skills at a pinned commit, rewrites their Cursor-only instructions for pi, and turns the mode on only in the repos you list.

pi-stack ships no tools of its own. Delegation, todos, and questions go through tools you already run, mainly `subagent` from [pi-interactive-subagents](https://github.com/amosblomqvist/pi-interactive-subagents).

## What it does

- In an activated repo, every run gets a `pi-stack` system prompt section. It tells the model to read `vendor/skills/poteto-mode/SKILL.md` before rigorous work and carries the map from Cursor terms to pi tools (`references/pi-primitives.md`).
- A `pi-stack-roles` section lists the model for each pstack role, from your `models.json`.
- Sections named in `supersedes` (for example another style extension's `ponytail`) are removed while the mode is on.
- Outside activated repos, pi-stack adds nothing.
- Subagent children never run the playbook. The four agents pi-stack ships (`general-purpose`, `poteto-agent`, `pstack-reviewer`, `comment-sicko`) carry the map in their own prompt and also drop `supersedes` sections.

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

- `activate`: absolute paths or globs (`*` one segment, `**` any depth, `~` allowed). The mode is on in a matching directory and everything below it, worktrees included. Relative entries never match.
- `supersedes`: prompt section names to remove while the mode is on.

`~/.pi/agent/pi-stack/models.json` maps each pstack role to `"provider/id:thinking"`, a list of them for panel roles (one reviewer per entry), or `inherit-parent`. Keys starting with `$` are comments. A missing role runs on the parent model. Each `/setup-pstack` run refreshes `$available` and keeps your role lines.

The two files fail independently. A broken `models.json` drops the role table but keeps activation.

## Commands

- `/poteto-mode on|off|auto|status`: override the mode for this session branch, return to the `activate` rule, or show the state.
- `/setup-pstack`: write or refresh the config files.
- `/skill:<name>`: run a vendored skill directly, for example `/skill:interrogate`.

## Without pi-interactive-subagents

The prompt section lists any missing tool (`subagent`, `todo`, `ask_user_question`, `typesafe_evaluate`) with a fallback. Without `subagent`, the model does each delegated step itself and labels review results "single reviewer, no independent panel".

## Updating from upstream

`scripts/sync.mjs` copies upstream `skills/` into `vendor/skills/` at the commit in `scripts/upstream.json`, then applies `scripts/substitutions.json`:

- 24 rewrite rules, for example `Task` to `subagent`, `AskQuestion` to `ask_user_question`, and `/name` to `/skill:name`.
- Every skill's `name:` becomes its directory name, so `/skill:poteto-mode` resolves.
- Excluded skills: `make-bot-ui`, `bro`, `setup-pstack`. Renamed: `recall` to `pstack-recall`.
- The sync fails if a denied Cursor pattern survives, such as `~/.cursor/` or `Task tool`.

It also builds `vendor/agents/` from `agents-src/` plus the primitive map.

```sh
node scripts/sync.mjs                    # clone upstream at the pin and rebuild vendor/
node scripts/sync.mjs --from <pstack>    # use a local checkout instead
node scripts/sync.mjs --check            # rebuild to a temp dir; fail if vendor/ differs
bun test tests
```

To move to a new release, change `commit` and `version` in `scripts/upstream.json`, run the sync, and fix any denied pattern it reports by adding a rule.

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

pi-warden saves this file with an atomic rename, so a dotfiles symlink at that path is replaced by a plain file on the next `/warden` setting change.

## License

pi-stack is MIT. The vendored skills are copyright Lauren Tan, under the MIT license in `vendor/LICENSE-pstack`.
