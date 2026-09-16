function sz
    # Unstick terminal state left behind by crashed TUIs/BEAM: pop kitty
    # keyboard flags, disable modifyOtherKeys, disable bracketed paste.
    # Works inside tmux (parsed per-pane) and in a bare terminal.
    printf '\e[<u\e[>4;0m\e[?2004l'
    exec fish
end
