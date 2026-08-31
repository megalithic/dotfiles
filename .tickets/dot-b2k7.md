---
id: dot-b2k7
status: in_progress
deps: []
links: [dot-aq4a]
created: 2026-08-31T16:06:27Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-wo6i
tags: [ready-for-development, browser, helium, migration]
---

# Merge megabookpro Helium data into workbookpro

Merge browsing data from megabookpro's Helium profile into workbookpro's existing Helium profile. Preserve bookmarks, history, and open tabs from both machines. Do not replace workbookpro's profile or copy machine-bound secrets.

This task is a one-time migration under `dot-wo6i`. It complements `dot-aq4a`, which tracks the earlier Brave Nightly-to-Helium migration.

## Current inventory

- Both machines run Helium with Chromium `150.0.7871.46`.
- megabookpro profile: about 2 GB, 1,056 bookmark URLs, 12,492 history URLs, 146,573 visits, and six session files.
- workbookpro profile: about 444 MB. Bookmark, history, and session counts still need a read-only inventory.
- Helium has no built-in account sync. Profile files live under `~/Library/Application Support/net.imput.helium/`.

## Relevant paths

- `~/Library/Application Support/net.imput.helium/Default/Bookmarks`
- `~/Library/Application Support/net.imput.helium/Default/History`
- `~/Library/Application Support/net.imput.helium/Default/Sessions/`
- `bin/helium-launch` - starts Helium with CDP on port 9223
- `mise/tasks/setup-helium` - manages extensions and defaults but deliberately avoids profile JSON
- `lat.md/programs/helium.md` - Helium profile and launch constraints
- `.local_scripts/` - temporary migration scripts only; do not commit browser data

## Plan

1. Inventory workbookpro
   - Record bookmark URL/folder counts, history URL/visit counts, session files, Helium version, and free disk space.
   - Record enough aggregate data to verify the merge without printing private URLs.

2. Capture megabookpro open tabs
   - While Helium runs through `bin/helium-launch`, query CDP on port 9223.
   - Save normal page URLs and titles to a mode-0600 temporary manifest. Preserve duplicate URLs and tab order when CDP exposes it.
   - Exclude extension pages, DevTools, new-tab pages, private windows, form state, and back/forward stacks. Note these limits before migration.

3. Stop and back up
   - Quit Helium cleanly on both machines and verify all Helium processes exited.
   - Create a timestamped, restorable backup of workbookpro's full `net.imput.helium` support directory before changing it.
   - Copy source files to a staging directory instead of editing either live profile.

4. Merge bookmarks safely
   - Prefer Helium's native HTML export/import path so Chromium recalculates the `Bookmarks` checksum.
   - Import megabookpro bookmarks into a dated migration folder on workbookpro.
   - Remove only exact duplicate URL entries. Preserve source folder structure and all workbookpro bookmarks.
   - Do not rewrite `Secure Preferences`.

5. Merge history transactionally
   - Compare both `History` SQLite schemas and `PRAGMA user_version` values before merging.
   - Start from workbookpro's database. Merge source `urls` rows by URL, remap source URL IDs, then insert source `visits` and related `visit_source` rows with remapped IDs.
   - Preserve visit timestamps and workbookpro row IDs. Run the merge in one transaction against a staged database.
   - Require `PRAGMA integrity_check` to return `ok` before atomically replacing workbookpro's `History` file.
   - Stop and restore the backup if schemas differ or any integrity check fails.

6. Restore tabs without replacing workbookpro sessions
   - Leave workbookpro's `Sessions/` files untouched so its current windows and tabs restore normally.
   - Reopen megabookpro URLs from the manifest in a separate workbookpro Helium window.
   - Keep the manifest until the user verifies the restored tabs, then move it to Trash.

7. Preserve machine-local state
   - Do not copy `Cookies`, `Login Data`, `Local State`, `Secure Preferences`, extension state, caches, or Keychain records.
   - Keep workbookpro's existing extensions and preferences.

8. Verify and document
   - Launch workbookpro Helium and check bookmarks, history searches across old and recent dates, existing tabs, imported tabs, extensions, and profile startup.
   - Record before/after aggregate counts and backup/restore path in this ticket.
   - Use `.local_scripts/` for disposable tooling. If reusable tracked tooling is added, update `lat.md/programs/helium.md` and run `lat check`.

## Acceptance criteria

1. A timestamped workbookpro profile backup exists, and this ticket records its restore command.
2. workbookpro retains its bookmarks and gains megabookpro's bookmarks with folder structure preserved; only exact duplicate URL entries are removed.
3. workbookpro's merged `History` database returns `ok` from `PRAGMA integrity_check`, and its visit count matches the recorded preflight total from both profiles.
4. History searches on workbookpro find verified sample visits from each machine across old and recent dates.
5. workbookpro's existing session restores, and every captured megabookpro tab URL is restored or listed as an explicit exception.
6. workbookpro retains its extensions and preferences. No cookies, saved logins, Keychain records, `Local State`, or `Secure Preferences` move between machines.
7. Helium starts without profile-reset, corruption, or SQLite errors after the merge.
8. No browser data, URL manifests, profile backups, or secrets are committed to this repository.

## Notes

### 2026-08-31T18:41:41Z

First verified megabookpro snapshot captured after restart and clean Helium quit. Snapshot ID: 20260831T180725Z-cc4cdab1d860. WOLFHALL path: /Volumes/Backups/sync/helium/snapshots/v1/megabookpro/20260831T180725Z-cc4cdab1d860/. Local staged copy: ~/.local/share/helium-merge/staging/snapshots/v1/megabookpro/20260831T180725Z-cc4cdab1d860/. Inventory: 1,056 bookmark URLs, 21 folders, 12,482 history URLs, 146,524 visits, 5 session files, 108 open tabs in 1 window, saved tab groups present. All 12 checksums verified on NAS; staged History PRAGMA integrity_check returned ok; READY written last. No Helium profile was modified and no excluded credential/site-state files were copied.
