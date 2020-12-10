# -*- coding: utf-8 -*-
#
# Insert unicode faces into weechat
#
# Usage: /emote name
#
# History:
#
# Version 1.0.0: initial release

import weechat

mappings = {
    "disapproval": "ಠ_ಠ",
    "doubleflip": "┻━┻ ︵ \(°□°)/ ︵ ┻━┻",
    "shrug": "¯\_(ツ)_/¯",
    "tableflip": "(╯°□°）╯︵ ┻━┻",
}


def emote(data, buf, args):
    try:
        key = args.split()[0]
        value = mappings[key]
        weechat.buffer_set(buf, "input", value)
        weechat.buffer_set(buf, "input_pos", str(len(value)))
    except (IndexError, KeyError):
        pass

    return weechat.WEECHAT_RC_OK


def main():
    if not weechat.register("emote", "Keith Smiley", "1.0.0", "MIT",
                            "Paste awesome unicode!", "", ""):
        return weechat.WEECHAT_RC_ERROR

    weechat.hook_command("emote", "Paste awesome unicode!", "", "",
                         "|".join(mappings.keys()), "emote", "")

if __name__ == "__main__":
    main()
