# Enable jdx/usage completions for usage-shebang scripts on PATH.
# Fish has no default completer fallback, so usage scans PATH once per shell.
status is-interactive; or return
command -sq usage; or return

# Upstream init reads every executable on PATH. Add -r so unreadable system
# binaries (for example sudo) do not print fish redirection warnings at startup.
usage generate completion-init fish \
    | string replace 'test -f $file -a -x $file; or continue' 'test -f $file -a -x $file -a -r $file; or continue' \
    | source
