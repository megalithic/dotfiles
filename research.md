# Mise bootstrap migration research

This report reviews remaining `mbm-*` migration tickets, the current parity checklist, custom scripts under `scripts/mise/`, and package-manager alternatives for risky/custom apps. It is based on repository inspection plus focused web research for Brew/MAS/Aqua/Nix-backend availability.

## Executive summary

Several items previously treated as custom-script or Nix-retained candidates have idiomatic package-manager paths:

- **Okta Verify** should be **Brew cask-installed** (`okta-verify`); keep script only as validator. Brew cask uses a `pkg` artifact and uninstall metadata for daemons/plugins.
- **Helium** has a **Homebrew cask** (`helium-browser`), but upstream does **not ship Widevine**; keep script or migrate custom Widevine-patched package to `megalithic/flakes`.
- **Kanata** has a **Homebrew formula** (`kanata`), so binary install can be Brew. The hard part remains TCC, sudoers, launchd, mutable config symlink, and kanata-bar. Best next path: prototype Brew formula + Nix-retained/system script, or `megalithic/flakes` for bundled daemon/bar logic.
- **Brave Nightly** has a **Homebrew cask** (`brave-browser@nightly`) already present in `mise/Brewfile`; remaining gap is wrapper/settings parity, not install source.
- **llama.cpp** has a **Homebrew formula** (`llama.cpp`) that includes `llama-server`; add `brew:llama.cpp` or `brew "llama.cpp"` to remove the current “missing install source” blocker.
- **Handy** has a **Homebrew cask** (`handy`), so custom Nix package can likely be removed.
- **chrome-devtools-mcp** has a **Homebrew formula** and an **npm package**; current mise npm entry is acceptable, Brew is also available.
- **slk** has upstream/Homebrew tap and npm options depending which `slk` package is intended; avoid custom Nix unless custom wrapper is needed.
- **fnox** is idiomatically installed by **mise** per fnox docs; Brew formula exists but mise is recommended.

## Tickets

### Closed migration tickets observed

- `mbm-55qf` — mise dotfile symlink classifier preflight.
- `mbm-qkmx` — dotfile target reconciliation.
- `mbm-8afn` — generated Home Manager fragments ported/decided.
- `mbm-buez` — espanso path/launchd parity.
- `mbm-c3sd` — 1Password validation and git signing fragment correction.
- `mbm-ju5m` — kanata/kanata-bar Nix-retained for v1.
- `mbm-m0rs` — Okta Verify path; needs correction from custom install script to Brew cask + validator.

### Open migration tickets observed

- `mbm-s5i1` — make `mise bootstrap --dry-run` pass.
- `mbm-nhdu` — harden mise scripts for safe repeated runs.
- `mbm-b597` — prototype fnox replacement for OpNix-rendered secrets.
- `mbm-9ov0` — one-command mise bootstrap v1.
- `mbm-xqjv` — parity audit umbrella/checklist.
- `mbm-i2na` — prototype `megalithic/flakes` repo for mise-nix consumption.

## Package/app alternatives and recommendations

