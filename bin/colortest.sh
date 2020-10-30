#!/bin/bash

echo "Kitty version: $( /Applications/kitty.app/Contents/MacOS/kitty --version )"

tmux_version=$(tmux -V)
echo "tmux version: $tmux_version"

echo -n 'This should show a neat truecolor rainbow, '
if [[ "$tmux_version" == "tmux 3.2-rc2" ]]; then
    echo 'but does not :/'
else
    echo 'and does:'
fi
awk 'BEGIN{
    s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
    for (colnum = 0; colnum<77; colnum++) {
        r = 255-(colnum*255/76);
        g = (colnum*510/76);
        b = (colnum*255/76);
        if (g>255) g = 510-g;
        printf "\033[48;2;%d;%d;%dm", r,g,b;
        printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
        printf "%s\033[0m", substr(s,colnum+1,1);
    }
    printf "\n";
}'
echo 'Press CTRL+C to quit test.'
sleep inf
