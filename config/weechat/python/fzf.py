from typing import Iterator, Tuple

import weechat

SCRIPT_NAME = "fzf"
SCRIPT_AUTHOR = "Trygve Aaberge <trygveaa@gmail.com>"
SCRIPT_VERSION = "0.1.0"
SCRIPT_LICENSE = "MIT"
SCRIPT_DESC = (
    "Switch buffer using fzf (currently only works inside tmux and kitty)"
)
REPO_URL = "https://github.com/trygveaa/weechat-fzf"


def print_log(message: str) -> None:
    weechat.prnt("", weechat.prefix("debug") + message)


def print_error(message: str) -> None:
    weechat.prnt("", weechat.prefix("error") + message)


def print_warn(message: str) -> None:
    weechat.prnt("", weechat.prefix("warning") + message)


def fzf_process_cb(
    data: str, command: str, return_code: int, out: str, err: str
) -> int:
    # print_log("Debugging.. data: {}".format(data))
    # print_log("Debugging.. command: {}".format(command))

    if (
        return_code == weechat.WEECHAT_HOOK_PROCESS_ERROR
        or return_code == 2
        or err
    ):
        print_error("Error running fzf (code {}): {}".format(return_code, err))
        return weechat.WEECHAT_RC_OK
    if out != "":
        # print_log("Debugging.. out: {}".format(out))

        pointer, _ = out.split("\t", 1)
        weechat.buffer_set(pointer, "display", "1")
    return weechat.WEECHAT_RC_OK


def fzf_tmux_command_cb(data: str, buffer: str, args: str) -> int:
    cmd = (
        "fzf-tmux -- --delimiter='\t' --with-nth=3.. "
        "--preview='tail -$LINES {2} 2>/dev/null'"
    )
    hook = weechat.hook_process_hashtable(
        cmd, {"stdin": "1"}, 0, "fzf_process_cb", ""
    )
    for buffer_info in buffers():
        weechat.hook_set(hook, "stdin", "\t".join(buffer_info) + "\n")
    weechat.hook_set(hook, "stdin_close", "")
    return weechat.WEECHAT_RC_OK


def fzf_kitty_command_cb(data: str, buffer: str, args: str) -> int:
    # "kitty @ launch --type=overlay --keep-focus --hold --stdin-source=@last_cmd_output --stdin-add-formatting--stdin-add-line-wrap-markers \""
    # cmd = (
    #     "kitty @ launch --type=overlay --keep-focus --hold "
    #     "fzf -- --delimiter='\t' --with-nth=3.. "
    #     "--preview='tail -$LINES {2} 2>/dev/null'"
    # )
    cmd = (
        "fzf-kitty -- --delimiter='\t' --with-nth=3.. "
        "--preview='tail -$LINES {2} 2>/dev/null'"
    )
    hook = weechat.hook_process_hashtable(
        cmd, {"stdin": "1"}, 0, "fzf_process_cb", ""
    )
    # print_log("Debugging.. hook: {}".format(hook))
    for buffer_info in buffers():
        weechat.hook_set(hook, "stdin", "\t".join(buffer_info) + "\n")
    weechat.hook_set(hook, "stdin_close", "")
    return weechat.WEECHAT_RC_OK


def buffers() -> Iterator[Tuple[str, str, str, str]]:
    logger_filenames = {}
    logger_infolist = weechat.infolist_get("logger_buffer", "", "")
    while weechat.infolist_next(logger_infolist):
        buffer = weechat.infolist_pointer(logger_infolist, "buffer")
        filename = weechat.infolist_string(logger_infolist, "log_filename")
        logger_filenames[buffer] = filename
    weechat.infolist_free(logger_infolist)

    buffer_infolist = weechat.infolist_get("buffer", "", "")
    while weechat.infolist_next(buffer_infolist):
        pointer = weechat.infolist_pointer(buffer_infolist, "pointer")
        number = weechat.infolist_integer(buffer_infolist, "number")
        name = weechat.infolist_string(buffer_infolist, "name")
        yield (pointer, logger_filenames.get(pointer, ""), str(number), name)
    weechat.infolist_free(buffer_infolist)


def main() -> None:
    if not weechat.register(
        SCRIPT_NAME,
        SCRIPT_AUTHOR,
        SCRIPT_VERSION,
        SCRIPT_LICENSE,
        SCRIPT_DESC,
        "",
        "",
    ):
        return

    tmux = weechat.string_eval_expression("${env:TMUX}", {}, {}, {})
    kitty = weechat.string_eval_expression("${env:KITTY_LISTEN_ON}", {}, {}, {})
    if tmux:
        weechat.hook_command(
            SCRIPT_NAME, SCRIPT_DESC, "", "", "", "fzf_tmux_command_cb", ""
        )
    elif kitty:
        weechat.hook_command(
            SCRIPT_NAME, SCRIPT_DESC, "", "", "", "fzf_kitty_command_cb", ""
        )
    else:
        print_error(
            "Error: fzf.py currently only supports being run inside tmux or kitty"
        )


if __name__ == "__main__":
    main()