| Item                     | Current approach                                                                                                       | Alternative found                                                                                                            | Recommendation                                                                                                                                                                                                                                                                                                   |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Okta Verify              | `scripts/mise/install-okta-verify` check/install script; current script recently trimmed to check-only in working tree | Homebrew cask `okta-verify`; cask uses `pkg "OktaVerify-...pkg"`, has livecheck, uninstall launchctl/pkgutil/delete metadata | Use Brew cask in `mise/Brewfile`; keep `scripts/mise/install-okta-verify` as validation only. Update checklist row from custom privileged script to Brew cask. Source: Homebrew cask definition (`okta-verify.rb`).                                                                                              |
| Helium                   | `scripts/mise/install-helium` downloads DMG, injects Widevine, signs helpers, rsyncs to `/Applications`                | Homebrew cask `helium-browser`; upstream issue says Helium does not have Widevine by default                                 | If Widevine is required, keep custom path but prefer moving this to `megalithic/flakes` or a dedicated Nix package consumed by mise-nix. If Widevine not required, use Brew cask. Sources: Homebrew `helium-browser`, Helium issue #116.                                                                         |
| Kanata                   | Nix-retained due TCC-stable `/usr/local/bin/kanata`, sudoers, launchd, TCP port, Hammerspoon switching                 | Homebrew formula `kanata`; upstream/Homebrew discussion has launchctl examples                                               | Install source can be Brew formula, but system integration remains custom. Re-open design: Brew formula + small privileged integration script may be better than Nix-retained. For kanata-bar, use `megalithic/flakes` or manual pinned app until packaged. Sources: Homebrew `kanata`, kanata discussion #1537. |
| Kanata-bar               | Nix derivation downloads app zip and writes config                                                                     | No clear Brew cask/formula found in this pass                                                                                | Keep with kanata as Nix/flakes-backed package or script. Avoid separating from daemon until daemon strategy settled.                                                                                                                                                                                             |
| Brave Browser Nightly    | Brew cask/manual settings in checklist; `mise/Brewfile` has `brave-browser@nightly`                                    | Homebrew cask `brave-browser@nightly` exists                                                                                 | Install source solved; remaining gap is wrapper/key equivalents/settings sync. Prefer Brew cask + manual/settings-sync deferral. Source: Homebrew `brave-browser@nightly`.                                                                                                                                       |
| llama.cpp / llama-server | `scripts/mise/llama-server-launchd` expects `llama-server` in PATH; checklist says install source missing              | Homebrew formula `llama.cpp` includes CLI and server                                                                         | Add `brew:llama.cpp` to `mise.toml` bootstrap packages or `brew "llama.cpp"` to Brewfile, then validate `command -v llama-server`. Source: Homebrew `llama.cpp`, upstream docs.                                                                                                                                  |
| Handy                    | Custom Nix package listed in custom app backlog                                                                        | Homebrew cask `handy` exists                                                                                                 | Move to Brew cask unless custom Nix wrapper provides needed behavior. Source: Homebrew `handy`.                                                                                                                                                                                                                  |
| Tidewave / tidewave-cli  | Custom Nix package listed                                                                                              | Upstream releases/macOS app downloads and CLI binary; no Brew result found                                                   | Prefer `megalithic/flakes` for now, or a focused installer if upstream stable URLs/hashes are easy. Re-check Homebrew later.                                                                                                                                                                                     |
| chrome-devtools-mcp      | `mise.toml` currently has `npm:chrome-devtools-mcp`; custom Nix package also mentioned                                 | Homebrew formula and npm package exist                                                                                       | Current npm via mise is okay. Brew formula is also viable if preferring one package manager. Remove custom Nix package after validation. Sources: npm and Homebrew formula.                                                                                                                                      |
| slk                      | Custom Nix package / generated config retained                                                                         | Upstream Homebrew tap (`howar31/tap/slk`) and npm (`@howar31/slk`) found; another `slk` project also exists                  | Identify intended `slk` upstream. If howar31 agent-facing Slack CLI, use Brew tap or npm; if another slk, document source first.                                                                                                                                                                                 |
| plannotator              | `scripts/mise/install-pi-tools` downloads pinned binary                                                                | Official installer `curl -fsSL https://plannotator.ai/install.sh                                                             | bash`; plugin marketplace also exists                                                                                                                                                                                                                                                                            | Keep custom downloader if pinning is required. Otherwise use upstream installer or package via `megalithic/flakes` for reproducibility. |
| sesame                   | `scripts/mise/install-pi-tools` downloads pinned GitHub binary                                                         | GitHub releases and npm package family indicated; no Homebrew formula found                                                  | Prefer npm/mise if `@aliou/sesame-cli` is stable; otherwise keep pinned downloader or package in `megalithic/flakes`.                                                                                                                                                                                            |
| fnox                     | mise tool entry `fnox = "latest"`; render script for legacy files                                                      | fnox docs recommend mise; Brew formula also exists                                                                           | Keep mise tool. Script still needed for legacy output files until consumers migrate to fnox directly. Sources: fnox docs, Homebrew `fnox`.                                                                                                                                                                       |
| Determinate Nix          | `scripts/mise/ensure-determinate-nix` official curl installer                                                          | Determinate docs recommend official installer; no better Brew path needed                                                    | Keep script. It is bootstrap infrastructure, not an app package.                                                                                                                                                                                                                                                 |
| Pi coding agent          | npm via mise plus `setup-pi` symlinks and wrappers                                                                     | npm package already used                                                                                                     | Keep npm via mise; reduce custom script to linking local extensions/skills/settings only.                                                                                                                                                                                                                        |

