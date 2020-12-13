#!/usr/bin/env zsh

# asdf reshim python

pip install --upgrade pip
pip2 install --upgrade pip
pip3 install --upgrade pip
# $(brew --prefix)/opt/python@3.8/bin/pip3 install --upgrade pip

pip install wheel setuptools
pip2 install wheel setuptools
pip3 install wheel setuptools
/usr/local/opt/python@3.8/bin/pip3 install wheel setuptools

sh $DOTS/python/package-installer.sh

# this is for wee_slack.py plugin to work for weechat,
# https://github.com/wee-slack/wee-slack#1-install-dependencies:

echo ":: installing weechat/wee-slack specific workaround.."

sudo -H /usr/local/opt/python@3.8/bin/pip3 install websocket_client
sudo -H /usr/local/opt/python@3.9/bin/pip3 install websocket_client

# -----------------------------------------------------------------------------
# NOTES:
# =============================================================================
#
# Python issues arise constantly.. with weechat, with ssh and git.
# For now, this system relies on homebrew installs of python@3.8 (ssh/git)
# and python@3.9 (weechat)
