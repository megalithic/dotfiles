# https://github.com/brookhong/Surfingkeys/blob/master/src/nvim/server/Readme.md
# SCRIPT_PATH=$(dirname "$BASH_SOURCE"[0])
# echo "$SCRIPT_PATH"
# exec nvim --headless -c "luafile $SCRIPT_PATH/server.lua"
exec nvim --headless -c "luafile $HOME/.dotfiles/config/surfingkeys/server.lua"
