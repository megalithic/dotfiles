# Worktree fixture contracts

This directory contains the Phase 1, dependency-free contract harness. It creates temporary Git repositories and uses an isolated tmux socket/config; it never starts project services, databases, or real Pi sessions.

## Safe commands

```bash
tests/worktree/run.sh self-test
WT_BIN=bin/wt FTM_BIN=bin/ftm tests/worktree/run.sh contract
```

`self-test` must pass. `contract` probes `WT_BIN` and `FTM_BIN` as black boxes and returns nonzero while any contract fails. After Phase 3 the deterministic `ftm` cases pass (`lock-lease`, `windows`, `repair`, `pi-cwd`, `generic-ftm`, `pi-uuid`); every `wt`-driven case stays red until the v2 `wt` commands exist (Phase 4). Each system-under-test invocation has a five-second bound. The harness records failures without hanging or attaching.

The harness replaces Worktrunk, mise, Pi, and service commands with inert fixtures. It wraps the real tmux binary with a unique `-L` socket and `/dev/null` config, then kills only that server. Noninteractive backend calls receive closed stdin; the picker fixture receives a pseudo-terminal.

`cases.tsv` maps every Phase 1 requirement to an executable test ID. The tests cover target classification, schema adaptation and rejection, resolver/version pinning, phase ordering, lock and identity safety, prune refusals and partial results, JSON and exit classes, canonical windows, additive repair, exact-cwd Pi invocation, patch-equivalent integration, deterministic non-worktree sessions, and explicit Pi session UUIDs.

Remaining Phase 1 fixture work must deepen the valid-lease matrix, model fork `pushRemote` state, change a worktree identity between prune preflight and removal, and assert cleanup after forced timeout. Keep those cases red or incomplete rather than weakening the contract.

Scripts are generated only in a later migration step: templates -> `mise-tmpl-gen` -> repository `.config/scripts`. This fixture foundation does not generate or install project scripts.
