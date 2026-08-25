# Async feedback from bin/wt's detached auto-prune. The wrapper writes
# "<epoch> <repo>: <summary>" to $XDG_STATE_HOME/wt/auto-prune-note only when
# a background `wt step prune` removed something or failed; no-op runs stay
# silent. This fish_prompt hook prints unseen notes at the next prompt.
# (A universal-variable transport was tried first, but fish 4.8 does not
# propagate cross-process changes into running shells here.) Notes that
# predate this shell are marked seen at startup so they never replay.
status is-interactive; or return

set -g __wt_auto_prune_note_file (test -n "$XDG_STATE_HOME"; and echo $XDG_STATE_HOME; or echo ~/.local/state)/wt/auto-prune-note
set -g __wt_auto_prune_seen ''
test -f $__wt_auto_prune_note_file
and set -g __wt_auto_prune_seen (command cat $__wt_auto_prune_note_file 2>/dev/null | string collect)

function __wt_auto_prune_notify --on-event fish_prompt
    test -f $__wt_auto_prune_note_file; or return
    set -l note (command cat $__wt_auto_prune_note_file 2>/dev/null | string collect)
    test -n "$note"; or return
    test "$__wt_auto_prune_seen" != "$note"; or return
    set -g __wt_auto_prune_seen $note
    printf 'wt auto-prune: %s\n' (string replace -r '^\d+ ' '' -- $note)
end
