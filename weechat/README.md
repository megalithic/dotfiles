### Weechat

I use [weechat](https://weechat.org/) for a number of things..

- IRC (ZNC)
- Slack ([wee_slack.py](https://github.com/wee-slack/wee-slack))
- GTalk ([Bitlbee](https://www.bitlbee.org/))

I have a pretty customized interface, that doesn't have it's own
compartmentalized theme file, it's just all included in my various
confs. It pretty well follows [this users's setup](https://gist.github.com/pascalpoitras/8406501).

I use weechat's `secure` facilities to keep sensitive data encrypted.

#### Installation

See my [`Brewfile`](https://github.com/megalithic/dotfiles/blob/master/homebrew/Brewfile)
for the options used for installing `weechat` via homebrew.

This nested `weechat.symlink` folder gets auto-symlinked to `~/.weechat` as part
of running [`_dotup`](https://github.com/megalithic/dotfiles/blob/master/bin/_dotup).
