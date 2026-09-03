```bash
┌┬┐┌─┐┌─┐┌─┐┬ ┬┌┬┐┬ ┬┬┌─┐
│││├┤ │ ┬├─┤│ │ │ ├─┤││
┴ ┴└─┘└─┘┴ ┴┴─┴ ┴ ┴ ┴┴└─┘
@megalithic 🗿
```

<p align="center">

![ghostty + tmux + nvim](https://raw.githubusercontent.com/megalithic/dotfiles/main/assets/megadots_ghostty_tmux_nvim.png 'ghostty + tmux + nvim')

![ghostty + tmux + fish + fzf](https://raw.githubusercontent.com/megalithic/dotfiles/main/assets/megadots_ghostty_tmux_fish_fzf.png 'ghostty + tmux + fish + fzf')

</p>

## Installation

`bootstrap.sh` is the MacOS first-install and migration entry point. Run it in
an interactive terminal on a new machine or when the machine still needs base
setup. Do not run it as root.

Run the current remote script:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/megalithic/dotfiles/HEAD/bootstrap.sh)"
```

Without flags, bootstrap prompts for a hostname and defaults to the current
short hostname. To select a host without the prompt:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/megalithic/dotfiles/HEAD/bootstrap.sh)" -- --host myhostname
```

From an existing checkout, run:

```bash
cd ~/.dotfiles
sh bootstrap.sh --host "$(hostname -s)"
```

Use `--force` only when bootstrap should overwrite conflicting whole-file
dotfile targets:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/megalithic/dotfiles/HEAD/bootstrap.sh)" -- --force --host myhostname
```

Bootstrap has no dry-run mode. It changes machine state: it may install Command
Line Tools and Homebrew, install or update standalone mise at
`~/.local/bin/mise`, set the MacOS hostname, clone or update `~/.dotfiles`,
apply managed links, install tools/packages/apps, run first-install hooks, set
fish as the login shell, attempt to refresh `mise.lock`, and run final health
checks. If an existing checkout is dirty, the current script stashes its
changes before pulling.

### Host configuration

Bootstrap normalizes the selected hostname, exports it as `MISE_ENV`, and uses
that value while mise loads configuration. After dotfiles are applied, mise
merges this host "overlay" over the global config:

```text
~/.config/mise/config.toml
~/.config/mise/config.$MISE_ENV.toml
```

Confirm the active global and host configuration without installing missing tools:

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

A MacOS App Management permission failure also requires quitting and reopening
the terminal after granting access, then rerunning bootstrap.

## Machine updates

After initial bootstrap, use the recurring machine updater instead of rerunning
bootstrap:

```bash
mise run up
```

Normal runs mutate machine state and stream each phase directly to the terminal.
To print each phase without running it, use the updater's dry-run mode:

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
   configure Helium, apply LaunchAgents, and apply MacOS defaults
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

- [mise](https://mise.jdx.dev)
- [ghostty](https://github.com/ghostty-org/ghostty)
- [tmux](https://github.com/tmux/tmux/wiki)
- [fish](https://fishshell.com/)
- [neovim](https://github.com/neovim/neovim)
- `megaforest` for all the colours/themes
- [jetbrains mono](https://www.jetbrains.com/lp/mono/) font
- [hammerspoon](https://github.com/megalithic/dotfiles/tree/main/config/hs)
- [kanata](https://github.com/jtroo/kanata) ([Leeloo v1.13/ZMK](https://github.com/megalithic/zmk-config))

<p align="center" style="margin-top: 20px; text-align:center; display: flex; align-items: center; justify-content: center;">
  <a href="https://megalithic.io" target="_blank" style="display:block; height:150px;">
    <img src="https://raw.githubusercontent.com/megalithic/dotfiles/main/assets/megadotfiles.png" alt="megadotfiles logo" height="150px" />
  </a>
</p>
