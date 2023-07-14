#!/usr/bin/env bash
BASH_BINARY="$(which bash)"
PREVIEW_ID="fzfpreview"

function draw_preview {
    stty </dev/tty size | {
        read -r _ TERMINAL_COLUMNS
        X=$((TERMINAL_COLUMNS - COLUMNS - 2))
        Y=1
        ueberzug cmd -s "$socket" \
            -a add -i "${PREVIEW_ID}" \
            -x "$X" -y "$Y" \
            --max-width "${COLUMNS}" --max-height "${LINES}" \
            -f "${@}" >/dev/null
    }
}

ub_pid_file=$(mktemp)
ueberzug layer -o x11 --no-stdin --pid-file "$ub_pid_file" --silent --use-escape-codes </dev/null >/dev/null
ub_pid=$(cat "$ub_pid_file")

export -f draw_preview
export socket="/tmp/ueberzugpp-$ub_pid.socket"
SHELL="${BASH_BINARY}" \
    fzf --preview "draw_preview {}" \
    "${@}"

ueberzug cmd -s "$socket" -a exit >/dev/null
