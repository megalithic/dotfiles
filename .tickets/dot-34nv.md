---
id: dot-34nv
status: closed
deps: []
links: []
created: 2026-09-01T13:46:12Z
type: bug
priority: 1
assignee: Seth Messer
tags: [notiwatchd, macos, tcc, codesign]
---
# Keep notiwatchd TCC grants across rebuilds

Replace ad-hoc signing with a stable self-signed code-signing identity so Full Disk Access and Accessibility grants survive notiwatchd rebuilds. Evaluate a disposable signing sandbox, including macOS VM and cross-platform rcodesign/apple-codesign, with signing material sourced from fnox/1Password without exposing secrets. Integrate the chosen flow with mise/config/notiwatchd/notiwatchd-build.

## Design

Prefer the smallest secure flow. Existing mise/tasks/kanata-setup already creates and trusts a local self-signed code-signing certificate and may be reusable. Sandbox must avoid persistent private-key copies outside the encrypted vault and must produce a stable designated requirement.

## Acceptance Criteria

1. Rebuilt notiwatchd has the same stable designated requirement across builds.
2. Existing FDA and Accessibility grants continue working after rebuild and launchd restart.
3. Signing key/certificate lifecycle and fnox/1Password references are documented without secret values.
4. notiwatchd-build fails clearly or uses an explicit documented fallback when identity is unavailable.
5. Sandbox feasibility decision and threat-model tradeoffs are recorded.

## Notes

### 2026-09-01T13:51:24Z

Investigation 2026-09-01: host has no Docker, Podman, Tart, UTM CLI, or rcodesign installed. Linux rcodesign can sign an already-built Mach-O from a P12, but compilation and final codesign/TCC validation remain on macOS. A disposable macOS VM preserves Apple tool semantics but adds large VM/tooling overhead and cannot transfer guest TCC grants. Smallest hermetic option is a temporary macOS keychain: fetch a stable P12/password from fnox/1Password, import into the temporary keychain, sign with Apple codesign, verify, then destroy the keychain. Current tracked vault refs expose Apple ID email, team ID, and notarytool app password only; no P12/private-key reference exists. Direct vault metadata inspection was blocked because op reports account is not signed in; fnox cache still resolves APPLE_TEAM_ID. Local prototype signed different binaries with the existing Kanata self-signed code-sign identity and fixed com.megadots.notiwatchd identifier: CDHashes differed while designated requirements matched, including hardened-runtime signing with --timestamp=none. Recommendation: reuse or replace that identity with a generic local code-sign identity before adding VM/container machinery; validate FDA and Accessibility persistence on Tahoe.

### 2026-09-01T14:48:25Z

TCC recovery observation: toggling stale FDA/Accessibility entries off/on did not update the ad-hoc requirement. Removing both entries and re-adding ~/.dotfiles/bin/notiwatchd restored FDA; launchd started at 14:40:44Z and resumed reading notifications. Accessibility was re-added but still needs a live dismiss event to verify.

**2026-09-01T19:50:35Z**

Resolved with the real Developer ID Application identity (3ZJ3F5RFBZ) instead of a new self-signed cert. Exported from megabookpro via Keychain Access GUI (CLI security export of private keys hard-fails over SSH: SecKeychainItemExport interaction-not-allowed even after unlock + set-key-partition-list), imported to workbookpro login keychain plus Apple DeveloperIDG2CA intermediate. Backup: .p12 + passphrase in 1Password Crypt > apple-developer > Code Signing (no secret values in repo). notiwatchd-build already preferred Developer ID and keeps documented ad-hoc fallback. New bin/signcode generalizes the flow for future binaries. AC validation: rebuilt + kickstarted, FDA read resumed (high-water anchor), Accessibility confirmed by live dismiss of two BTM alerts with verified ok via new retry/verify loop; TCC.db shows both services auth_value=2 pinned to the stable requirement. Sandbox evaluation: unnecessary once a durable identity existed in the keychain; decision recorded in lieu of VM/rcodesign work.
