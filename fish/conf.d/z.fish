if test -z "$Z_DATA"
  if test -z "$XDG_DATA_HOME"
    set -U Z_DATA_DIR "$HOME/.local/share/z"
  else 
    set -U Z_DATA_DIR "$XDG_DATA_HOME/z"
  end
  set -U Z_DATA "$Z_DATA_DIR/data"
end

if test ! -e "$Z_DATA"
  if test ! -e "$Z_DATA_DIR"
    mkdir -p -m 700 "$Z_DATA_DIR"  
  end
  touch "$Z_DATA"
end

if test -z "$Z_CMD"
  set -U Z_CMD "z"
end

set -U ZO_CMD "$Z_CMD"o

if test ! -z $Z_CMD
  function $Z_CMD -d "jump around"
    __z $argv
  end
end

if test ! -z $ZO_CMD
  function $ZO_CMD -d "open target dir"
    __z -d $argv
  end
end

if not set -q Z_EXCLUDE
  set -U Z_EXCLUDE $HOME
end

# Setup completions once first
__z_complete

function __z_on_variable_pwd --on-variable PWD
  __z_add
end
