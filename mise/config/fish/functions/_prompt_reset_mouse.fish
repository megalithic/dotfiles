function _prompt_reset_mouse --on-event fish_postexec
    status is-interactive; or return
    # a child (iex/beam, tmux, less, etc.) may leave the tty in raw mode or on
    # the alt screen. IEx on OTP 26+ (prim_tty) sets raw mode and does not
    # restore it when killed abruptly (Ctrl-C on `mise run start:server`).
    stty sane 2>/dev/null
    # mouse off, exit alt-screen, show cursor, reset SGR + charset
    printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1049l\e[?25h\e(B\e[m'
    commandline -f repaint
end
