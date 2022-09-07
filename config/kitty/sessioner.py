# TODO: I have a LOT of unnecessary imports; clean this up!

import os
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import (
    Generic,
    Iterable,
    Iterator,
    List,
    Optional,
    Sequence,
    TypeVar,
    Union,
)

from kittens.tui.handler import Handler, result_handler
from kittens.tui.loop import Loop, debug
from kittens.tui.operations import styled
from kitty.boss import Boss, get_boss
from kitty.fast_data_types import get_options
from kitty.key_encoding import KeyEvent
from kitty.session import create_sessions
from pyfzf import FzfPrompt

DEFAULT_SESSION_PATH = "~/.config/kitty/sessions"
DEFAULT_SESSION_EXT = "conf"
DEFAULT_FZF_PATH = "/usr/local/bin/fzf"
DEFAULT_FZF_PROMPT = " new or existing session  "


@dataclass
class KittySession:
    path: Path

    def __str__(self):
        return self.path.stem


def find_session_files(directory: str) -> Iterable[Path]:
    return Path(directory).expanduser().glob("*.{}".format(DEFAULT_SESSION_EXT))


def main(args: List[str]) -> tuple:
    # ensure we can start this with a default sessions file path
    if args is None or len(args) <= 1:
        session_files_path_arg = DEFAULT_SESSION_PATH
    else:
        session_files_path_arg = args[1]

    session_files = [
        KittySession(path) for path in find_session_files(session_files_path_arg)
    ]

    if session_files:
        fzf = FzfPrompt(DEFAULT_FZF_PATH)
        selected_session = fzf.prompt(
            session_files,
            '--prompt="{}" --bind="enter:replace-query+print-query"'.format(
                DEFAULT_FZF_PROMPT
            ),
        )
        if selected_session:
            selected_path = "{}/{}.{}".format(
                session_files_path_arg, selected_session[0], DEFAULT_SESSION_EXT
            )

            return (selected_session[0], str(selected_path))

    raise SystemExit(1)


# @result_handler(no_ui=True)
def handle_result(
    args: List[str], session_data: tuple, target_window_id: int, boss: Boss
) -> None:
    # tuple containing our selected session name and path
    session_name, session_path = session_data
    startup_session = next(
        create_sessions(get_options(), default_session=session_path)
    )

    # close current os_window; note: we're ok doing this here as we use tmux for longer running processes.
    boss.close_os_window()

    # open new os_window from our chosen session name and file path (to the session .conf file)
    os_win_id = boss.add_os_window(
        startup_session=startup_session,
        wclass=session_name,
        wname=session_name,
        override_title="{}-session".format(session_name),
    )
