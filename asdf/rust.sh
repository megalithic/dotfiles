
#!/usr/bin/env zsh

# super verbose debugging of the running script:
# set -x

echo ""
echo ":: setting up rust things"
echo "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"
echo "▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔";

if (which rustup &>/dev/null); then
  echo ":: attempting to install rust/rustup things"
  echo ""

  rustup install stable
  rustup default stable
else
  echo ""
  echo ":: ERROR: unable to run rustup command; likely rust/rustup isn't installed or in your PATH"
  echo ""
fi
