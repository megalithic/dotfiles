### Pure Prompt Setup

The goal here is to ensure the necessary zsh files live under a location that
zsh picks up in $fpath; usually, that'd be under `/usr/local/share/zsh/site-functions`.

```
ln -sfv $DOTS/zsh/themes/prompt_pure.zsh /usr/local/share/zsh/site-functions/prompt_pure_setup
ln -sfv $DOTS/zsh/themes/async.zsh /usr/local/share/zsh/site-functions/async
```
