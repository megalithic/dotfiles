function _prompt_reset_mouse --on-event fish_postexec
    printf "\e[?1000l\e[?1002l\e[?1003l\e[?1006l"
    commandline -f repaint
end
