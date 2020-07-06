#
# chruby - Ruby Version Manager
#
source /usr/local/share/chruby/auto.sh
source /usr/local/share/chruby/chruby.sh
RUBIES=(~/.rubies/*)


#
# rbenv - Ruby Version Manager
#
eval "$(rbenv init --no-rehash -)"
(rbenv rehash &) 2> /dev/null
