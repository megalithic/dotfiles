function _prompt_move_to_bottom --on-event="fish_postexec"
    tput cup $LINES
end
