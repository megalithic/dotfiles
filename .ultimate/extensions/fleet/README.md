Every Ultimate instance on this machine and on the machines in `remotes`, with what each is doing, on one screen of the hub.

This is the hub's (`~/.dotfiles`) Fleet surface, the project's `defaultSurface`. It loads once `~/.dotfiles` is chosen
as a local project (Extensions panel), like any project extension.

## What it shows

One row per instance, grouped by machine:

- **State**, the same as its Rex tab (`rex-status`): an open question is `blocked`, a busy conversation `working`,
  else `idle`; an instance that does not answer within 3 s is `unreachable`, with the reason.
- The first open question, the titles of busy conversations, failed runs of the last 24 hours with the latest one, and
  failing providers. Each links to its conversation; **open** opens the instance.
- **Hubs**, with the rules of `bin/agents` (`home/.pi/agent/lib/registry.ts`): the instance at `fleet.primary` in
  `~/.ultimate/settings.json` is the primary hub; an instance whose folder holds another running instance is a
  secondary hub (e.g. `~/code/work/strive` over `provider_portal`). Members show under their deepest hub.

The status line shows the same counts on other surfaces. Coordination goes through the docked @ultimate
(`ultimate.tell`).

Links to a local instance keep the page's host and use the instance's port, so they work from `127.0.0.1`,
`ultimate.localhost` and the tailnet address alike (Tailscale serves each instance on its local port).

## Action

`fleet/list` (no args, polled) → `{ machine, at, instances: Row[] }` (`Row` in `lib.ts`). Local instances come from
`host.projects()`; remote ones from `remotes` in user settings, skipping entries for this machine, since dotfiles
shares the settings between machines. Each is asked for `status/status` and `codemode/read {op: 'conversations'}`
with its own `Origin`, in parallel.

## Tests

`.ultimate/tests/fleet.test.ts` (`mise run test:ts`) checks hub roles against the registry and states against
`rex-status`.
