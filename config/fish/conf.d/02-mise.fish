# Activate mise so tools and [shell_alias] work in fish. The 02- prefix sorts it
# before the tool snippets (atuin, fnox, fzf, ...), which return early when
# their tool isn't on PATH yet.

command -sq mise; or return

if status is-interactive
    mise activate fish | source
else if status is-login
    # `fish -l -c ...` (Rex commands start this way with a bare PATH): one-shot
    # env, no prompt hooks. Not `mise activate --shims`: shims/pi would shadow
    # the ~/.local/bin/pi wrapper.
    mise env -s fish | source
end
