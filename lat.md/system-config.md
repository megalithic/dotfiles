# System configuration (nix-darwin)

This file covers the nix-darwin layer: shared host settings, per-host overrides, Homebrew, Mac App Store, and the darwin modules. Apply with `just darwin`.

## Host layout

`hosts/common.nix` holds settings shared by every host; `hosts/megabookpro.nix` and `hosts/workbookpro.nix` carry per-host overrides. The builder passes `username`, `hostname`, `paths`, and `arch` through special args.

`hosts/common.nix` sets system fonts, the `seth` user (uid 501, fish shell), hostname, timezone (`America/New_York`), and locale (`en_US.UTF-8`). It defines system-wide `environment.variables` including editor (`nvim-nightly`), pager, XDG paths, project paths (`CODE`, `DOTS`), cloud-storage paths, tmux layout paths, and FZF defaults, plus a minimal `environment.systemPackages` set.

Bootstrap-critical packages stay in `hosts/common.nix` `environment.systemPackages` because they are needed before Home Manager runs: `just`, `git`, `curl`, `vim`, plus core archive and nix tooling.

## Determinate Nix integration

`nix.enable = false` because Determinate Nix owns `/etc/nix/nix.conf`.

The repo generates `/etc/nix/nix.custom.conf` declaratively (trusted users, extra substituters, `keep-derivations`, `keep-outputs`, `warn-dirty = false`), which Determinate's config includes.

`environment.systemPath` explicitly adds `/nix/var/nix/profiles/system/sw/bin` and `/opt/homebrew/bin` because Determinate Nix does not create the `/run/current-system` symlink.

System programs enabled in common include `bash`, `fish` (with babelfish), and `gnupg.agent` with SSH support. `services.tailscale.enable = true`. The SSH auth socket points at 1Password's agent through `environment.extraInit`.

## Homebrew and Mac App Store

Homebrew is the last-resort path for casks and apps that resist Nix packaging. `nix-homebrew` is configured in the flake `brew_config` with Rosetta enabled, auto-migrate on, immutable taps, and the four Homebrew taps wired from flake inputs.

`modules/brew.nix` declares Homebrew casks and `homebrew.masApps` for Mac App Store apps. `brew-nix` provides a cask overlay used for `mas` packaging.

The staged mise bootstrap mirrors this through `_mise.toml` `[bootstrap.packages]`: Homebrew entries use `brew:`/`brew-cask:` prefixes, and Mac App Store apps use `mas:<app id>` entries such as Fantastical (`mas:975937182`).

## Darwin modules

`modules/` holds the nix-darwin modules. Custom kanata support also comes from the `kanata-darwin` flake input.

`system.nix` covers core system settings, `brew.nix` covers Homebrew, and `darwin/` holds `kanata.nix`, `services.nix`, `spotlight.nix`, `_1password.nix`, and `okta-verify.nix`.

## Kanata on macOS

Kanata needs Karabiner DriverKit VirtualHIDDevice on macOS; installing only `kanata` and `kanata-bar` is not enough.

The nix path keeps using the `kanata-darwin` flake plus `modules/darwin/kanata.nix`. It installs and activates the Karabiner DriverKit package, runs the VirtualHID daemon, copies kanata to stable `/usr/local/bin/kanata`, starts kanata as a launchd user agent through sudo, and runs kanata-bar as a UI client.

The staged mise path mirrors that design without changing the nix modules. `_mise.toml` installs `kanata` through Homebrew bootstrap packages and `kanata-bar` through mise's `http:` backend (pinned version + sha256), links the `.kbd` profiles and layer icons, declares mise-managed launchd agents, and runs `mise/scripts/kanata-setup` from the `post-tools` bootstrap hook for privileged macOS glue. That script installs/activates the Karabiner VirtualHID `.pkg`, writes the system VirtualHID LaunchDaemon, copies Homebrew's kanata to stable `/usr/local/bin/kanata`, writes the sudoers entry, writes `~/.config/kanata-bar/config.toml`, warns when nix-managed kanata agents are still loaded, and only moves stale `org.nixos.*` helper LaunchDaemons aside when they point at missing Nix store paths.

The launchd agents run through `mise/scripts/kanata-launchd` and `mise/scripts/kanata-bar-launchd` wrapper scripts because mise expands `~` only in launchd `program`/`stdout_path`/`stderr_path`, never in `args`; the kanata-bar wrapper also resolves the versioned `http:kanata-bar` install path so `[tools]` version bumps need no agent edits. mise prefixes bootstrap launchd labels with `dev.mise.`, so the live agents are `dev.mise.org.kanata.daemon` and `dev.mise.com.kanata-bar.ui`.

Both `config/kanata/macbook.kbd` and `config/kanata/macbook-disabled.kbd` are scoped to `"Apple Internal Keyboard / Trackpad"`; external Leeloo/ZMK state only selects which internal-keyboard profile is active.

