#!/bin/zsh

echo "## NODE..."

echo "Installing `n` (my preferred node version manager)..."

rm -rf $HOMEDIR/.n
rm -rf $HOMEDIR/n
curl -L https://git.io/n-install | bash -s -- -y lts # this installs `n` && node lts
export N_PREFIX="$HOMEDIR/.n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"  # Added by n-install (see http://git.io/n-install-repo).

echo "Installing node packages..."
$DOTS/node/package-installer

echo "Setting up `avn` (automatic node version loader)..."
[[ -s "$HOMEDIR/.avn/bin/avn.sh" ]] && source "$HOMEDIR/.avn/bin/avn.sh" # source avn
avn setup
