# Fantastical sync

`bin/fantastical-sync` is a standalone manual Fantastical snapshot tool.

It has no scheduler, no orchestrator, and no SSH execution. It mirrors the
Helium WOLFHALL snapshot conventions: local staging, validation, hidden
incoming directory, same-filesystem rename, `READY` written last.

## CLI

Four local modes; restore is the only destructive one and requires `--apply`.

```text
mise run sync:fantastical -- snapshot [--dry-run]
mise run sync:fantastical -- verify --snapshot PATH
mise run sync:fantastical -- publish --snapshot PATH [--dry-run]
mise run sync:fantastical -- restore --snapshot PATH --apply [--dry-run]
```

Details:

`snapshot` captures the live containers, group container, and a `defaults
export` into `~/.local/share/fantastical-sync/staging/snapshots/v1/<host>/<id>/`
and writes a `ditto -c -k --sequesterRsrc --keepParent` archive beside it.
`verify` validates a snapshot given as a tree directory, a `.zip` archive, or
a published NAS directory. `publish` copies the archive to
`/Volumes/Backups/sync/fantastical/snapshots/v1/<host>/<id>/` (WOLFHALL,
mounted over SMB) through a hidden `.incoming` sibling, re-verifies the
archive checksum on NAS bytes, renames, then writes `READY` last. `restore`
requires `--apply` and a READY snapshot; snapshot, verify, and publish are
non-destructive. `--dry-run` prints the plan and performs no writes and no
process checks.

Cross-machine flow: snapshot + publish on the source host, mount the same NAS
share on the destination host, restore from the published directory (the zip
preserves resource forks and xattrs across SMB). There is no remote SSH mode;
appbak, Nix, and settings-sync are not involved.

## Snapshot format and safety

Snapshots hold complete container trees, the group container, and preferences.

The snapshot contains every case-insensitive Fantastical/Flexibits directory
under `~/Library/Containers` (copied per container with `ditto`), the exact
group container `85C27NK92C.com.flexibits.fantastical2.mac`, and a `defaults
export` of `com.flexibits.fantastical2.mac`. `.stfolder` markers are stripped
from the staged copy. Snapshot id is `<UTC>-<hash12>` where the hash is the
SHA-256 identity of the sorted per-file checksum list.

Each snapshot carries `manifest.json` (`fantastical.snapshot.v1`: host,
captured_at, app_version, container_count, payload identity) and
`checksums.sha256`. Validation requires the manifest, the defaults export, the
group and per-container `.com.apple.containermanagerd.metadata.plist` files
(leading dot; the real on-disk name), at least one `*.fcdata`, at least one
`Sources-*.plist`, no `.stfolder`, every checksum, the payload identity, and
the id suffix. `READY` is written only after validation.

Process gate: the tool refuses to run snapshot or restore while any
Fantastical/Flexibits process is alive (matched against `ps` command names).
It never terminates processes; the user quits Fantastical first.

Restore first captures a fully validated snapshot of the current live state
into `~/.local/share/pi/backups/fantastical/`, then replaces containers and
group container (old trees go to Trash via `trash`), imports the defaults
export, and post-verifies. On failure after replacement starts, it rolls back
from that backup or reports indeterminate. Restore also refuses when the
snapshot and installed app versions differ.

Logs are mode 0600 under `~/.local/state/fantastical-sync` and report only
ids, counts, hashes, statuses, and snapshot paths - never plist contents,
account or calendar names, URLs, or credentials. Failed NAS `.incoming`
directories are retained for inspection; local temp and failed staging paths
are cleaned with `trash`.

All roots (containers, group parent, defaults domain, app plist, staging,
NAS, backups, state, process regex) are overridable via `FANTASTICAL_SYNC_*`
environment variables, which is how the isolated fixture test exercises
snapshot/verify/publish/restore without touching live data.

## Helium pairing

Pair this command manually with the existing Helium WOLFHALL snapshot.

Run it immediately after the established Helium snapshot operation. Both use
the same WOLFHALL layout (`/Volumes/Backups/sync/<app>/snapshots/v1/<host>/`),
the same staging -> incoming -> rename -> `READY` publication order, and the
same manual-only v1 rule from the Helium plan (no launchd, no cron). Helium's
own restore path is the dot-b2k7 merge plan, not this tool.
