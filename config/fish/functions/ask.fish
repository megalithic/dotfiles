function ask
    set -l model "hf:deepseek-ai/DeepSeek-V3.2"
    set -l question
    set -l args

    # Parse flags.
    while test (count $argv) -gt 0
        switch $argv[1]
            case -m --model
                # Present synthetic models to choose from.
                set -l models (pi --list-models 2>/dev/null | rg "^synthetic" | awk '{print $2}')
                if test -z "$models"
                    echo "No synthetic models found"
                    return 1
                end
                set model (printf "%s\n" $models | gum choose --header "Select model:")
                if test -z "$model"
                    return 0
                end
                set -e argv[1]
            case '*'
                set -a args $argv[1]
                set -e argv[1]
        end
    end

    # If no arguments, prompt for input with textarea.
    if test (count $args) -eq 0
        set question (gum write --placeholder "Ask pi a question..." --header "Question:" --char-limit 0)
        if test -z "$question"
            return 0
        end
    else
        set question (string join " " $args)
    end

    # Run pi with spinner, capture output to temp file (avoids quoting issues).
    set -l outfile (mktemp)
    gum spin --spinner dot --title "Asking $model..." -- sh -c 'pi -p --no-session --no-tools --provider synthetic --model "$1" "$2" 2>/dev/null > "$3"' _ "$model" "$question" "$outfile"

    # Render with glow if available.
    if command -q glow
        glow < $outfile
    else
        cat $outfile
    end

    command rm -f "$outfile"
end