## Custom script catalog

| Script                         | Purpose                                   | Replaceable by package manager?                      | Recommendation                                                                                    |
| ------------------------------ | ----------------------------------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `apply-macos-complex-defaults` | macOS defaults not represented in mise    | No                                                   | Keep, but harden; avoid broad `killall` in dry-run.                                               |
| `bootstrap-final`              | Orchestrates setup tasks                  | No                                                   | Keep but gate mutations and add dry-run/report mode.                                              |
| `doctor`                       | Checks prerequisites/state                | No                                                   | Keep. Add package-manager availability checks before scripts.                                     |
| `dotfile-preflight`            | Symlink classifier                        | No                                                   | Keep. It is core safety guard.                                                                    |
| `ensure-determinate-nix`       | Official Determinate Nix installer/repair | No Brew replacement needed                           | Keep. Report, do not reinstall over non-Determinate Nix without approval.                         |
| `ensure-homebrew`              | Homebrew installer                        | No                                                   | Keep. Standard bootstrap path.                                                                    |
| `install-apps`                 | `brew bundle` wrapper                     | Already idiomatic                                    | Keep wrapper; consider `brew bundle check` before install.                                        |
| `install-helium`               | Custom Widevine/signing install           | Partially: Brew cask exists but lacks Widevine       | Prefer `megalithic/flakes` for custom Widevine package, or keep script only if Widevine required. |
| `install-okta-verify`          | Validator after switch to Brew cask       | Install replaced by Brew cask                        | Keep check-only validator; update docs/ticket to remove custom install framing.                   |
| `install-pi-tools`             | Downloads sesame/plannotator binaries     | Partially: plannotator installer, sesame release/npm | Re-evaluate; replace with npm/mise or flakes where possible.                                      |
| `llama-server-launchd`         | Launchd wrapper for llama-server          | Install source solved by Brew formula                | Keep service wrapper; add Brew formula `llama.cpp`.                                               |
| `pi-session-indexer`           | Pi session indexer shim                   | No direct package replacement                        | Keep if tied to local repo scripts.                                                               |
| `render-fnox-files`            | Render fnox secrets to legacy files       | No                                                   | Keep until callers consume fnox directly. Add check/dry-run mode.                                 |
| `sesame-session-indexer`       | Sesame indexer launchd wrapper            | Package may be npm/release                           | Keep wrapper; replace binary source if possible.                                                  |
| `setup-pi`                     | Link Pi extensions/skills/settings        | No                                                   | Keep; this is dotfiles repo integration, not package install.                                     |

## Priority order for remaining work

1. **Correct Okta docs/ticket state after Brew cask discovery.** Ensure checklist and ticket say “Brew cask + check-only validator,” not “custom installer.” This avoids repeating the same error.
2. **`mbm-s5i1`: make dry-run pass.** Validate Brew identifiers (`yubikey-manager` issue, `llama.cpp`, `okta-verify`, `handy`, possible `kanata`) and mise schema now that package-manager choices changed.
3. **`mbm-i2na`: prototype `megalithic/flakes`.** Use it for Helium Widevine, kanata-bar, Tidewave, and other bespoke packages that do not have adequate Brew/Aqua/npm support.
4. **`mbm-b597`: fnox prototype.** Remaining secrets/token bootstrap blocks clean doctor output and Pi/Helium notarization paths.
5. **`mbm-nhdu`: harden scripts.** After package-manager cleanup, scripts should be fewer and easier to harden.
6. **`mbm-9ov0`: one-command bootstrap.** Only after dry-run, fnox, and script hardening are solid.
7. **Close/update `mbm-xqjv` audit umbrella** once checklist reflects package-manager corrections and blockers are resolved or explicitly deferred.

