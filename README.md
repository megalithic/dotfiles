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
git clone git@github.com:megalithic/dots.git ~/.dotfiles && make -C ~/.dotfiles install
```

This dotfiles repo is managed by [dotbot](https://github.com/anishathalye/dotbot).

I have tried to be platform agnostic, but the majority of scripts that run here
are for MacOS (specifically MacOS Big Sur, non-M1, at the time of this commit), with a
handful of Debian/Ubuntu Linux specific platform scripts and provisions. This
means that certain tools/binaries I rely on may or may not install/configure on
Linux. Though, I have tested it decently well on an Ubuntu-based Linode instance.

##### ⚠️ Thar be dragons..

I highly recommend you dig into the scripts and configs to see what all
is going on (because it does a lot that I'm not describing here) before you
-- all willy-nilly, throwing caution to the wind -- install a stranger's shell scripts. 🤣

### ✨ Accoutrements

A few of the _must-have_ tools I roll with:

- [homebrew](https://brew.sh/)
  - see `~/.dotfiles/brew` for all that gets installed
- [hammerspoon](https://github.com/megalithic/dotfiles/tree/master/hammerspoon)
- [karabiner-elements](https://github.com/tekezo/Karabiner-Elements)
  - see `~/.dotfiles/keyboard` for macOS specific config things
  - see my [Atreus62 config](https://github.com/megalithic/qmk_firmware/tree/master/keyboards/atreus62/keymaps/megalithic) for my custom keyboard setup
- [tmux](https://github.com/tmux/tmux/wiki)
- [jetbrains mono](https://www.jetbrains.com/lp/mono/)
  - patched via [nerd-fonts](https://github.com/ryanoasis/nerd-fonts#font-patcher)
- [kitty](https://github.com/kovidgoyal/kitty)
- `megaforest/everforest` everything
- [neovim](https://neovim.io/)
- [zsh](https://www.zsh.org/)
  - [starship](https://starship.rs)
- [weechat](https://www.weechat.org/)

<p align="center" style="margin-top: 20px;">
  <img src="megadotfiles.png" alt="megadotfiles" height="150px"/>
</p>
