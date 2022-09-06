import os
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Generic, Iterable, Iterator, List, Optional, Sequence, TypeVar, Union

from kittens.tui.handler import Handler
from kittens.tui.loop import Loop, debug
from kittens.tui.operations import styled
from kitty.boss import Boss, get_boss
from kitty.fast_data_types import get_options
from kitty.key_encoding import KeyEvent
from kitty.session import create_sessions
from pyfzf import FzfPrompt


@dataclass
class KittySession:
    path: Path

    def __str__(self):
        return self.path.stem


def find_session_files(directory: str) -> Iterable[Path]:
    return Path(directory).expanduser().glob("*.conf")


def main(args: List[str]) -> tuple:
    session_files = [KittySession(path) for path in find_session_files(args[1])]
    if session_files:
        fzf = FzfPrompt("/usr/local/bin/fzf")
        # selected_session = fzf.prompt(session_files)
        selected_session = fzf.prompt(
            session_files,
            '--prompt=" new or existing session  " --bind="enter:replace-query+print-query"',
        )
        if selected_session:
            selected_path = "{}/{}.conf".format(args[1], selected_session[0])
            # print("i hate python")
            # debug(selected_session)
            # debug(selected_path)
            return (selected_session, str(selected_path))

    raise SystemExit(1)


def handle_result(
    args: List[str], session_data: tuple, target_window_id: int, boss: Boss
) -> None:
    session_name, session_path = session_data
    # debug(session_name)
    # debug(session_path)
    startup_session = next(create_sessions(get_options(), default_session=session_path))

    # for os_window in boss.list_os_windows():
    #     print(os_window.wm_class)

    win_id = boss.add_os_window(startup_session)

    # for tab in tuple(self.os_window_map[win_id]):
    #     self._move_tab_to(tab, target_window_id)
