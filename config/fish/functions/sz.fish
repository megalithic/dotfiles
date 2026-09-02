function sz
    set -e __HM_SESS_VARS_SOURCED
    set -l vars_file (string match -r '/nix/store/[^ ]+hm-session-vars\.fish' < ~/.config/fish/config.fish)
    test -n "$vars_file"; and source $vars_file
    exec fish
end
