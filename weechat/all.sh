#!/usr/bin/env zsh

echo ""
echo ":: weechat setup things.."
echo ""


if (which mix &>/dev/null); then
  # install required plugin thingy for weechat > multiline.pl (perl script)
  cpan Pod::Select
fi
