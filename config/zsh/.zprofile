#!/usr/bin/env zsh
# shellcheck shell=bash
#
# .zprofile is sourced on login shells and before .zshrc. As a general rule, it
# should not change the shell environment at all.
#
# .zprofile is basically the same as .zlogin except that it's sourced before
# .zshrc while .zlogin is sourced after .zshrc. According to the zsh
# documentation, ".zprofile is meant as an alternative to .zlogin for ksh fans;
# the two are not intended to be used together, although this could certainly be
# done if desired."
#
## Login shell custom commands and options
## This runs once when the system starts (at login)
## To reload: "exec zsh --login"

#-------------------------------------------------------------------------------
# Homebrew
#-------------------------------------------------------------------------------
# eval "$(/opt/homebrew/bin/brew shellenv)"

#-------------------------------------------------------------------------------
#               $PATH Updates
#-------------------------------------------------------------------------------
# NOTE: this is here because it must be loaded after homebrew is added to the
# path which is done in the .zprofile which loads after the .zshenv

# MacOS ships with an older version of Ruby which is built against an X86
# system rather than ARM i.e. for M1+. So replace the system ruby with an
# updated one from Homebrew and ensure it is before /usr/bin/ruby
# Prepend to PATH
# path=(
  # "$(brew --prefix)/opt/ruby/bin"
  # "$(brew --prefix)/lib/ruby/gems/3.0.0/bin"
  # NOTE: Add coreutils which make commands like ls run as they do on Linux rather than the BSD flavoured variant macos ships with
  # "$(brew --prefix)/opt/coreutils/libexec/gnubin"
  # $path
# )
# export MANPATH="$(brew --prefix)/opt/coreutils/libexec/gnuman:${MANPATH}"

function detect_platform {
  if [[ -z $PLATFORM ]]; then
    platform="unknown"
    derived_platform=$(uname | tr "[:upper:]" "[:lower:]")

    if [[ $derived_platform == "darwin" ]]; then
      platform="macos"
    elif [[ $derived_platform == "linux" ]]; then
      platform="linux"
    fi

    export PLATFORM=$platform

    # if [[ "$PLATFORM" == "linux" ]]; then
    #     # If available, use LSB to identify distribution
    #     if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
    #         export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
    #         # Otherwise, use release info file
    #     else
    #         export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
    #     fi
    # fi
    unset platform
    unset derived_platform
  fi
}
detect_platform

# this loads in all of our environment variables, etc.
source "$ZDOTDIR/lib/env.zsh"

# vim:ft=zsh:foldenable:foldmethod=marker:ts=2:sts=2:sw=2
