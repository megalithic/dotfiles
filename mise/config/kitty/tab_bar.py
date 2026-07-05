import json
import subprocess
from collections import defaultdict
from datetime import datetime, timezone

from kitty.boss import get_boss
from kitty.fast_data_types import Screen, add_timer
from kitty.rgb import Color
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    Formatter,
    TabBarData,
    as_rgb,
    draw_attributed_string,
    draw_title,
)
from kitty.utils import color_as_int

timer_id = None

ICON = "  "
RIGHT_MARGIN = 1
REFRESH_TIME = 15

icon_fg = as_rgb(color_as_int(Color(255, 250, 205)))
icon_bg = as_rgb(color_as_int(Color(47, 61, 68)))
# OR icon_bg = as_rgb(0x2f3d44)
bat_text_color = as_rgb(0x999F93)
clock_color = as_rgb(0x7FBBB3)
dnd_color = as_rgb(0x465258)
sep_color = as_rgb(0x999F93)
utc_color = as_rgb(color_as_int(Color(113, 115, 116)))


# cells = [
#     (Color(113, 115, 116), dnd),
#     (Color(135, 192, 149), clock),
#     (Color(113, 115, 116), utc),
# ]


def calc_draw_spaces(*args) -> int:
    length = 0
    for i in args:
        if not isinstance(i, str):
            i = str(i)
        length += len(i)
    return length


def _draw_icon(screen: Screen, index: int) -> int:
    if index != 1:
        return 0

    fg, bg = screen.cursor.fg, screen.cursor.bg
    screen.cursor.fg = icon_fg
    screen.cursor.bg = icon_bg
    screen.draw(ICON)
    screen.cursor.fg, screen.cursor.bg = fg, bg
    screen.cursor.x = len(ICON)
    return screen.cursor.x


