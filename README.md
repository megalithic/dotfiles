
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
curl -fsSL https://raw.githubusercontent.com/megalithic/dotfiles/master/bin/_dotup | /usr/bin/env zsh
```

The install script will install things and symlink the appropriate files in
`~/.dotfiles` to your home directory (`~`). Everything is configured and tweaked
within `~/.dotfiles`, though. All files and folders ending in `.symlink` get,
you guessed it, symlinked. For example: `~/.dotfiles/zsh/zshrc.symlink` gets
symlinked to `~/.zshrc`.

This also sets up things like homebrew if you're on a mac, and even allows for a
private repo setup. **Please note**, this repo supports multiple platforms, but
has really only been extensively used and tested on macos.

I highly recommend you dig into the scripts and configs to see what all
is going on (because it does a lot that I'm not describing here) before you
all willy-nilly install a stranger's shell scripts. :)

### Main elements

A few of the tools I roll with:

- [homebrew](https://brew.sh/)
- [hammerspoon](http://www.hammerspoon.org/)
- [karabiner-elements](https://github.com/tekezo/Karabiner-Elements)
  * see `~/.dotfiles/keyboard`
- [tmux](https://github.com/tmux/tmux/wiki)
  * additional tmux statusbar binaries available (see `tmux-*` files in
  `~/.dotfiles/bin`).
- [dankmono nerd font](https://dank.sh)
  * patched via [nerd-fonts](https://github.com/ryanoasis/nerd-fonts#font-patcher)
- [kitty](https://github.com/kovidgoyal/kitty)
- [nova](https://github.com/trevordmiller/nova-colors) - pretty much for everything
- [neovim](https://neovim.io/)
- [zsh](https://www.zsh.org/)

The file hierarchy:

- **bin/**: Anything in `bin/` will get added to your `$PATH` and be made
  available everywhere.
- **topic/\*.symlink**: Any files ending in `*.symlink` get symlinked into
  your `$HOME`. This is so you can keep all of those versioned in your dotfiles
  but still keep those autoloaded files in your home directory. These get
  symlinked when you run `bin/_dotup`, or you can explicitly run `bin/_symlinks`.
- **topic/\<platform\>.sh**: Platform-specific installers to handle additional
  things that you may need to happen for that topic. `all | macos | linux | freebsd | windows`

### Sensitive data

Use `~/.localrc` as your location for sensitive information. ~~Optionally, you
can let `bin/_dotup` handle the cloning of your private repo to
`~/.dotfiles/private`, which will execute an install script, assuming it's
located at `~/.dotfiles/private/install.sh`.~~

### Attribution

- Originally based on the dotfiles of the esteemed [Wynn Netherland](https://github.com/pengwynn/dotfiles)
- Presently a delicate combination of [Wynn Netherland's](https://github.com/pengwynn/dotfiles) and [Phillip Ridlen's](https://github.com/philtr/dotfiles) respective dotfiles


<p align="center" style="margin-top: 20px;">
  <img src="megadotfiles.png" alt="megadotfiles" height="150px"/>
</p>
