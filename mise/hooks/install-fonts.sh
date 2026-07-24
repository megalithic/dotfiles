#!/bin/sh
# Install Nerd Fonts into ~/Library/Fonts. Driven by [vars].nerd_fonts in
# mise/config/mise/global_config.toml via [tasks."fonts:install"].
#
# Usage: install-fonts.sh <FontAssetStem>...
#   e.g. install-fonts.sh JetBrainsMono NerdFontsSymbolsOnly
#   Names are release asset stems: <Name>.tar.xz on
#   https://github.com/ryanoasis/nerd-fonts/releases
#
# Env:
#   NERD_FONTS_VERSION  release tag without the v prefix (e.g. 3.4.0);
#                       "latest" or unset uses the latest-release redirect.
#
# Idempotent two ways: a per-font version marker in $XDG_STATE_HOME skips
# downloads entirely, and cmp-based copies only touch changed font files.
set -eu

dest="$HOME/Library/Fonts"
state="${XDG_STATE_HOME:-$HOME/.local/state}/nerd-fonts"
version="${NERD_FONTS_VERSION:-latest}"
mkdir -p "$dest" "$state"

[ "$#" -gt 0 ] || {
	echo "install-fonts: no fonts given" >&2
	exit 1
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

total=0
for font in "$@"; do
	marker="$state/$font"
	if [ -f "$marker" ] && [ "$(cat "$marker")" = "$version" ] && [ "$version" != "latest" ]; then
		echo "install-fonts: $font $version already installed, skipping"
		continue
	fi

	if [ "$version" = "latest" ]; then
		url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.tar.xz"
	else
		url="https://github.com/ryanoasis/nerd-fonts/releases/download/v$version/$font.tar.xz"
	fi

	echo "install-fonts: downloading $font ($version)"
	extract="$tmp/$font"
	mkdir -p "$extract"
	curl -fsSL "$url" -o "$tmp/$font.tar.xz"
	tar -xJf "$tmp/$font.tar.xz" -C "$extract"

	copied=0
	for f in "$extract"/*.ttf "$extract"/*.otf; do
		[ -e "$f" ] || continue
		base=$(basename "$f")
		if ! cmp -s "$f" "$dest/$base" 2>/dev/null; then
			cp -f "$f" "$dest/$base"
			copied=$((copied + 1))
		fi
	done
	printf '%s\n' "$version" >"$marker"
	total=$((total + copied))
	echo "install-fonts: $font -> $copied font file(s) copied"
done

echo "install-fonts: done, $total font file(s) copied to $dest"
