function fasd_cd -d "fasd builtin cd"
  if test (count $argv) -le 1
    command fasd "$argv"
  else
    fasd -e 'printf %s' $argv | read -l ret
    test -z "$ret"; and return
    test -d "$ret"; and cd "$ret"; or printf "%s\n" $ret
  end
end
