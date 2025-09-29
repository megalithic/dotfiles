#-------------------------------------------------------------------------------
#  PLUGIN MANAGEMENT
#-------------------------------------------------------------------------------

PLUGINS="$ZDOTDIR/plugins/"

# TODO:
# - add zsh-defer: https://github.com/romkatv/zsh-defer
# - handle -d for defering in zsh_add_plugin/2

# source "$PLUGINS/zsh-defer/zsh-defer.plugin.zsh"

function zsh_add_file() {
  [[ -f "$ZDOTDIR/$1" ]] && source "$ZDOTDIR/$1" #(printf "adding %s\n" "$ZDOTDIR/$1" && source "$ZDOTDIR/$1") || (printf "missing %s\n" "$ZDOTDIR/$1")
}

# function zsh_defer_file() {
#   [[ -f "$ZDOTDIR/$1" ]] && zsh-defer source "$ZDOTDIR/$1"
# }

function zsh_source_plugin() {
  zsh_add_file "$PLUGINS/$1.zsh"
}

function zsh_add_plugin() {
  PLUGIN_NAME=$(echo $1 | cut -d "/" -f 2)

  if [[ -d "$ZDOTDIR/plugins/$PLUGIN_NAME" ]]; then
    if [[ -n "$(ls -A "$ZDOTDIR/plugins/$PLUGIN_NAME" 2> /dev/null)" ]]; then
      zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh" ||
        zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.zsh" ||
        zsh_add_file "plugins/$PLUGIN_NAME/$2.zsh"
    else
      __zsh_remove_plugin "$1"
      zsh_add_plugin_submodule "$1"
    fi
  else
    __zsh_remove_plugin "$1"
    zsh_add_plugin_submodule "$1"
  fi
}

function zsh_add_plugin_submodule() {
  PLUGIN_NAME=$(echo $1 | cut -d "/" -f 2)

  pushd $DOTS
  git submodule add "https://github.com/$1.git" "config/zsh/plugins/$PLUGIN_NAME"
  popd
}

function __zsh_remove_plugin() {
  PLUGIN_NAME=$(echo $1 | cut -d "/" -f 2)

  pushd $DOTS
  echo "removing config/zsh/plugins/$PLUGIN_NAME"
  rm -rf "config/zsh/plugins/$PLUGIN_NAME"
  git update-index --remove "config/zsh/plugins/$PLUGIN_NAME"
  git config -f .gitmodules --remove-section "submodule.config/zsh/plugins/$PLUGIN_NAME"
  popd
}

# function zsh_defer_plugin() {
#   PLUGIN_NAME=$(echo $1 | cut -d "/" -f 2)

#   if [[ -d "$ZDOTDIR/plugins/$PLUGIN_NAME" ]]; then
#     zsh_defer_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh" ||
#       zsh_defer_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.zsh" ||
#       zsh_defer_file "plugins/$PLUGIN_NAME/$2.zsh"
#   else
#     pushd $DOTS
#     git submodule add "https://github.com/$1.git" "$PLUGIN_DIR/$PLUGIN_NAME"
#     popd
#   fi
# }
