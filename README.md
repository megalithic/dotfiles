
```

 ┌┬┐┌─┐┌─┐┌─┐┬  ┬┌┬┐┬ ┬┬┌─┐
 │││├┤ │ ┬├─┤│  │ │ ├─┤││   :: dots & things
 ┴ ┴└─┘└─┘┴ ┴┴─┘┴ ┴ ┴ ┴┴└─┘
 @megalithic


```


### Installation

If you want to kick the tires, then simply:

```sh
curl -fsSL \
  https://raw.githubusercontent.com/megalithic/dotfiles/master/bin/dotup | sh
```

The install script will symlink the appropriate files in `~/.dotfiles` to your
home directory (`~`). Everything is configured and tweaked within `~/.dotfiles`,
though. All files and folders ending in `.symlink` get, you guessed it,
symlinked. For example: `~/.dotfiles/zsh/zshrc.symlink` gets symlinked to
`~/.zshrc`.

This also sets up things like homebrew if you're on a mac, and even allows for a
private repository setup.

I highly recommend you dig into the scripts and configs to see what all
is going on before you willy-nilly install a stranger's shell scripts. :)

### Main elements

A few of the flavors I roll with:

- Homebrew
- Hammerspoon
- Tmux -- Several shell scripts for getting the info I want on my tmux statusbar (take
a gander at `~/.dotfiles/bin` for `tmux-` prefixed scripts).
- FuraCode Nerd Font
- Kitty / iTerm2 / Alacritty -- Nova color scheme
- Neovim -- Nova color scheme
- Zsh -- [pure](https://github.com/sindresorhus/pure), with some extra git things

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
  symlinked in when you run `scripts/bootstrap`.
- **topic/\*.completion.sh**: Any files ending in `completion.sh` get loaded
  last so that they get loaded after we set up zsh autocomplete functions.

### .localrc and sensitive data

Use `~/.localrc` as your location for sensitive information. Optionally, you
can let `setup/bootstrap` handle the cloning of your private repo to
~/.dotfiles/private, which will execute an install script, assuming it's
located at `~/.dotfiles/private/install.sh`.
