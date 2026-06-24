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

## 🚀 Installation (automagic)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/megalithic/dotfiles/HEAD/scripts/install.sh)"
```

## 🚀 Installation (manual)

## Getting Started

Paste into Terminal.app on a fresh or partially-configured Mac:

```bash
curl -sSfL https://raw.githubusercontent.com/megalithic/dotfiles/main/scripts/install.sh | bash
```

This runs a **mise-first bootstrap** that:

- Detects your hostname (megabookpro or workbookpro) and sets macOS hostname fields
- Installs Command Line Tools and accepts the Xcode license
- Installs Homebrew, Nix (official nix-installer), and mise
- Installs Brew packages, GUI apps, and dev tools via mise
- Links dotfiles to `~/.config/` and `~/Library/Application Support/`
- Sets macOS defaults, launchd agents, and shell configuration
- Renders fnox/1Password secrets and installs Helium with Widevine

Safe to rerun — detects existing state and reports conflicts before mutating.

**Manual gates you may encounter:**

- Xcode/MAS authentication (App Store sign-in)
- Gatekeeper "Open Anyway" for 1Password and Helium on first launch
- Okta Verify: `brew install --cask okta-verify` (separate step)
- Kanata: still Nix-managed — run `just darwin`

## Nix (retained for specific packages)

Nix is retained for `devenv.nix`, external flakes, and the `megalithic/flakes` repo
(consumed by mise's nix backend for complex packages like kanata and Helium).
It is no longer the primary workstation orchestrator.

## Usage

You can see the current tasks by running `just --list`

```bash
$ just --list
Available recipes:
default
fix-shell-files # fix shell files. this happens sometimes with nix-darwin
hm              # run home-manager switch
news
mac | rebuild # rebuild nix darwin
uninstall     # uninstalls the nix determinate installer
update        # updates brew, flake, and runs home-manager
update-brew   # update and upgrade homebrew packages
update-flake  # update your flake.lock
upgrade-nix   # upgrades nix
```

> **_NOTE_**: this nix setup is super unstable at the moment.

#### Quick start if using devenv:

```sh
devenv shell                    # enter dev environment
devenv tasks run home:apply     # apply home-manager config
devenv tasks run system:apply   # apply system config (requires sudo)
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
