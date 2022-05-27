#-------------------------------------------------------------------------------
#  PLUGIN MANAGEMENT
#-------------------------------------------------------------------------------
PLUGIN_DIR="$DOTFILES/config/zsh/plugins"

function zsh_add_file() {
  [ -f "$ZDOTDIR/$1" ] && source "$ZDOTDIR/$1"
}

function zsh_source_plugin () {
  zsh_add_file "$PLUGIN_DIR/$1.zsh"
}

function zsh_add_plugin() {
  PLUGIN_NAME=$(echo $1 | cut -d "/" -f 2)
  if [ -d "$PLUGIN_DIR/$PLUGIN_NAME" ]; then
    zsh_add_file "$PLUGIN_DIR/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh" || \
    zsh_add_file "$PLUGIN_DIR/$PLUGIN_NAME/$PLUGIN_NAME.zsh" || \
    zsh_add_file "$PLUGIN_DIR/$PLUGIN_NAME/$2.zsh"
  else
    echo "1: $1"
    echo "$PLUGIN_DIR/$PLUGIN_NAME"
    git submodule add "https://github.com/$1" "$PLUGIN_DIR/$PLUGIN_NAME"
  fi
}