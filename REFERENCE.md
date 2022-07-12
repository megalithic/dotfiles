# Reference

## MacOS apps

- https://github.com/FelixKratz/SketchyVim
- https://github.com/FelixKratz/SketchyBar
- https://github.com/dexterleng/vimac
- https://www.trankynam.com/xtrafinder/

#### System Intergrity Protection (SIP)

1. Disable System Integrity Protection.

   - How to turn off System Integrity Protection in macOS

   - Here's how to turn off System Integrity Protection on Mac

   - Restart your Mac
   - Hold down Command+R to reboot into Recovery Mode.
   - Click Utilities.
   - Select Terminal.
   - Type the following command: csrutil disable.
   - Press Enter on your keyboard.
   - Click Restart…
   - Restart your Mac and your new System Integrity Protection setting will take effect.

2. Launch Terminal and enter the following command:
   - `sudo defaults write /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation -bool true`
   - This command allows Finder (and all applications) to load arbitrary library.
   - By default, Finder can load libraries signed by Apple only.
3. Copy XtraFinderInjector.osax to directory /Library/ScriptingAdditions.
4. Copy XtraFinder.app to directory /Applications.

## GPG/Yubikey

- https://hackernoon.com/things-you-must-know-about-git-crypt-to-successfully-protect-your-secret-data-kyi3wi6
- https://chipsenkbeil.com/posts/applying-gpg-and-yubikey-part-1-overview/
- https://chipsenkbeil.com/posts/applying-gpg-and-yubikey-part-6-setting-up-yubikeys/
- https://www.instapaper.com/text?u=https%3A%2F%2Fzach.codes%2Fultimate-yubikey-setup-guide%2F
- https://github.com/drduh/YubiKey-Guide
- https://ocramius.github.io/blog/yubikey-for-ssh-gpg-git-and-local-login/
- https://www.guyrutenberg.com/tag/gpg/
- https://buddy.works/guides/git-crypt
- https://dev.to/paulmicheli/using-your-yubikey-for-signed-git-commits-4l73
- https://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration.html
- https://stackoverflow.com/questions/39494631/gpg-failed-to-sign-the-data-fatal-failed-to-write-commit-object-git-2-10-0
- https://superuser.com/a/1183544
- https://stackoverflow.com/a/70484849/213904
- https://scatteredcode.net/signing-git-commits-using-yubikey-on-windows
- https://wiki.gnupg.org/AgentForwarding
- https://www.youtube.com/watch?v=4166ExAnxmo (gpg signingkey as email)
- https://github.com/a-dma/yubitouch
- https://github.com/ahmedelgabri/dotfiles/blob/ba3774d38b2288ee5468cb26aa82098aaefcd139/install#L152-L163 (transcrypt instead of git-crypt thanks [@ahmed](https://twitter.com/ahmedelgabri/status/1541682417442127872?s=20&t=M-02HMWvusc5Fkb5PE8IYw))!

## NVIM

```lua
--[[ lua runtime ] -------------------------------------------------------------

   REF: https://github.com/neovim/neovim/pull/14686#issue-907487329

   order of operations:

   colors [first]
   compiler [first]
   ftplugin [all]
   ftdetect [all | ran at startup or packadd]
   indent [all]
   plugin [all | ran at startup or packadd]
   syntax [all]
   after/plugin ?
   after/ftplugin ?
   after/indent ?
   after/syntax ?

   NOTE: paq management and installer are in nvim/lua/mega/plugins.lua

--[ debugging ] ----------------------------------------------------------------

   Discover runtime files (change path) ->
    :lua mega.dump(vim.api.nvim_get_runtime_file('ftplugin/**/*.lua', true))

   Debug LSP traffic ->
    vim.lsp.set_log_level("trace")
    require("vim.lsp.log").set_format_func(vim.inspect)

   LSP/efm log locations ->
    htail -n150 -f $HOME/.cache/nvim/lsp.log`
    `tail -n150 -f $HOME/.cache/nvim/efm-lsp.log`
    -or-
    :lua vim.cmd('vnew '..vim.lsp.get_log_path())
    -or-
    :LspLog

   LSP current client server_capabilities ->
    `:lua =vim.lsp.get_active_clients()[1].server_capabilities`

