#!/bin/zsh

cat $HOME/.default-python-packages | xargs pip install --upgrade --user
cat $HOME/.default-python-packages | xargs pip2 install --upgrade --user
cat $HOME/.default-python-packages | xargs pip3 install --upgrade --user
# cat $HOME/.default-python-packages | xargs /usr/local/opt/python@3.8/bin/pip3 install --upgrade --user
