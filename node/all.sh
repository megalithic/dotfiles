#!/usr/bin/env zsh

echo ""
echo ":: setting up node..."
echo ""
echo ":: installing n (my preferred node version manager)..."
rm -rf "$HOME/.n"
rm -rf "$HOME/n"
rm /usr/local/bin/n

curl -L https://git.io/n-install | bash -s -- -y lts # this installs `n` && node lts
export N_PREFIX="$HOME/.n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"  # Added by n-install (see http://git.io/n-install-repo).

source "$HOME/.zshrc"
n lts # always make sure we have lts loaded

echo ""
echo ":: installing node packages..."
"$DOTS/node/package-installer"

echo ""
echo ":: setting up `avn` (automatic node version loader)..."
[[ -s "$HOME/.avn/bin/avn.sh" ]] && source "$HOME/.avn/bin/avn.sh" # source avn
avn setup
