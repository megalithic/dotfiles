#!/usr/bin/env zsh

echo ""
echo ":: setting up python things"
echo ""

asdf reshim python

pip install --upgrade pip
pip2 install --upgrade pip
pip3 install --upgrade pip
# $(brew --prefix)/opt/python@3.8/bin/pip3 install --upgrade pip

pip install wheel setuptools
pip2 install wheel setuptools
pip3 install wheel setuptools
/usr/local/opt/python@3.8/bin/pip3 install wheel setuptools

$DOTS/python/package-installer

# this is for wee_slack.py plugin to work for weechat,
# https://github.com/wee-slack/wee-slack#1-install-dependencies:

echo ":: installing weechat/wee-slack specific workaround.."

sudo -H /usr/local/opt/python@3.8/bin/pip3 install websocket_client

# sudo /usr/local/opt/python@2/bin/pip2 install websocket_client
# sudo /usr/local/bin/pip install websocket_client
# sudo /usr/local/bin/pip install websocket
# sudo -H /usr/local/bin/pip2 install websocket_client
# sudo -H /usr/local/bin/pip2 install websocket
# sudo /usr/local/bin/pip3 install websocket_client
# sudo /usr/local/bin/pip3 install websocket
# sudo $(brew --prefix)/opt/python@3.8/bin/pip3 install websocket_client
