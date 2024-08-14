```sh

   ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐
   │││├┤ │ ┬├─┤│  │ │ ├─┤││
   ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘
   @megalithic 🗿

```

<p align="center">

![alt text](https://raw.githubusercontent.com/megalithic/dotfiles/main/screenshot.png "screenshot")

</p>

## 🚀 Installation

_If you want to kick the tires, you can simply:_

```bash
git clone https://github.com/megalithic/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && make install
```

_If you want to update an existing installation:_

```bash
make -C ~/.dotfiles up
```

_For platform specific installations:_

```bash
cd ~/.dotfiles && make macos # or, `linux`
# or, for easier use:
make -C ~/.dotfiles macos
```

_Get some help:_

```bash
cd ~/.dotfiles && make help
# or, for easier use:
make -C ~/.dotfiles help
```

> **_NOTE_**: to execute a `make` command from anywhere, say, specifically for your dotfiles: `make -C ~/.dotfiles <GOAL>`

---

This dotfiles repo is managed by [dotbot](https://github.com/anishathalye/dotbot); not near as over-the-top configurable as _Ansible_, but way more advanced than just _GNU Stow_.

I have tried to be platform agnostic, but the majority of scripts that run here are for macOS (specifically macOS Ventura -- x86 and arm), with a handful of Debian/Ubuntu Linux specific platform scripts and provisions. This means that certain tools/binaries I rely on might or might not install/configure on Linux. Though, I have tested it reasonably well on Ubuntu-based Linode and DigitalOcean instances.

#### 🐉 Thar be dragons

I am pushing updates _constantly_, so there are **NO** guarantees of stability with my config!

> **Warning**
>
> I highly recommend you dig into the scripts and configs to see what all is going on (because it does a lot more than what I'm describing in this README) before you -- all willy-nilly, throw caution to the wind -- install a stranger's shell scripts. 🤣

---

## ✨ Accoutrements

A few of the _must-have_ tools I roll with:

- [kitty](https://github.com/kovidgoyal/kitty)
- [tmux](https://github.com/tmux/tmux/wiki)
- [neovim](https://neovim.io/)
- [zsh](https://www.zsh.org/)
- [weechat](https://www.weechat.org/)
- [asdf](https://asdf-vm.com/)
- [homebrew](https://brew.sh/)
- `megaforest` for all the colours/themes
- [jetbrains mono](https://www.jetbrains.com/lp/mono/) font ([nerd-fonts](https://github.com/ryanoasis/nerd-fonts#font-patcher) patched)
- [hammerspoon](https://github.com/megalithic/dotfiles/tree/main/config/hammerspoon)
- [karabiner-elements](https://github.com/tekezo/Karabiner-Elements) ([leeloo ZMK](https://github.com/megalithic/zmk-config))
- [gpg/yubikey/encryption](https://github.com/drduh/YubiKey-Guide)
- `vim`-esque control
  - [surfingkeys (in-browser)](https://github.com/brookhong/Surfingkeys)
  - [homerow (macos-wide)](https://homerow.app)

<p align="center" style="margin-top: 20px;">
  <a href="https://megalithic.io" target="_blank">

![alt text](https://raw.githubusercontent.com/megalithic/dotfiles/main/megadotfiles.png "megadotfiles logo")

</a>
</p>
