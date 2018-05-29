### Pure Prompt Setup

The goal here is to ensure the 2 zsh files live under a location that zsh picks up in $fpath, in my case, that'd be under `$HOME/.dotfiles/zsh/themes`.

```
ln -s "$PWD/pure.zsh" $HOME/.dotfiles/zsh/themes/pure/prompt_pure_setup
ln -s "$PWD/async.zsh" $HOME/.dotfiles/zsh/themes/pure/async
```
