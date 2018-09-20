#!/usr/bin/env zsh

setopt EXTENDED_GLOB
rg "^\s*\w\+[^=]*=\s*$" ~/.elm/0.18.0/package/(^(tests|test|virtual-dom|Internal)/)#*.elm \
    | rg -v "^\s--" \
    | rg -v "\s*type\s" \
    | sed -e 's/=.*//' -e 's/\.elm: */\./' \
    | cut -d' ' -f 1 \
    | rev \
    | cut -d'/' -f 1 \
    | rev \
    | sort


# first, run:
# elm-dictionary.zsh > ~/.elm/0.18.0/dictionary
#
# second, add to vim config for elm only:
# setlocal iskeyword+=.
# setlocal dictionary=~/.elm/0.18.0/dictionary
