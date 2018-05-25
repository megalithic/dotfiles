
```

 ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐
 │││├┤ │ ┬├─┤│  │ │ ├─┤││   :: bits & bobs, dots & things.
 ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘
 @megalithic


```


### Installation

If you want to kick the tires, then you can simply:

```sh
curl -fsSL \
  https://raw.githubusercontent.com/megalithic/dotfiles/master/bin/dotup | sh
```

The install script will install things and symlink the appropriate files in
`~/.dotfiles` to your home directory (`~`). Everything is configured and tweaked
within `~/.dotfiles`, though. All files and folders ending in `.symlink` get,
you guessed it, symlinked. For example: `~/.dotfiles/zsh/zshrc.symlink` gets
symlinked to `~/.zshrc`.

This also sets up things like homebrew if you're on a mac, and even allows for a
private repo setup.

I highly recommend you dig into the scripts and configs to see what all
is going on (because it does a lot that I'm not describing here) before you
all willy-nilly install a stranger's shell scripts. :)

### Main elements

A few of the tools I roll with:

- [ `brew` ](https://brew.sh/)
- [ Hammerspoon ](http://www.hammerspoon.org/)
- [ `tmux` ](https://github.com/tmux/tmux/wiki) -- Several shell scripts for
getting the info I want on my tmux statusbar (see `tmux-*` files in
~/.dotfiles/bin).
- [FuraCode Nerd Font](https://nerdfonts.com/)
- [ `kitty` ](https://github.com/kovidgoyal/kitty)
  * colors: [Nova](https://github.com/trevordmiller/nova-colors)
- [ `nvim` ](https://neovim.io/)
- [ `zsh` ](https://www.zsh.org/)
  * manager: [prezto](https://github.com/sorin-ionescu/prezto)
  * prompt: customized version of [pure](https://github.com/sindresorhus/pure), with some extra git things

The file hierarchy:

- **bin/**: Anything in `bin/` will get added to your `$PATH` and be made
  available everywhere.
- **topic/\*.zsh**: Any files ending in `.zsh` get loaded into your
  environment.
- **topic/path.zsh**: Any file named `path.zsh` is loaded first and is
  expected to setup `$PATH` or similar.
- **topic/\*.symlink**: Any files ending in `*.symlink` get symlinked into
  your `$HOME`. This is so you can keep all of those versioned in your dotfiles
  but still keep those autoloaded files in your home directory. These get
  symlinked in when you run `bin/dotup`.
- **topic/\*.completion.sh**: Any files ending in `completion.sh` get loaded
  last so that they get loaded after we set up zsh autocomplete functions.

### .localrc and sensitive data

Use `~/.localrc` as your location for sensitive information. Optionally, you
can let `bin/dotup` handle the cloning of your private repo to
~/.dotfiles/private, which will execute an install script, assuming it's
located at `~/.dotfiles/private/install.sh`.
