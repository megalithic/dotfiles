```

     ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐
     │││├┤ │ ┬├─┤│  │ │ ├─┤││   :: bits & bobs, dots & things.
     ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘
     @megalithic

```

<p align="center">
  <img src="screenshot.png" alt="screenshot" />
</p>

### Installation

If you want to kick the tires, you can simply:

```sh
curl -fsSL https://raw.githubusercontent.com/megalithic/dotfiles/main/bin/_dotup | zsh
```

The install script will install things and symlink the appropriate files in
`~/.dotfiles` to your home directory (`~`). Everything is configured and tweaked
within `~/.dotfiles`, though. The majority of files and folders get `stow`ed in
to your `$HOME`, or to `$XDG_CONFIG_HOME`.

I have tried to be platform agnostic, but the majority of scripts that run here
are for macOS (specifically Big Sur at the time of this edit), with a handful of
debian/ubuntu linux specific platform scripts and
provisions. This means that certain tools/binaries I rely on may or may not
install/configure on linux. Though, I have tested it decently well on an
Ubuntu-based Linode instance.

I highly recommend you dig into the scripts and configs to see what all
is going on (because it does a lot that I'm not describing here) before you
install a stranger's shell scripts all willy-nilly, throwing caution to the
wind. 🤣

### Things

A few of the _must-have_ tools I roll with:

* [homebrew](https://brew.sh/)
  + see `~/.dotfiles/Brewfile` for all that gets installed
* [hammerspoon](https://github.com/megalithic/dotfiles/tree/master/hammerspoon)
* [karabiner-elements](https://github.com/tekezo/Karabiner-Elements)
  + see `~/.dotfiles/keyboard` for macOS specific config things
  + see my [Atreus62 config](https://github.com/megalithic/qmk_firmware/tree/master/keyboards/atreus62/keymaps/megalithic) for my custom keyboard setup
* [tmux](https://github.com/tmux/tmux/wiki)
  + additional tmux statusbar binaries available (see `tmux-*` files in
    `~/.dotfiles/bin`).
  + see also my [DND tmux plugin](https://github.com/megalithic/tmux-dnd-status)
* [jetbrains mono](https://www.jetbrains.com/lp/mono/)
  + patched via [nerd-fonts](https://github.com/ryanoasis/nerd-fonts#font-patcher)
* [kitty](https://github.com/kovidgoyal/kitty)
* [~~forest night~~ everforest](https://github.com/sainnhe/everforest)
* [neovim](https://neovim.io/)
  + using lua with neovim? https://github.com/nanotee/nvim-lua-guide
* [zsh](https://www.zsh.org/)
  + [starship](https://starship.rs)
* [weechat](https://www.weechat.org/)

### Stuff

The file hierarchy:

* **bin/**: Anything in `bin/` will get added to your `$PATH` and be made
  available everywhere.
* Everything else is handled by custom installers based upon the current
  platform; otherwise, `stow` handles the rest (clean and easy symlinking).

### Privates

Use `~/.localrc` as your location for sensitive information. ~~Optionally, you
can let `bin/_dotup` handle the cloning of your private repo to
`~/.dotfiles/private`, which will execute an install script, assuming it's
located at `~/.dotfiles/private/install.sh`.~~

_NOTE:_ You'll want to be sure to setup an SSH key for github access to this repo and likely to your private repo too: https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent

Also helpful: https://docs.github.com/en/free-pro-team@latest/github/using-git/caching-your-github-credentials-in-git

### Props

* So many esteemed individuals in the community have, in some way, left their
  mark on my own dotfilery (they're all legends in my book):

  + [Zach Holman](https://github.com/holman/dotfiles)
  + [Wynn Netherland](https://github.com/pengwynn/dotfiles)
  + [Evan Travers](https://github.com/evantravers/dotfiles)
  + [Dorian Karter](https://github.com/dkarter/dotfiles)
  + [Phil Ridlen](https://github.com/philtr/dotfiles)
  + _.. and many, many others._

### Refs

* A wealth of handy scripts/bins for future use: https://github.com/salman-abedin/alfred
* Neovim lua migration resource: https://github.com/nanotee/nvim-lua-guide

<p align="center" style="margin-top: 20px;">
  <img src="megadotfiles.png" alt="megadotfiles" height="150px"/>
</p>
