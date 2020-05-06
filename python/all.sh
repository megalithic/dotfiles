#!/usr/bin/env zsh

echo ""
echo ":: setting up python things"
echo ""

pip install --upgrade pip
# pip2 install --upgrade pip
pip3 install --upgrade pip

$DOTS/python/package-installer

# this is for wee_slack.py plugin to work for weechat,
# https://github.com/wee-slack/wee-slack#1-install-dependencies:

echo ":: installing weechat/wee-slack specific workaround.."
# sudo /usr/local/opt/python@2/bin/pip2 install websocket_client
sudo /usr/local/bin/pip install websocket_client
# sudo /usr/local/bin/pip2 install websocket_client
sudo /usr/local/bin/pip3 install websocket_client
