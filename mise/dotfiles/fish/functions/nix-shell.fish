function nix-shell --wraps="nix-shell"
    for ARG in $argv
        if [ "$ARG" = --run ]
            command nix-shell $argv
            return $status
        end
    end
    command nix-shell $argv --run "exec fish"
end
