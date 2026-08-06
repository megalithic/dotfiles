# appbak

`bin/appbak` is a single-file bash CLI that discovers a macOS app's on-disk data and selectively backs it up with retention, a JSON manifest, and keychain metadata capture.

Discovery covers Application Support, Preferences, Containers, Group Containers, and Caches.

Requires bash >= 4.4 (empty-array expansion under `set -u`). Toolchain is mise-managed (gum, jq, age); no nix references. BSD-flag-dependent commands are pinned to absolute paths (`/usr/bin/stat`, `/bin/date` — note `/usr/bin/date` does not exist on macOS) because GNU coreutils from `~/.nix-profile` shadow BSD tools on PATH.

## Backup layout and manifest

Snapshots mirror absolute source paths: `<dest>/<hostname -s>/<AppName>/<YYYYMMDDHHMMSS>/<abs source path>`, copied with `ditto`.

Each snapshot also contains `backup-manifest.json`; the primary manifest lives outside the dest (default `~/.local/share/appbak/manifest.json`, override `APPBAK_MANIFEST`).

Per-app manifest entries record `discovered[]` (with apparent size, du display size, real ISO-8601 mtime), `selected`, `backed_up`, `keychain_items`, `last_backup`, `last_backup_status`, and `app_was_running`. Empty selections serialize as `[]`, never `[""]`. A corrupt manifest is refused without truncation. Every flag has an `APPBAK_*` env twin; flags win over env.

## Verify-before-prune invariant

A bad or partial new snapshot must never evict a good older one: retention pruning runs only after the new snapshot passes verification.

The pruner (`rm -rf` to 2 newest) is guarded by a `^[0-9]{14}$` basename filter plus a dirname re-check immediately before each removal.

Every copy-critical command (`mkdir`, `ditto`, the backup-manifest write) is explicitly `if !`-checked into a `copy_failed` latch — `set -e` is inert in this call chain, so nothing relies on errexit. After copying, the snapshot is verified by recursive apparent-size (`stat -f '%z'`, regular files only, symlinks excluded identically on both sides) plus file-count comparison against the source at copy time. `du` block counts are used only for display: block allocation legitimately differs across filesystems and falsely failed byte-identical copies.

Status vocabulary and consequences:

- `complete` — verified; prune runs; manifest stamped.
- `possibly_incomplete` — app was running (or verify mismatch while running); prune skipped; manifest stamped; exit 0.
- `partial` — some selected sources vanished but the rest copied and verified; prune skipped; manifest stamped with the reduced `backed_up`; exit 0.
- `failed` — copy/verify/mkdir failure, or all sources vanished; no prune, no manifest stamp, exit non-zero.

A prune failure after a successful backup is logged (`prune failed (backup itself succeeded)`) but does not fail the run or block the manifest update. Empty selections and zero-byte-only discoveries persist to the manifest without stamping `last_backup`; previously zero-byte items are re-stated on later runs and picked up when they grow.

## Keychain handling

Default is metadata-only: matching keychain item names are listed in `keychain-items.txt` inside the snapshot — no secrets leave the keychain.

`--keychain-export age` optionally encrypts secret values with an age recipient (plaintext staged only in a 0600 mktemp with cleanup trap, refused when TMPDIR is inside the dest). The age path ships in v1 but is unexercised by live tests.

## v1 scope cuts

Two planned features were removed after three defect rounds rather than shipped broken; the plan file (`~/.local/share/pi/plans/dotfiles/app-backup-cli.md`) still describes them but they are intentionally out of scope for v1:

- AI fallback discovery (`--ai`, `--ai-timeout`, local llama-server / `pi -p` secondary): never demonstrable end-to-end on this host.
- `--keychain-export op` (1Password vault export, `--op-vault`): also removed the secret-in-argv exposure. Valid modes are now `off|age`.

## Known accepted tradeoffs

Fail-safe residuals accepted for v1, from the round-4 review.

- A permanently vanished selected path keeps status `partial` forever and freezes retention for that app until re-`--discover`.
- Failed snapshot husks are never cleaned up and consume retention slots.
- Running-app detection is pgrep-by-display-name; mismatched process names hard-fail verification instead of soft-failing.
- An age export failure leaves the backup `complete` with only a stderr log.
