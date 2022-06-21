# Reference

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