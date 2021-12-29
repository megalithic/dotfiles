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

#### Debugging

- `/debug libs` -> shows you which core libraries/dependencies are being used by
  weechat; e.g., python, etc

If you end up having weird issues with python scripts not loading fully; likely
weechat switched to wanting a different version of python, e.g., weechat 2.9 -> 2.9.1
switched to using python 3.9.0 from python 3.8.6 and this caused issues. For me,
uninstalling both python and weechat, then reinstalling python, then my pip3 packages
then weechat. Still not perfect solution. I was using asdf to manage python versions
but it looks like weechat wants system installed things and homebrew's black
magic seems to handle linking things right to where weechat works with it.

##### Issues

- If you have perl issues, see this: https://github.com/NixOS/nixpkgs/issues/106506#issuecomment-795775642
  - `brew install perl && cpan install Pod::Parser`

#### References

- https://megalithic.io/thoughts/weechat-setup-with-irc-bitlbee-slack
- https://demu.red/blog/2016/12/setting-up-sms-in-irc-via-bitlbee-with-purple-hangouts/#installing-bitlbee
- https://weechat.org/files/doc/stable/weechat_user.en.html#command_weechat_secure
- https://www.weechat.org/files/doc/stable/weechat_user.en.html#secured_data
- http://www.futurile.net/2020/11/30/weechat-for-slack/
- http://www.futurile.net/2020/12/01/weechat-even-more-configuration-for-irc-and-slack/
- https://gist.github.com/pascalpoitras/8406501
- https://i.pinimg.com/originals/f6/bb/c6/f6bbc677af6291972006bdd08e297068.png

#### TODO

- [x] implement [SASL support for weechat](https://freenode.net/kb/answer/weechat)