--]]
```

## ZSH

```zsh
# exec - replaces the current shell. This means no subshell is
# created and the current process is replaced with this new command.
# fd/FD - file descriptor
# &- closes a FD e.g. "exec 3<&-" closes FD 3
# file descriptor 0 is stdin (the standard input),
# 1 is stdout (the standard output),
# 2 is stderr (the standard error).
# https://www.reddit.com/r/commandline/comments/vde0lw/wondering_what_a_line_of_code_does/icjsmei/
#
# ╭────────────────────────────────────────────────────────────────────────────╮
# │ Expression │ Description                                                   │
# │────────────────────────────────────────────────────────────────────────────│
# │ $#         │ Number of arguments                                           │
# │ $*         │ All positional arguments (as a single word)                   │
# │ $@         │ All positional arguments (as separate strings)                │
# │ $1         │ First argument                                                │
# │ $_         │ Last argument of the previous command                         │
# │ $?         │ Exit code of previous command                                 │
# │ $!         │ PID of last command run in the background                     │
# │ $0         │ The name of the shell script itself                           │
# │ $-         │ Current option flags set by the script                        │
# ╰────────────────────────────────────────────────────────────────────────────╯
# NOTE: $@ and $* must be quoted in order to perform as described. Otherwise,
# they do exactly the same thing (arguments as separate strings).
#
# (EXPANSIONS)
# ╭────────────────────────────────────────────────────────────────────────────╮
# │ Expression │ Description                                                   │
# │────────────────────────────────────────────────────────────────────────────│
# │ !$         │ Expand last parameter of most recent command                  │
# │ !*         │ Expand all parameters of most recent command                  │
# │ !-n        │ Expand nth most recent command                                │
# │ !n         │ Expand nth command in history                                 │
# │ !<command> │ Expand most recent invocation of command <command>            │
# ╰────────────────────────────────────────────────────────────────────────────╯
#
# (OPERATIONS)
# ╭────────────────────────────────────────────────────────────────────────────╮
# │ Code               │ Description                                           │
# │────────────────────────────────────────────────────────────────────────────│
# │ !!                 │ Execute last command again                            │
# │ !!:s/<FROM>/<TO>/  │ Replace first occurrence of <FROM> to <TO> in most    │
# │                    │   recent command                                      │
# │ !!:gs/<FROM>/<TO>/ │ Replace all occurrences of <FROM> to <TO> in most     │
# │                    │   recent command                                      │
# │ !$:t               │ Expand only basename from last parameter of most      │
# │                    │   recent command                                      │
# │ !$:h               │ Expand only directory from last parameter of most     │
# │                    │   recent command                                      │
# ╰────────────────────────────────────────────────────────────────────────────╯
# NOTE: !! and !$ can be replaced with any valid expansion.
#
# (SLICES)
# ╭────────────────────────────────────────────────────────────────────────────╮
# │ Code    │ Description                                                      │
# │────────────────────────────────────────────────────────────────────────────│
# │ !!:n    │ Expand only nth token from most recent command                   │
# │         │   (command is 0; first argument is 1)                            │
# │ !^      │ Expand first argument from most recent command                   │
# │ !$      │ Expand last token from most recent command                       │
# │ !!:n-m  │ Expand range of tokens from most recent command                  │
# │ !!:n-$  │ Expand nth token to last from most recent command                │
# ╰────────────────────────────────────────────────────────────────────────────╯
# NOTE: !! can be replaced with any valid expansion i.e. !cat, !-2, !42, etc.
#
```

https://linux.die.net/abs-guide/exitcodes.html

## SurfingKeys

- https://github.com/eugercek/dotfiles/blob/master/surfingkeys.js
