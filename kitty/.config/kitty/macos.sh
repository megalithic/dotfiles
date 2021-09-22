# https://github.com/DinkDonk/kitty-icon#installation
cp ./kitty-dark.icns /Applications/kitty.app/Contents/Resources/kitty.icns

rm /var/folders/*/*/*/com.apple.dock.iconcache

killall Dock