## 1Password (GUI + CLI)

`modules/darwin/_1password.nix` enables the GUI and CLI via nix-darwin **system** options; there is no Home Manager equivalent.

It sets `programs._1password.enable = true` and `programs._1password-gui.enable = true`. The GUI module rsyncs `pkgs._1password-gui` to `/Applications/1Password.app` as `root:wheel r-xr-xr-x`; the CLI module installs `op` to `/usr/local/bin/op`. `nixpkgs.config.allowUnfree = true` in `hosts/common.nix` is required at the system level (the flake's `pkgs` already had it, but system nixpkgs did not).

For the staged mise migration, `_mise.toml` replaces this module with the `1password` brew cask (`[bootstrap.packages]`) plus `1password-cli` installed through the `post-packages` bootstrap hook via real brew (mise's brew-cask backend handles app-bundle-only casks, and that cask ships a `binary` artifact), and links `~/.config/1Password/ssh/agent.toml` from `mise/config/1password/agent.toml`.

The GUI **must** live in `/Applications` — 1Password's anti-tamper logic quits the app when launched from `~/Applications/Home Manager Apps/` or the nix store. So unlike Hammerspoon/Raycast/ProtonVPN (Home Manager `copyApps` into `~/Applications/Home Manager Apps/`), 1Password is a system module. Git and jj SSH signing point at `/Applications/1Password.app/Contents/MacOS/op-ssh-sign` (the full GUI bundle ships `op-ssh-sign`); do not point them at the Home Manager Apps path.

### "1Password.app is damaged" gotcha (first-launch Gatekeeper false positive)

After migrating the GUI from a Homebrew cask to this module, macOS may throw **"1Password.app is damaged and can't be opened"** on first GUI launch. The bundle is NOT damaged — do not trash it (that deletes the working nix copy; click Cancel).

All checks pass: `codesign --verify` valid, `spctl -a -vvv` accepted (Notarized Developer ID, AgileBits `2BUA8C4S2C`), `xcrun stapler validate` confirms the notarization ticket is stapled, and there is no `com.apple.quarantine` xattr.

Root cause: replacing the bundle **in place** at `/Applications/1Password.app` (brew uninstall → nix-darwin rsync) makes Gatekeeper's first-launch GUI scan re-fire against the known path. `syspolicyd` logs `GK evaluateScanResult: 3` → `Prompt shown`, keyed on the `com.apple.provenance` xattr (which the system re-applies after `xattr -cr`). `sudo spctl --add` no longer works ("operation is no longer supported"), and `lsregister -f` / clearing xattrs do not stick.

**Fix:** after the dialog, open **System Settings → Privacy & Security**, scroll to the Security section, and click **Open Anyway** for 1Password, then authenticate. This writes the user-consent override that the brew install used to carry. Verified working: app stays running across quit/relaunch with no further prompt.

## Okta Verify (privileged .pkg installer)

`modules/darwin/okta-verify.nix` installs Okta Verify by running Apple's own installer during activation, because it is not a plain `.app`.

Okta Verify's `.pkg` has an `auth="root"` postinstall that loads LaunchDaemons (`com.okta.authentication.service`, `autoupdate.daemon`, `deviceaccess.servicedaemon`), installs a SecurityAgentPlugin bundle, and drops `/usr/local/bin/AutoUpdateDaemon`. `mkApp`/`brewCasks`/`brew-nix` only extract the `.app` and never run that postinstall, so device-access auth breaks; `mas` needs interactive auth.

The module pins the official `.pkg` in the nix store via `pkgs.fetchurl` (version/build/sha256 taken from the Homebrew cask `okta-verify.rb`), then a `system.activationScripts.postActivation` block runs `/usr/sbin/installer -pkg <store-path> -target /` as root so the real postinstall executes. It is idempotent on the `com.okta.mobile` pkgutil receipt version: same version → skip. No Homebrew, no `modules/brew.nix`. Bump version/build/sha256 in the module when the cask updates. `home/common/programs/okta-verify/default.nix` is now just a post-`just home` presence-check warning.

Migration note: if the old Homebrew cask is still installed at the same version, the activation check sees a matching receipt and skips. To switch fully to the nix-managed install, `brew uninstall --cask okta-verify` first, then `just darwin` reinstalls from the pinned pkg.

## Spotlight exclusions

`spotlight.exclusions` (from `modules/darwin/spotlight.nix`) prevents Spotlight from indexing build artifacts, dependencies, and devenv state.

It seeds exclusion patterns from `home/common/programs/git/gitignore` plus explicit paths such as `node_modules`, `.devenv`, `.direnv`, `_build`, `deps`, and Elixir tool caches, scanning under `~/code`. Hosts can extend it via `spotlight.exclusions.paths` and `scanPaths`.
