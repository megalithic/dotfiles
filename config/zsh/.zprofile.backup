# #!/usr/bin/env zsh
# # shellcheck shell=bash
# #
# # .zprofile is sourced on login shells and before .zshrc. As a general rule, it
# # should not change the shell environment at all.
# #
# # .zprofile is basically the same as .zlogin except that it's sourced before
# # .zshrc while .zlogin is sourced after .zshrc. According to the zsh
# # documentation, ".zprofile is meant as an alternative to .zlogin for ksh fans;
# # the two are not intended to be used together, although this could certainly be
# # done if desired."
# #
# ## Login shell custom commands and options
# ## This runs once when the system starts (at login)
# ## To reload: "exec zsh --login"

# #-------------------------------------------------------------------------------
# #               $PATH Updates
# #-------------------------------------------------------------------------------
# # NOTE: this is here because it must be loaded after homebrew is added to the
# # path which is done in the .zprofile which loads after the .zshenv

# # MacOS ships with an older version of Ruby which is built against an X86
# # system rather than ARM i.e. for M1+. So replace the system ruby with an
# # updated one from Homebrew and ensure it is before /usr/bin/ruby
# # Prepend to PATH

brew_prefix='/usr/local'
if [[ "$(arch)" == "arm64" ]]; then
  brew_prefix='/opt/homebrew'
  # eval $(/opt/homebrew/bin/brew shellenv)
# else
#   eval $(/usr/local/bin/brew shellenv)
fi

export BREW_PREFIX="${brew_prefix}"
export HOMEBREW_PREFIX="$BREW_PREFIX"

path=(
  "$BREW_PREFIX/opt/ruby/bin"
  "$BREW_PREFIX/lib/ruby/gems/3.0.0/bin"
  # NOTE: Add coreutils which make commands like ls run as they do on Linux rather than the BSD flavoured variant macos ships with
  "$BREW_PREFIX/opt/coreutils/libexec/gnubin"
  /nix/store/[^/]*/bin(Nn[-1]-/)
  $path
)

# export MANPATH="$BREW_PREFIX/opt/coreutils/libexec/gnuman:${MANPATH}"

# # this loads in all of our environment variables, etc.
# source "$ZDOTDIR/lib/env.zsh"

# # vim:ft=zsh:foldenable:foldmethod=marker:ts=2:sts=2:sw=2
#
#