## Sources checked

- Homebrew cask `okta-verify` raw definition: `https://raw.githubusercontent.com/Homebrew/homebrew-cask/HEAD/Casks/o/okta-verify.rb`
- Homebrew cask `helium-browser`: `https://formulae.brew.sh/cask/helium-browser`
- Helium Widevine issue: `https://github.com/imputnet/helium/issues/116`
- Homebrew formula `kanata`: `https://formulae.brew.sh/formula/kanata`
- Kanata Homebrew/launchctl discussion: `https://github.com/jtroo/kanata/discussions/1537`
- Homebrew cask `brave-browser@nightly`: `https://formulae.brew.sh/cask/brave-browser@nightly`
- Homebrew formula `llama.cpp`: `https://formulae.brew.sh/formula/llama.cpp`
- Homebrew cask `handy`: `https://formulae.brew.sh/cask/handy`
- Homebrew formula `chrome-devtools-mcp`: `https://formulae.brew.sh/formula/chrome-devtools-mcp`
- npm `chrome-devtools-mcp`: `https://www.npmjs.com/package/chrome-devtools-mcp`
- fnox mise integration: `https://fnox.jdx.dev/guide/mise-integration.html`
- Homebrew formula `fnox`: `https://formulae.brew.sh/formula/fnox`
- Determinate Nix installer docs: `https://github.com/DeterminateSystems/nix-installer`
- `jbadeau/mise-nix` flake support from prior research: `https://github.com/jbadeau/mise-nix`

## Review notes

- I could not run `lat_search` because this delegated environment exposed only read/write/web research tools. I read the relevant `lat.md` files directly.
- I did not run shell commands or mutate project code besides writing this report.
- `lat.md/migration/mise-parity-checklist.md` currently still contains stale Okta wording in the checked-in text read here: it says “privileged pkg installer script” and pinned `9.63.0`, while `mise/Brewfile` already includes `cask "okta-verify"` and `scripts/mise/install-okta-verify` is check-only. Parent should update checklist/ticket before committing the Okta correction.

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "Created only research.md with the requested migration research report; no implementation changes made."
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "Report lists open/closed tickets, checklist status, custom script catalog, Brew/MAS/Aqua/Nix alternatives with source URLs, recommendations, priority order, and residual risks."
    }
  ],
  "changedFiles": [
    "research.md"
  ],
  "testsAddedOrUpdated": [],
  "commandsRun": [
    {
      "command": "functions.read .tickets/mbm-*.md (known ticket files)",
      "result": "passed",
      "summary": "Read open and relevant closed migration tickets to classify completed vs remaining work."
    },
    {
      "command": "functions.read lat.md/migration/mise-parity-checklist.md",
      "result": "passed",
      "summary": "Read parity checklist and current status rows."
    },
    {
      "command": "functions.read scripts/mise/* (known script files)",
      "result": "passed",
      "summary": "Cataloged custom scripts and assessed replacement possibilities."
    },
    {
      "command": "functions.web_search package-manager availability queries",
      "result": "passed",
      "summary": "Researched Brew casks/formulae, npm packages, fnox docs, and Determinate Nix docs for target items."
    },
    {
      "command": "functions.write research.md",
      "result": "passed",
      "summary": "Wrote final report to requested path."
    }
  ],
  "validationOutput": [
    "No executable tests were run; task was research-only.",
    "Report written to /Users/seth/.dotfiles/.worktrees/mise-bootstrap-migration/research.md."
  ],
  "residualRisks": [
    "Could not run lat_search because delegated toolset did not expose it; read lat files directly instead.",
    "Could not run git status, so no-staged-files is inferred from no staging tool use rather than verified by command.",
    "Some package alternatives, especially Tidewave and kanata-bar, need follow-up source-specific validation before implementation."
  ],
  "noStagedFiles": true,
  "notes": "Main correction: Okta Verify should be Brew cask-installed; custom script should remain validation-only. Next work should clean stale Okta checklist/ticket wording, then run mbm-s5i1 dry-run validation."
}
```
