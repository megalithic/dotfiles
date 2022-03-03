from dataclasses import dataclass
from pathlib import Path
from typing import Generic, Iterable, Iterator, List, Sequence, TypeVar, Union

from kittens.tui.handler import Handler
from kittens.tui.loop import Loop
from kittens.tui.operations import styled
from kitty.boss import Boss
from kitty.fast_data_types import get_options
from kitty.key_encoding import KeyEvent
from kitty.session import create_sessions

Selectable = TypeVar("Selectable")


class Selection(Iterable[Selectable]):
    def __init__(self, items: Sequence[Selectable]):
        self.items = items
        self.selected_index = 0

    def __iter__(self) -> Iterator[Selectable]:
        for item in self.items:
            yield item

    def next(self) -> None:
        max_index = len(self.items) - 1
        self.selected_index = min(max_index, self.selected_index + 1)

    def prev(self) -> None:
        self.selected_index = max(0, self.selected_index - 1)

    @property
    def selected(self) -> Selectable:
        return self.items[self.selected_index]


class SelectHandler(Generic[Selectable], Handler):
    def __init__(self, items: Sequence[Selectable], msg: str = "Select item") -> None:
        self.msg = msg
        self.deselected = False
        self.selection = Selection[Selectable](items)

    @property
    def selected(self) -> Union[Selectable, None]:
        if self.deselected:
            return None
        return self.selection.selected

    def initialize(self) -> None:
        self.cmd.set_cursor_visible(False)
        self.draw_screen()

    def quit_without_selection(self) -> None:
        self.deselected = True
        self.quit_loop(0)

    def select_next(self) -> None:
        self.selection.next()
        self.draw_screen()

    def select_prev(self) -> None:
        self.selection.prev()
        self.draw_screen()

    def draw_screen(self) -> None:
        self.cmd.clear_screen()
        print = self.print
        print(styled(self.msg, bold=True, fg="gray", fg_intense=True))
        print()
        for item in self.selection:
            if item == self.selected:
                to_print = styled(item, bg="yellow", fg="black")
            else:
                to_print = item
            print(f"   {to_print}")
        print()
        print("↑: {}".format(styled("Up/K", italic=True)))
        print("↓: {}".format(styled("Down/J", italic=True)))
        print("Select: {}".format(styled("Enter", italic=True)))
        print("Exit: {}".format(styled("Esc/Q", italic=True)))

    def on_key(self, key_event: KeyEvent) -> None:
        key = key_event.key
        if key in ("DOWN", "j"):
            self.select_next()
        if key in ("UP", "k"):
            self.select_prev()
        if key == "ENTER":
            self.quit_loop(0)
        elif key in ("ESCAPE", "q"):
            self.quit_without_selection()


@dataclass
class KittySession:
    path: Path

    def __str__(self):
        return self.path.stem


def find_session_files(directory: str) -> Iterable[Path]:
    return Path(directory).expanduser().glob("*.conf")


def main(args: List[str]) -> str:
    session_files = [KittySession(path) for path in find_session_files(args[1])]
    if session_files:
        loop = Loop()
        handler = SelectHandler(session_files, msg="Select session to start")
        loop.loop(handler)
        selected = handler.selected
        if selected:
            return str(selected.path)
    raise SystemExit(1)


def handle_result(
    args: List[str], session_file_path: str, target_window_id: int, boss: Boss
) -> None:
    startup_session = next(
        create_sessions(get_options(), default_session=session_file_path)
    )
    boss.add_os_window(startup_session)
