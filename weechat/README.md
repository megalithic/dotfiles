## Weechat

I use [weechat](https://weechat.org/) for a number of things..

- IRC ([ZNC](https://wiki.znc.in/ZNC))
- Slack ([wee_slack.py](https://github.com/wee-slack/wee-slack))
- Google Hangouts ([Bitlbee](https://www.bitlbee.org/) and [purple-hangouts](https://bitbucket.org/EionRobb/purple-hangouts/overview))

I have a pretty customized interface that doesn't have it's own compartmentalized theme file; all of the theming is combined into the various `*.conf` files. That said, the theme pretty well follows [this users' setup](https://gist.github.com/pascalpoitras/8406501), with some tweaks to more closely match the [nova](https://trevordmiller.com/projects/nova) theme.

For a full setup guide for connecting weechat to a Digital Ocean droplet running ZNC, Bitlbee, and Slack, [checkout the article I wrote](https://megalithic.io/thoughts/weechat-setup-with-irc-bitlbee-slack).

#### Installation

See my [`Brewfile`](https://github.com/megalithic/dotfiles/blob/master/homebrew/Brewfile)
for the options used for installing `weechat` via homebrew on macOS.

The nested `weechat.symlink` folder gets auto-symlinked to `~/.weechat` as part
of running [`_dotup`](https://github.com/megalithic/dotfiles/blob/master/bin/_dotup).


#### Notes

All sensitive data is kept encrypted using weechat's `/secure` API.

#### References

- https://megalithic.io/thoughts/weechat-setup-with-irc-bitlbee-slack
- https://demu.red/blog/2016/12/setting-up-sms-in-irc-via-bitlbee-with-purple-hangouts/#installing-bitlbee
- https://weechat.org/files/doc/stable/weechat_user.en.html#command_weechat_secure
