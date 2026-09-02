```bash
┌┬┐┌─┐┌─┐┌─┐┬ ┬┌┬┐┬ ┬┬┌─┐
│││├┤ │ ┬├─┤│ │ │ ├─┤││
┴ ┴└─┘└─┘┴ ┴┴─┴ ┴ ┴ ┴┴└─┘
@megalithic 🗿
```

<p align="center">

![ghostty + tmux + nvim](https://raw.githubusercontent.com/megalithic/dotfiles/main/assets/megadots_ghostty_tmux_nvim.png "ghostty + tmux + nvim")

![ghostty + tmux + fish + fzf](https://raw.githubusercontent.com/megalithic/dotfiles/main/assets/megadots_ghostty_tmux_fish_fzf.png "ghostty + tmux + fish + fzf")

</p>

## Installation

`bootstrap.sh` is the macOS first-install and migration entry point. Run it in
an interactive terminal on a new machine or when the machine still needs base
setup. Do not run it as root.

Run the current remote script:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/megalithic/dotfiles/HEAD/bootstrap.sh)"
```

Without flags, bootstrap prompts for a hostname and defaults to the current
short hostname. To select a host without the prompt:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/megalithic/dotfiles/HEAD/bootstrap.sh)" -- --host workbookpro
```

From an existing checkout, run:

```bash
cd ~/.dotfiles
sh bootstrap.sh --host "$(hostname -s)"
```

Use `--force` only when bootstrap should overwrite conflicting whole-file
dotfile targets:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/megalithic/dotfiles/HEAD/bootstrap.sh)" -- --force --host workbookpro
```

Bootstrap has no dry-run mode. It changes machine state: it may install Command
Line Tools and Homebrew, install or update standalone mise at
`~/.local/bin/mise`, set the macOS hostname, clone or update `~/.dotfiles`,
apply managed links, install tools/packages/apps, run first-install hooks, set
fish as the login shell, attempt to refresh `mise.lock`, and run final health
checks. If an existing checkout is dirty, the current script stashes its
changes before pulling.

### Host configuration

Bootstrap normalizes the selected hostname, exports it as `MISE_ENV`, and uses
that value while mise loads configuration. After dotfiles are applied, mise
merges this host overlay over the global config:

```text
~/.config/mise/config.toml
~/.config/mise/config.$MISE_ENV.toml
```

The repo sources are `config/mise/config.toml` and
`config/mise/config.{workbookpro,megabookpro}.toml`. Both host overlays select
their SSH configuration. The workbookpro overlay also declares Ansible, Google
Cloud, and OpenTofu; the megabookpro overlay declares AirConnect and its
LaunchAgent. Fish, Bash, and Zsh shell initialization export `MISE_ENV` from
`hostname -s` for later sessions. The bootstrap-backed package, dotfile, and
system update tasks use the same short hostname fallback when `MISE_ENV` is
missing. Confirm the active global and host configuration without installing
missing tools:

```bash
MISE_AUTO_INSTALL=false mise cfg
```

After bootstrap succeeds, fully quit and reopen the terminal so the fish login
shell and host environment take effect. Bootstrap runs a limited
`scripts/mise/check-system` check before exiting; this first pass skips the full
missing-tool check. If it reports failures, restart the terminal and run the
full check:

```bash
mise run doctor
```

A macOS App Management permission failure also requires quitting and reopening
the terminal after granting access, then rerunning bootstrap.

## Machine updates

After initial bootstrap, use the recurring machine updater instead of rerunning
bootstrap:

```bash
mise run up
# Equivalent alias:
mise run dot
```

Both commands mutate machine state during a normal run. To print each phase
without running it, use the updater's supported dry-run mode:

```bash
mise run up -- --dry-run
```

`scripts/mise/update-machine` runs these phases sequentially and stops on the
first failure:

1. `update:tools` - update standalone mise, plugins, and declared tools
2. `update:packages` - apply and upgrade declared system packages
3. `update:dotfiles` - force-apply managed dotfile targets
4. `install:fonts` - install declared Nerd Fonts when inputs changed
5. `update:system` - build signed miccheckd, notiwatchd, and avwatchd binaries,
   configure Helium, apply LaunchAgents, and apply macOS defaults
6. `update:nvim` - update Neovim plugins and Treesitter parsers
7. `update:fnox` - refresh the fnox cache and generated secret artifacts
8. `update:pi` - update Pi settings, tools, and extensions
9. `reload:hammerspoon` - reload Hammerspoon

Task declarations live in `config/mise/config.toml`. Multi-step mise helpers
live in `scripts/mise/`; shared Swift sources and their signed build helper stay
in `lib/`. List current public tasks with:

```bash
mise tasks ls
```

`doctor` and `sync:fantastical` are independent tasks. `up` does not run either
one:

```bash
mise run doctor
mise run sync:fantastical -- --help
```

### Update logs

Each `up` run streams output and creates private timestamped logs under
`~/.local/state/mise/up/`:

```text
<timestamp>.log
<timestamp>.mise-debug.log
latest.log
latest.mise-debug.log
```

The human log records phase results, exit codes, and warnings. Failed runs also
include a bounded failure tail. The mise debug log keeps internal diagnostics
separate. The `latest` links point to the newest run.

---

### 🐉 Thar be dragons

I am pushing updates _constantly_, so there are **NO** guarantees of stability
with my config!

> **Warning**
>
> I highly recommend you dig into the scripts and configs to see what all is
> going on (because it does a lot more than what I'm describing in this README)
> before you -- all willy-nilly, throw caution to the wind -- install a
> stranger's shell scripts. 🤣

---

## ✨ Accoutrements

A few of the _must-have_ tools I roll with:

- [nix](https://search.nixos.org/packages)
  ([home-manager](https://home-manager-options.extranix.com/)/[nix-darwin](https://nix-darwin.github.io/nix-darwin/manual/index.html))
- [ghostty](https://github.com/ghostty-org/ghostty)
- [homebrew](https://brew.sh/)
- [mise](https://github.com/jdx/mise)
- [tmux](https://github.com/tmux/tmux/wiki)
- [fish](https://fishshell.com/)
- [neovim](https://github.com/neovim/neovim)
- [weechat](https://www.weechat.org/)
- `megaforest` for all the colours/themes
- [jetbrains mono](https://www.jetbrains.com/lp/mono/) font
  ([nerd-fonts](https://github.com/ryanoasis/nerd-fonts#font-patcher) patched)
- [hammerspoon](https://github.com/megalithic/dotfiles/tree/main/config/hs)
- [kanata](https://github.com/jtroo/kanata)
- [karabiner-elements](https://github.com/tekezo/Karabiner-Elements)
  ([leeloo ZMK](https://github.com/megalithic/zmk-config))
- [gpg/yubikey/encryption](https://github.com/drduh/YubiKey-Guide)
- `vim`-esque control
  - [surfingkeys (in-browser)](https://github.com/brookhong/Surfingkeys)
  - [homerow (macos-wide)](https://homerow.app)

<p align="center" style="margin-top: 20px; text-align:center; display: flex; align-items: center; justify-content: center;">
  <a href="https://megalithic.io" target="_blank" style="display:block; height:150px;">
    <img src="https://raw.githubusercontent.com/megalithic/dotfiles/main/assets/megadotfiles.png" alt="megadotfiles logo" height="150px" />
  </a>
</p>
