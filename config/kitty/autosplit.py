import array, fcntl, sys, termios
from kitty.boss import Boss
from typing import List

def main(args: List[str]) -> str:
    buf = array.array('H', [0, 0, 0, 0])
    fcntl.ioctl(sys.stdout, termios.TIOCGWINSZ, buf)
    height = buf[2]
    width = buf[3]
    if height <= width:
        return '--location=hsplit'
    else:
        return '--location=vsplit'

def handle_result(args: List[str], split: str, target_window_id: int, boss: Boss) -> None:
    boss.launch(split)