#-------------------------------------------------------------------------------
#  PLUGIN MANAGEMENT
#-------------------------------------------------------------------------------

PLUGIN_DIR="config/zsh/plugins"
# PLUGIN_DIR="$DOTS/config/zsh/plugins"
PLUGINS="$ZDOTDIR/plugins/"

# TODO:
# - add zsh-defer: https://github.com/romkatv/zsh-defer
# - handle -d for defering in zsh_add_plugin/2

source "$PLUGINS/zsh-defer/zsh-defer.plugin.zsh"

function zsh_add_file() {
  # echo "adding file $1"
  [[ -f "$ZDOTDIR/$1" ]] && source "$ZDOTDIR/$1"
}

function zsh_defer_file() {
  [[ -f "$ZDOTDIR/$1" ]] && zsh-defer source "$ZDOTDIR/$1"
}

function zsh_source_plugin() {
  zsh_add_file "plugins/$1.zsh"
}

function zsh_add_plugin() {
  PLUGIN_NAME=$(echo $1 | cut -d "/" -f 2)

  # echo "adding plugin $PLUGIN_NAME"

  if [[ -d "$ZDOTDIR/plugins/$PLUGIN_NAME" ]]; then
    zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh" ||
      zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.zsh" ||
      zsh_add_file "plugins/$PLUGIN_NAME/$2.zsh"
  else
    pushd $DOTS
    git submodule add "https://github.com/$1.git" "$PLUGIN_DIR/$PLUGIN_NAME"
    popd
  fi
}

function zsh_defer_plugin() {
  PLUGIN_NAME=$(echo $1 | cut -d "/" -f 2)

  if [[ -d "$ZDOTDIR/plugins/$PLUGIN_NAME" ]]; then
    zsh_defer_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh" ||
      zsh_defer_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.zsh" ||
      zsh_defer_file "plugins/$PLUGIN_NAME/$2.zsh"
  else
    pushd $DOTS
    git submodule add "https://github.com/$1.git" "$PLUGIN_DIR/$PLUGIN_NAME"
    popd
  fi
}
