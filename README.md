```

   ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐
   │││├┤ │ ┬├─┤│  │ │ ├─┤││   :: bits & bobs, dots & things.
   ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘
   @megalithic

```

<p align="center">
  <img src="screenshot.png" alt="screenshot" />
</p>

## 🚀 Installation

If you want to kick the tires, you can simply:

```bash
git clone git@github.com:megalithic/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && make -B
```

> **_NOTE_**: defaults to using the `install` goal

_For platform specific installs:_

```bash
cd ~/.dotfiles && make -B macos # or, `linux`
```

_Get some help:_

```bash
cd ~/.dotfiles && make -B help
```

> **_NOTE_**: to execute a `make` command from anywhere; specifically for your dotfiles: `make -BC ~/.dotfiles <GOAL>`

---

This dotfiles repo is managed by [dotbot](https://github.com/anishathalye/dotbot); not near as over-the-top configurable as _Ansible_, but way more advanced than just _GNU Stow_.

I have tried to be platform agnostic, but the majority of scripts that run here are for MacOS (specifically MacOS Big Sur, _non-M1_, at the time of this commit), with a handful of Debian/Ubuntu Linux specific platform scripts and provisions. This means that certain tools/binaries I rely on may or may not install/configure on Linux. Though, I have tested it decently well on an Ubuntu-based Linode instance.

##### 🐉 Thar be dragons..

> ⚠️ I highly recommend you dig into the scripts and configs to see what all is going on (because it does a lot more than what I'm describing in this README) before you -- all willy-nilly, throwing caution to the wind -- install a stranger's shell scripts. 🤣

## ✨ Accoutrements

A few of the _must-have_ tools I roll with:

- [kitty](https://github.com/kovidgoyal/kitty)
- [tmux](https://github.com/tmux/tmux/wiki)
- [neovim](https://neovim.io/)
- [zsh](https://www.zsh.org/) ([starship](https://starship.rs) prompt)
- [weechat](https://www.weechat.org/)
- [asdf](https://asdf-vm.com/)
- [homebrew](https://brew.sh/)
- `megaforest` for all the colours/themes
- [jetbrains mono](https://www.jetbrains.com/lp/mono/) font ([nerd-fonts](https://github.com/ryanoasis/nerd-fonts#font-patcher) patched)
- [hammerspoon](https://github.com/megalithic/dotfiles/tree/master/hammerspoon)
- [karabiner-elements](https://github.com/tekezo/Karabiner-Elements) ([atreus62 qmk](https://github.com/megalithic/qmk_firmware/tree/master/keyboards/atreus62/keymaps/megalithic))

<p align="center" style="margin-top: 20px;">
  <img src="megadotfiles.png" alt="megadotfiles" height="150px"/>
</p>
