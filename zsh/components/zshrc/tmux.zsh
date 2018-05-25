function txs() {
  tmux_session=$1

  # list sessions if no session name provided
  if [[ -z $tmux_session ]]; then
    tmux ls
  else
    if ! tmux has-session -t "$tmux_session" 2> /dev/null; then
      # Ensure that tmux server is started.
      tmux start-server

      # Create a new session.
      tmux new-session -d -s "$tmux_session"
    fi

    exec tmux attach-session -t "$tmux_session"
  fi
}
