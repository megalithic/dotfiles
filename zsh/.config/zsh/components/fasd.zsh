#
# fasd
#

if [ $commands[fasd] ]; then # check if fasd is installed
  fasd_cache="$HOME/.fasd-init-cache"
  if [ "$(command -v fasd)" -nt "$fasd_cache" -o ! -s "$fasd_cache" ]; then
    fasd --init auto >| "$fasd_cache"
  fi

  source "$fasd_cache"
  unset fasd_cache

  # TODO: find out what these do exactly
  # alias v='f -e nvim'
  # alias o='a -e open'
fi