def _draw_left_status(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    # print(extra_data)
    if draw_data.leading_spaces:
        screen.draw(" " * draw_data.leading_spaces)

    # TODO: https://github.com/kovidgoyal/kitty/discussions/4447#discussioncomment-2463083
    # tm = get_boss().active_tab_manager
    #     if tm is not None:
    #         w = tm.active_window
    #         if w is not None:
    #             cwd = w.cwd_of_child or ''
    #             log_error(cwd)

    draw_title(draw_data, screen, tab, index)
    trailing_spaces = min(max_title_length - 1, draw_data.trailing_spaces)
    max_title_length -= trailing_spaces
    extra = screen.cursor.x - before - max_title_length
    if extra > 0:
        screen.cursor.x -= extra + 1
        screen.draw("…")
    if trailing_spaces:
        screen.draw(" " * trailing_spaces)
    end = screen.cursor.x
    screen.cursor.bold = screen.cursor.italic = False
    screen.cursor.fg = 0
    if not is_last:
        screen.cursor.bg = as_rgb(color_as_int(draw_data.inactive_bg))
        screen.draw(draw_data.sep)
    screen.cursor.bg = 0
    return end


def _get_dnd_status():
    result = subprocess.run("~/.dotfiles/bin/dnd -k", shell=True, capture_output=True)
    status = ""

    if result.stderr:
        raise subprocess.CalledProcessError(
            returncode=result.returncode, cmd=result.args, stderr=result.stderr
        )

    if result.stdout:
        status = result.stdout.decode("utf-8").strip()

    return status


# more handy kitty tab_bar things:
# REF: https://github.com/kovidgoyal/kitty/discussions/4447#discussioncomment-2183440
def _draw_right_status(screen: Screen, is_last: bool) -> int:
    if not is_last:
        return 0
    # global timer_id
    # if timer_id is None:
    #     timer_id = add_timer(_redraw_tab_bar, REFRESH_TIME, True)

    draw_attributed_string(Formatter.reset, screen)

    clock = datetime.now().strftime("%H:%M")
    utc = datetime.now(timezone.utc).strftime(" (UTC %H:%M)")
    dnd = _get_dnd_status()

    cells = []
    if dnd != "":
        cells.append((dnd_color, dnd))
        cells.append((sep_color, " ⋮ "))

    cells.append((clock_color, clock))
    cells.append((utc_color, utc))

    # right_status_length = calc_draw_spaces(dnd + " " + clock + " " + utc)

    right_status_length = RIGHT_MARGIN
    for cell in cells:
        right_status_length += len(str(cell[1]))

    draw_spaces = screen.columns - screen.cursor.x - right_status_length

    if draw_spaces > 0:
        screen.draw(" " * draw_spaces)

    screen.cursor.fg = 0
    for color, status in cells:
        screen.cursor.fg = color  # as_rgb(color_as_int(color))
        screen.draw(status)
    screen.cursor.bg = 0

    if screen.columns - screen.cursor.x > right_status_length:
        screen.cursor.x = screen.columns - right_status_length

    return screen.cursor.x


# REF: https://github.com/kovidgoyal/kitty/discussions/4447#discussioncomment-1940795
# def _redraw_tab_bar():
#     tm = get_boss().active_tab_manager
#     if tm is not None:
#         tm.mark_tab_bar_dirty()


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:

    _draw_icon(screen, index)
    _draw_left_status(
        draw_data,
        screen,
        tab,
        before,
        max_title_length,
        index,
        is_last,
        extra_data,
    )
    _draw_right_status(
        screen,
        is_last,
    )

    return screen.cursor.x


# # pyright: reportMissingImports=false

# # REF: https://github.com/kovidgoyal/kitty/discussions/4447#discussioncomment-3240635
# import subprocess
# from datetime import datetime, timezone
# from pprint import pprint

# # from kitty.boss import get_boss
# from kitty.fast_data_types import Screen, add_timer, get_boss, get_options
# from kitty.rgb import Color
# from kitty.tab_bar import (
#     DrawData,
#     ExtraData,
#     Formatter,
#     TabBarData,
#     as_rgb,
#     draw_attributed_string,
#     draw_title,
# )
# from kitty.utils import color_as_int

# opts = get_options()
# icon_fg = as_rgb(color_as_int(Color(255, 250, 205)))
# icon_bg = as_rgb(color_as_int(Color(47, 61, 68)))
# # OR icon_bg = as_rgb(0x2f3d44)
# bat_text_color = as_rgb(0x999F93)
# clock_color = as_rgb(0x7FBBB3)
# utc_color = as_rgb(color_as_int(Color(113, 115, 116)))

# # BATTERY_CMD = "pmset -g batt | awk -F '; *' 'NR==2 { print $2 }'"
# SEPARATOR_SYMBOL, SOFT_SEPARATOR_SYMBOL = ("", "")
# RIGHT_MARGIN = 1
# REFRESH_TIME = 5
# ICON = "  "
# UNPLUGGED_ICONS = {
#     10: "",
#     20: "",
#     30: "",
#     40: "",
#     50: "",
#     60: "",
#     70: "",
#     80: "",
#     90: "",
#     100: "",
# }
# PLUGGED_ICONS = {
#     1: "",
# }
# UNPLUGGED_COLORS = {
#     15: as_rgb(color_as_int(opts.color1)),
#     16: as_rgb(color_as_int(opts.color15)),
# }
# PLUGGED_COLORS = {
#     15: as_rgb(color_as_int(opts.color1)),
#     16: as_rgb(color_as_int(opts.color6)),
#     99: as_rgb(color_as_int(opts.color6)),
#     100: as_rgb(0xA7C080),
# }


# def _draw_icon(screen: Screen, index: int) -> int:
#     if index != 1:
#         return 0
#     fg, bg = screen.cursor.fg, screen.cursor.bg
#     screen.cursor.fg = icon_fg
#     screen.cursor.bg = icon_bg
#     screen.draw(ICON)
#     screen.cursor.fg, screen.cursor.bg = fg, bg
#     screen.cursor.x = len(ICON)
#     return screen.cursor.x


# def _draw_left_status(
#     draw_data: DrawData,
#     screen: Screen,
#     tab: TabBarData,
#     before: int,
#     max_title_length: int,
#     index: int,
#     is_last: bool,
#     extra_data: ExtraData,
# ) -> int:
#     if screen.cursor.x >= screen.columns - right_status_length:
#         return screen.cursor.x
#     tab_bg = screen.cursor.bg
#     tab_fg = screen.cursor.fg
#     default_bg = as_rgb(int(draw_data.default_bg))
#     if extra_data.next_tab:
#         next_tab_bg = as_rgb(draw_data.tab_bg(extra_data.next_tab))
#         needs_soft_separator = next_tab_bg == tab_bg
#     else:
#         next_tab_bg = default_bg
#         needs_soft_separator = False
#     if screen.cursor.x <= len(ICON):
#         screen.cursor.x = len(ICON)
#     # screen.draw(" ")
#     screen.cursor.bg = tab_bg

#     # @REF: https://github.com/kovidgoyal/kitty/discussions/4447#discussioncomment-3459140
#     # title = f"{opts.os_window_class}{tab.title}"
#     # tab = TabBarData(
#     #     title,
#     #     tab.is_active,
#     #     tab.needs_attention,
#     #     tab.num_windows,
#     #     tab.num_window_groups,
#     #     tab.layout_name,
#     #     tab.has_activity_since_last_focus,
#     #     tab.active_fg,
#     #     tab.active_bg,
#     #     tab.inactive_fg,
#     #     tab.inactive_bg,
#     # )
#     # pprint(dir(tab))
#     # pprint(vars(screen))
#     draw_title(draw_data, screen, tab, index)

#     if not needs_soft_separator:
#         # screen.draw(" ")
#         screen.cursor.fg = tab_bg
#         screen.cursor.bg = next_tab_bg
#         # screen.draw(SEPARATOR_SYMBOL)
#     else:
#         prev_fg = screen.cursor.fg
#         if tab_bg == tab_fg:
#             screen.cursor.fg = default_bg
#         elif tab_bg != default_bg:
#             c1 = draw_data.inactive_bg.contrast(draw_data.default_bg)
#             c2 = draw_data.inactive_bg.contrast(draw_data.inactive_fg)
#             if c1 < c2:
#                 screen.cursor.fg = default_bg
#         # screen.draw(" " + SOFT_SEPARATOR_SYMBOL)
#         screen.cursor.fg = prev_fg
#     end = screen.cursor.x
#     return end


# def _draw_right_status(screen: Screen, is_last: bool, cells: list) -> int:
#     if not is_last:
#         return 0
#     draw_attributed_string(Formatter.reset, screen)
#     screen.cursor.x = screen.columns - right_status_length
#     screen.cursor.fg = 0
#     for color, status in cells:
#         screen.cursor.fg = color
#         screen.draw(status)
#     screen.cursor.bg = 0
#     return screen.cursor.x


# def _redraw_tab_bar(_):
#     tm = get_boss().active_tab_manager
#     if tm is not None:
#         tm.mark_tab_bar_dirty()


# def get_battery_cells() -> list:
#     s_result = subprocess.run(
#         "~/.dotfiles/bin/btry -s", shell=True, capture_output=True
#     )
#     status = ""

#     if s_result.stderr:
#         raise subprocess.CalledProcessError(
#             returncode=s_result.returncode, cmd=s_result.args, stderr=s_result.stderr
#         )

#     if s_result.stdout:
#         status = s_result.stdout.decode("utf-8").strip()

#     p_result = subprocess.run(
#         "~/.dotfiles/bin/btry -p", shell=True, capture_output=True
#     )
#     percent = ""

#     if p_result.stderr:
#         raise subprocess.CalledProcessError(
#             returncode=p_result.returncode, cmd=p_result.args, stderr=p_result.stderr
#         )

#     if p_result.stdout:
#         percent = int(p_result.stdout.decode("utf-8").strip())

#     if status == "Discharging \n":
#         # TODO: declare the lambda once and don't repeat the code
#         icon_color = UNPLUGGED_COLORS[
#             min(UNPLUGGED_COLORS.keys(), key=lambda x: abs(x - percent))
#         ]
#         icon = UNPLUGGED_ICONS[
#             min(UNPLUGGED_ICONS.keys(), key=lambda x: abs(x - percent))
#         ]
#     elif status == "Not charging \n":
#         icon_color = UNPLUGGED_COLORS[
#             min(UNPLUGGED_COLORS.keys(), key=lambda x: abs(x - percent))
#         ]
#         icon = PLUGGED_ICONS[min(PLUGGED_ICONS.keys(), key=lambda x: abs(x - percent))]
#     else:
#         icon_color = PLUGGED_COLORS[
#             min(PLUGGED_COLORS.keys(), key=lambda x: abs(x - percent))
#         ]
#         icon = PLUGGED_ICONS[min(PLUGGED_ICONS.keys(), key=lambda x: abs(x - percent))]

#     percent_cell = (bat_text_color, " " + str(percent) + "%")
#     icon_cell = (icon_color, icon)
#     return [icon_cell, percent_cell]


# timer_id = None
# right_status_length = -1


# def draw_tab(
#     draw_data: DrawData,
#     screen: Screen,
#     tab: TabBarData,
#     before: int,
#     max_title_length: int,
#     index: int,
#     is_last: bool,
#     extra_data: ExtraData,
# ) -> int:
#     # pprint(vars(get_boss()))
#     global timer_id
#     global right_status_length
#     # if timer_id is None:
#     #     timer_id = add_timer(_redraw_tab_bar, REFRESH_TIME, True)

#     date = datetime.now().strftime("%d.%m.%Y")
#     clock = datetime.now().strftime("%H:%M")
#     utc = datetime.now(timezone.utc).strftime(" (UTC %H:%M)")

#     cells = get_battery_cells()
#     cells.append((as_rgb(color_as_int(opts.color255)), " ⋮ "))
#     cells.append((clock_color, clock))
#     cells.append((utc_color, utc))

#     right_status_length = RIGHT_MARGIN
#     for cell in cells:
#         right_status_length += len(str(cell[1]))

#     _draw_icon(screen, index)
#     _draw_left_status(
#         draw_data,
#         screen,
#         tab,
#         before,
#         max_title_length,
#         index,
#         is_last,
#         extra_data,
#     )
#     _draw_right_status(
#         screen,
#         is_last,
#         cells,
#     )
#     return screen.cursor.x
