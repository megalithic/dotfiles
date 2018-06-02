### Pure Prompt Setup

The goal here is to ensure the 3 zsh files live under a location that zsh picks up in $fpath,
in my case, that'd be under `/usr/local/share/zsh/site-functions`.

```
ln -sfv $DOTS/zsh/themes/prompt_pure.zsh /usr/local/share/zsh/site-functions/prompt_pure_setup
ln -sfv $DOTS/zsh/themes/async.zsh /usr/local/share/zsh/site-functions/async
ln -sfv $DOTS/zsh/themes/gitstatus.zsh /usr/local/share/zsh/site-functions/gitstatus
```
