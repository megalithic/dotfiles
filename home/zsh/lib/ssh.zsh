# fix up permissions every time, just in case
umask 002
if [[ -d "$HOME/.ssh" ]]; then
	chmod 700 "$HOME/.ssh" 2>/dev/null
	chmod 600 "$HOME/.ssh/*" 2>/dev/null
fi
