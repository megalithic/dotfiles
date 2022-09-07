# -- WORKING, not in ssh though; see @guysherman @ref below
# import re

# from kittens.tui.handler import result_handler
# from kitty.key_encoding import KeyEvent, parse_shortcut


# def is_window_vim(window, vim_id):
#     fp = window.child.foreground_processes
#     return any(
#         re.search(vim_id, p["cmdline"][0] if len(p["cmdline"]) else "", re.I)
#         for p in fp
#     )


# def encode_key_mapping(window, key_mapping):
#     mods, key = parse_shortcut(key_mapping)
#     event = KeyEvent(
#         mods=mods,
#         key=key,
#         shift=bool(mods & 1),
#         alt=bool(mods & 2),
#         ctrl=bool(mods & 4),
#         super=bool(mods & 8),
#         hyper=bool(mods & 16),
#         meta=bool(mods & 32),
#     ).as_window_system_event()

#     return window.encoded_key(event)


# def main():
#     pass


# @result_handler(no_ui=True)
# def handle_result(args, result, target_window_id, boss):
#     window = boss.window_id_map.get(target_window_id)
#     direction = args[2]
#     key_mapping = args[3]
#     vim_id = args[4] if len(args) > 4 else "n?vim"

#     if window is None:
#         return
#     if is_window_vim(window, vim_id):
#         encoded = encode_key_mapping(window, key_mapping)
#         window.write_to_child(encoded)
#     else:
#         boss.active_tab.neighboring_window(direction)


# @REF: from @guysherman
# - https://github.com/guysherman/dotfiles/commit/9f4cbe0d27efb216ece2b3b3dfcddaf891c82dff

import re

from kittens.tui.handler import result_handler
from kitty.key_encoding import KeyEvent, parse_shortcut


def is_cmdline_vim(window, vim_id):
    fp = window.child.foreground_processes
    print("CMDLINE:", fp)
    return any(
        re.search(vim_id, p["cmdline"][0] if len(p["cmdline"]) else "", re.I)
        for p in fp
    )


def is_title_vim(window, vim_id):
    title = window.child_title
    print("TITLE:", title)
    return re.search(vim_id, title, re.I)


def is_window_vim(window, vim_id):
    is_cmdline = is_cmdline_vim(window, vim_id)
    is_title = is_title_vim(window, vim_id)
    return is_cmdline or is_title


def encode_key_mapping(window, key_mapping):
    mods, key = parse_shortcut(key_mapping)
    event = KeyEvent(
        mods=mods,
        key=key,
        shift=bool(mods & 1),
        alt=bool(mods & 2),
        ctrl=bool(mods & 4),
        super=bool(mods & 8),
        hyper=bool(mods & 16),
        meta=bool(mods & 32),
    ).as_window_system_event()

    return window.encoded_key(event)


def main():
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    direction = args[2]
    key_mapping = args[3]
    vim_id = args[4] if len(args) > 4 else "n?vim"

    if window is None:
        return
    if is_window_vim(window, vim_id):
        encoded = encode_key_mapping(window, key_mapping)
        window.write_to_child(encoded)
    else:
        boss.active_tab.neighboring_window(direction)
