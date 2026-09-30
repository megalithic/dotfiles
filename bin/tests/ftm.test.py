"""Isolated ftm CLI regressions. Run with: python3 -B bin/tests/ftm.test.py"""

import base64
import fcntl
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import termios
import threading
import unittest


BIN = Path(__file__).resolve().parent.parent
BASH = os.environ.get("FTM_TEST_BASH") or shutil.which("bash") or "/bin/bash"
FZF = shutil.which("fzf")
FAKE_COMMAND = r'''
import glob
import json
import os
from pathlib import Path
import sys

name = Path(sys.argv[0]).name
args = sys.argv[1:]
root = Path(os.environ["FIXTURE"])
with (root / "calls").open("a") as log:
    log.write(json.dumps({"command": name, "args": args, "cwd": os.getcwd(),
                          "git_worktree": os.environ.get("GIT_WORKTREE")}) + "\n")

def option(flag, default=""):
    return args[args.index(flag) + 1] if flag in args else default

if name == "wt":
    if args == ["open", "."]:
        sys.exit(int(os.environ.get("WT_EXIT", "0")))
    sys.exit(45)
elif name == "zoxide":
    if args == ["query", "-l"]:
        sys.exit(0)
    if os.environ.get("ZOXIDE_PATH"):
        print(os.environ["ZOXIDE_PATH"])
    else:
        sys.exit(1)
elif name == "trash":
    if os.environ.get("TRASH_FAIL"):
        sys.exit(23)
    if os.environ.get("TRASH_NOOP"):
        sys.exit(0)
    for arg in args:
        if arg == "--":
            continue
        pattern = ""
        index = 0
        while index < len(arg):
            if arg[index] == "\\" and index + 1 < len(arg):
                index += 1
                pattern += glob.escape(arg[index])
            else:
                pattern += arg[index]
            index += 1
        for match in glob.glob(pattern):
            path = Path(match)
            path.rename(root / "trashed" / path.name)
elif name == "fzf":
    (root / "picker-rows").write_text(sys.stdin.read())
    print(os.environ.get("FZF_OUTPUT", ""), end="")
elif name == "ftm-grid-preview":
    if not args or args[0] != "--manifest-panes":
        print("grid-preview")
elif name == "mise":
    sys.exit(1)
elif name == "ps":
    sys.exit(0)
elif name == "tmux":
    state_file = root / "sessions.json"
    state = json.loads(state_file.read_text())
    command = args[0]
    target = option("-t")
    session = next((s for s in state.values() if s["id"] == target), None)
    if command == "list-sessions":
        for key, value in state.items():
            fmt = option("-F")
            if fmt == "#S":
                print(key)
            elif "session_last_attached" in fmt:
                print("100 " + key)
            else:
                print(value["id"] + " " + key)
    elif command == "show-options":
        pass
    elif command == "kill-session":
        if session is None:
            sys.exit(1)
        state = {k: v for k, v in state.items() if v["id"] != target}
        state_file.write_text(json.dumps(state))
    elif command == "display-message":
        values = {"#{session_path}": session["cwd"] if session else str(root),
                  "#{window_index}": "0", "#{window_id}": "@1",
                  "#{pane_id}": "%1", "#{pane_dead}": "0",
                  "#{pane_current_command}": "bash", "#{client_width}": "100",
                  "#S": "current"}
        print(values.get(args[-1], ""))
    elif command == "list-windows":
        if "window_layout" in option("-F"):
            print("0\tcode\tlayout\t1\t0")
        else:
            print("@1 code\n@3 services" if os.environ.get("MISSING_AGENT")
                  else "@1 code\n@2 agent\n@3 services")
    elif command == "new-window":
        print("@4")
    elif command == "send-keys":
        pass
    elif command == "list-panes":
        print("0\t" + str(root) + "\tbash\t-\t/dev/fake\t1")
    elif command == "new-session":
        state[option("-s")] = {"id": "$99", "cwd": option("-c")}
        state_file.write_text(json.dumps(state))
    elif command in ("set-option", "setenv", "switch-client", "attach-session",
                     "select-window", "select-pane", "select-layout", "respawn-pane",
                     "rename-session"):
        pass
    else:
        print("Unexpected fake tmux command: " + repr(args), file=sys.stderr)
        sys.exit(90)
else:
    sys.exit(91)
'''


class FtmTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="ftm-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.home = self.root / "home"
        self.bin = self.home / ".dotfiles" / "bin"
        self.state = self.root / "state"
        self.layouts = self.root / "layouts"
        for directory in (self.bin, self.state / "snapshots", self.layouts,
                          self.root / "trashed", self.home / "code"):
            directory.mkdir(parents=True)
        (self.bin / "bash").symlink_to(BASH)
        self.ftm = self.bin / "ftm"
        shutil.copy2(BIN / "ftm", self.ftm)
        shutil.copy2(BIN / "wt-lock-lib", self.bin / "wt-lock-lib")
        for name in ("tmux", "wt", "zoxide", "trash", "fzf", "mise", "ps",
                     "ftm-grid-preview"):
            path = self.bin / name
            path.write_text("#!" + sys.executable + "\n" + FAKE_COMMAND)
            path.chmod(0o755)
        self.env = {
            "PATH": str(self.bin) + ":/usr/bin:/bin",
            "HOME": str(self.home),
            "FIXTURE": str(self.root),
            "FTM_STATE_DIR": str(self.state),
            "PI_STATE_DIR": str(self.root / "pi"),
            "TMUX_LAYOUTS": str(self.layouts),
            "TMUX": "fake-server,1,0",
            "GIT_WORKTREE": "inherited-wrong-worktree",
            "GIT_CONFIG_NOSYSTEM": "1",
            "LC_ALL": "C",
        }
        self.set_sessions({})

    def set_sessions(self, sessions):
        (self.root / "sessions.json").write_text(json.dumps(sessions))

    def calls(self, command):
        log = self.root / "calls"
        return [call for line in log.read_text().splitlines()
                if (call := json.loads(line))["command"] == command] if log.exists() else []

    def run_ftm(self, *args, expected=0):
        result = subprocess.run([BASH, str(self.ftm), *args], env=self.env,
                                cwd=self.root, text=True, capture_output=True, timeout=15)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def seed_removal(self, live=True, name=".repo[one]*"):
        self.name = name
        self.snapshot = self.state / "snapshots" / name
        self.snapshot.write_text("old snapshot\n")
        self.other_snapshot = self.state / "snapshots" / (name + "-other")
        self.other_snapshot.write_text("unrelated snapshot\n")
        self.glob_neighbor = ".repoo" if name == ".repo[one]*" else "alphabet"
        self.glob_snapshot = self.state / "snapshots" / self.glob_neighbor
        self.glob_snapshot.write_text("glob neighbor snapshot\n")
        self.kept_recent = f"{name}-other\t/other\n{self.glob_neighbor}\t/other\nother\t/{name}\n"
        self.recent = self.state / "recent"
        self.recent.write_text(f"{name}\t/first\n" + self.kept_recent +
                               f"{name}\n{name}\t/second\n")
        sessions = {name + "-other": {"id": "$8", "cwd": str(self.root)},
                    self.glob_neighbor: {"id": "$9", "cwd": str(self.root)}}
        if live:
            sessions[name] = {"id": "$7", "cwd": str(self.root)}
        self.set_sessions(sessions)

    def remove(self, discard=True, expected=0):
        return self.run_ftm("remove", "--session", self.name, "--format", "json",
                            *(["--discard-snapshot"] if discard else []), expected=expected)

    def assert_unrelated_untouched(self):
        self.assertEqual(self.other_snapshot.read_text(), "unrelated snapshot\n")
        self.assertEqual(self.glob_snapshot.read_text(), "glob neighbor snapshot\n")
        sessions = json.loads((self.root / "sessions.json").read_text())
        self.assertIn(self.name + "-other", sessions)
        self.assertIn(self.glob_neighbor, sessions)
        self.assertNotIn(self.name, sessions)

    def assert_trashed_snapshot(self):
        calls = self.calls("trash")
        self.assertEqual(calls[-1]["cwd"], str(self.state / "snapshots"))
        self.assertEqual(calls[-1]["args"][0], "--")
        self.assertRegex(calls[-1]["args"][1], r"^\./\.forget\.[A-Za-z0-9]+$")
        self.assertEqual([path.read_text() for path in (self.root / "trashed").iterdir()],
                         ["old snapshot\n"] * len(calls))
        self.assertEqual(list((self.state / "snapshots").glob(".forget.*")), [])

    def use_special_state_parent(self):
        self.state = self.root / r"state[one]{two}\three"
        (self.state / "snapshots").mkdir(parents=True, exist_ok=True)
        self.env["FTM_STATE_DIR"] = str(self.state)

    def assert_no_snapshot_capture(self):
        commands = [call["args"][0] for call in self.calls("tmux")]
        self.assertNotIn("list-windows", commands)
        self.assertNotIn("list-panes", commands)

    def test_discard_live_session_forgets_only_exact_name_without_snapshotting(self):
        self.seed_removal()
        self.remove()
        self.assertEqual([call["args"] for call in self.calls("tmux")
                          if call["args"][0] == "kill-session"], [["kill-session", "-t", "$7"]])
        self.assert_no_snapshot_capture()
        self.assertFalse(self.snapshot.exists())
        self.assert_trashed_snapshot()
        self.assertEqual(self.recent.read_text(), self.kept_recent)
        self.assert_unrelated_untouched()

    def test_discard_glob_name_does_not_trash_matching_neighbor(self):
        for live in (True, False):
            with self.subTest(live=live):
                self.seed_removal(live=live, name="alpha*")
                self.remove()
                self.assertFalse(self.snapshot.exists())
                self.assert_trashed_snapshot()
                self.assertEqual(self.recent.read_text(), self.kept_recent)
                self.assert_unrelated_untouched()

    def test_discard_special_names_under_special_parent(self):
        self.use_special_state_parent()
        for name in ("[brackets]", "{alpha,beta}", r"back\slash"):
            for live in (True, False):
                with self.subTest(name=name, live=live):
                    self.seed_removal(live=live, name=name)
                    self.remove()
                    self.assertFalse(self.snapshot.exists())
                    self.assert_trashed_snapshot()
                    self.assertEqual(self.recent.read_text(), self.kept_recent)
                    self.assert_unrelated_untouched()

    def test_failed_discard_restores_special_names_under_special_parent(self):
        self.use_special_state_parent()
        for name in ("[brackets]", "{alpha,beta}", r"back\slash"):
            for failure in ("TRASH_FAIL", "TRASH_NOOP"):
                for live in (True, False):
                    with self.subTest(name=name, failure=failure, live=live):
                        self.seed_removal(live=live, name=name)
                        before = self.recent.read_bytes()
                        self.env.pop("TRASH_FAIL", None)
                        self.env.pop("TRASH_NOOP", None)
                        self.env[failure] = "1"
                        result = self.remove(expected=7)
                        self.assertEqual(json.loads(result.stdout)["status"], "error")
                        self.assertEqual(self.snapshot.read_text(), "old snapshot\n")
                        self.assertEqual(self.recent.read_bytes(), before)
                        self.assertEqual(list((self.state / "snapshots").glob(".forget.*")), [])
                        self.assertEqual(list((self.root / "trashed").iterdir()), [])
                        self.assert_unrelated_untouched()

    def test_discard_absent_session_still_forgets_saved_state(self):
        self.seed_removal(live=False)
        self.remove()
        self.assert_no_snapshot_capture()
        self.assertFalse(self.snapshot.exists())
        self.assertEqual(self.recent.read_text(), self.kept_recent)
        self.assert_unrelated_untouched()
        self.assertFalse(any(c["args"][0] == "kill-session" for c in self.calls("tmux")))

    def test_discard_without_snapshot_still_removes_recent_entries(self):
        self.seed_removal(live=False)
        self.snapshot.rename(self.root / "unused-snapshot")
        self.remove()
        self.assertEqual(self.recent.read_text(), self.kept_recent)
        self.assertEqual(self.calls("trash"), [])

    def test_discard_absent_session_without_saved_state_is_idempotent(self):
        self.name = "never-created"
        self.remove()
        self.remove()
        self.assertEqual(self.calls("trash"), [])
        self.assertEqual(json.loads((self.root / "sessions.json").read_text()), {})

    def test_normal_remove_snapshots_and_preserves_recent(self):
        self.seed_removal()
        before = self.recent.read_bytes()
        self.remove(discard=False)
        self.assertTrue(self.snapshot.read_text().startswith("version\t1\n"))
        self.assertEqual(self.recent.read_bytes(), before)
        self.assertEqual(self.calls("trash"), [])
        self.assert_unrelated_untouched()

    def test_normal_remove_absent_session_preserves_saved_state(self):
        self.seed_removal(live=False)
        before = self.recent.read_bytes()
        self.remove(discard=False)
        self.assertEqual(self.snapshot.read_text(), "old snapshot\n")
        self.assertEqual(self.recent.read_bytes(), before)
        self.assertEqual(self.calls("trash"), [])

    def test_trash_failure_reports_error_and_never_unlinks_snapshot(self):
        for live in (True, False):
            with self.subTest(live=live):
                self.seed_removal(live=live)
                before = self.recent.read_bytes()
                self.env["TRASH_FAIL"] = "1"
                result = subprocess.run(
                    [BASH, str(self.ftm), "remove", "--session", self.name,
                     "--discard-snapshot", "--format", "json"],
                    env=self.env, cwd=self.root, text=True, capture_output=True, timeout=15)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(self.snapshot.read_text(), "old snapshot\n")
                self.assertEqual(self.recent.read_bytes(), before)
                self.assertEqual(list((self.state / "snapshots").glob(".forget.*")), [])
                self.assertEqual(json.loads(result.stdout)["status"], "error")

    def test_trash_success_without_removal_reports_error_and_keeps_recent(self):
        for live in (True, False):
            with self.subTest(live=live):
                self.seed_removal(live=live)
                before = self.recent.read_bytes()
                self.env["TRASH_NOOP"] = "1"
                result = subprocess.run(
                    [BASH, str(self.ftm), "remove", "--session", self.name,
                     "--discard-snapshot", "--format", "json"],
                    env=self.env, cwd=self.root, text=True, capture_output=True, timeout=15)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(json.loads(result.stdout)["status"], "error")
                self.assertEqual(self.snapshot.read_text(), "old snapshot\n")
                self.assertEqual(self.recent.read_bytes(), before)

    def test_invalid_names_do_not_mutate_state(self):
        self.seed_removal()
        before = self.recent.read_bytes()
        for name in ("", ".", "..", "../outside", "a/b", "a\nb", "a\tb"):
            with self.subTest(name=name):
                self.run_ftm("remove", "--session", name, "--discard-snapshot", expected=2)
        self.assertEqual(self.calls("trash"), [])
        self.assertEqual(self.calls("tmux"), [])
        self.assertEqual(self.snapshot.read_text(), "old snapshot\n")
        self.assertEqual(self.recent.read_bytes(), before)

    def git(self, *args):
        subprocess.run(["/usr/bin/git", *args], env=self.env, cwd=self.root,
                       text=True, capture_output=True, check=True, timeout=15)

    def git_cwd(self, linked=False):
        repo = self.root / "primary repo"
        self.git("init", "-q", str(repo))
        if linked:
            self.git("-C", str(repo), "-c", "user.name=Fixture", "-c",
                     "user.email=fixture@example.invalid", "commit", "-qm", "initial", "--allow-empty")
            worktree = self.root / "linked checkout"
            self.git("-C", str(repo), "worktree", "add", "-qb", "topic", str(worktree))
            cwd = worktree / "nested dir"
        else:
            cwd = repo / "nested dir"
        cwd.mkdir()
        self.env["ZOXIDE_PATH"] = str(cwd)
        return cwd

    def assert_wt_open(self, cwd):
        self.assertEqual(self.calls("wt"), [{"command": "wt", "args": ["open", "."],
                                           "cwd": str(cwd), "git_worktree": None}])
        self.assertFalse(any(c["args"][0] == "new-session" for c in self.calls("tmux")))
        self.assertEqual(self.calls("mise"), [])

    def test_primary_git_directory_routes_through_wt_with_clean_environment(self):
        cwd = self.git_cwd()
        self.run_ftm("project")
        self.assert_wt_open(cwd)

    def test_linked_git_directory_routes_through_wt_with_clean_environment(self):
        cwd = self.git_cwd(linked=True)
        self.run_ftm("project")
        self.assert_wt_open(cwd)

    def test_wt_failure_is_propagated_without_generic_fallback(self):
        cwd = self.git_cwd()
        self.env["WT_EXIT"] = "42"
        self.run_ftm("project", expected=42)
        self.assert_wt_open(cwd)

    def test_linked_wt_failure_is_propagated_without_generic_fallback(self):
        cwd = self.git_cwd(linked=True)
        self.env["WT_EXIT"] = "42"
        self.run_ftm("project", expected=42)
        self.assert_wt_open(cwd)

    def add_layout(self):
        (self.layouts / "project.sh").write_text(
            'printf layout > "$FIXTURE/layout-ran"\n'
            'tmux new-session -d -s project -c "$ZOXIDE_PATH"\n')

    def test_primary_git_directory_keeps_named_layout(self):
        self.git_cwd()
        self.add_layout()
        self.run_ftm("project")
        self.assertEqual((self.root / "layout-ran").read_text(), "layout")
        self.assertEqual(self.calls("wt"), [])

    def test_linked_git_directory_routes_through_wt_even_with_named_layout(self):
        cwd = self.git_cwd(linked=True)
        self.add_layout()
        self.run_ftm("project")
        self.assert_wt_open(cwd)
        self.assertFalse((self.root / "layout-ran").exists())

    def test_fresh_bypasses_wt_snapshot_and_named_layout(self):
        cwd = self.git_cwd(linked=True)
        self.add_layout()
        encode = lambda value: base64.b64encode(value.encode()).decode()
        snapshot = self.state / "snapshots" / "project"
        snapshot.write_text("version\t1\npath\t" + encode(str(cwd)) +
                            "\nactive\t0\nwindow\t0\t" + encode("saved-window") +
                            "\t" + encode("layout") + "\t1\t0\npane\t0\t0\t" +
                            encode(str(cwd)) + "\t" + encode("bash") + "\t-\t1\n")
        before = snapshot.read_bytes()
        self.env["FZF_OUTPUT"] = "project\n__FTM_FRESH__\n"
        self.run_ftm()
        self.assertEqual(self.calls("wt"), [])
        self.assertFalse((self.root / "layout-ran").exists())
        self.assertEqual(snapshot.read_bytes(), before)
        creates = [c["args"] for c in self.calls("tmux") if c["args"][0] == "new-session"]
        self.assertEqual(len(creates), 1)
        self.assertIn("code", creates[0])
        self.assertNotIn("saved-window", creates[0])
        self.assertFalse(any(c["args"][0] == "respawn-pane" for c in self.calls("tmux")))

    def test_agent_launch_uses_managed_wrapper(self):
        self.env["MISSING_AGENT"] = "1"
        session_id = "01a069c5-9dbc-76ed-a951-1b70905357d5"
        for pi_args in (["-c"], ["--session", session_id]):
            with self.subTest(pi_args=pi_args):
                self.run_ftm("ensure", "--kind", "generic", "--cwd", str(self.root),
                             "--session", "project", "--attach", "never",
                             *([] if pi_args == ["-c"] else ["--pi-session", session_id]))
                sends = [call["args"] for call in self.calls("tmux")
                         if call["args"][0] == "send-keys"]
                command = sends[-1][3]
                self.assertEqual(command, '"$HOME/.local/bin/pi" ' + " ".join(pi_args))
                # Exercise shell quoting with a spaced HOME and a shadowing PATH pi.
                home = self.root / "home with spaces"
                wrapper = home / ".local" / "bin" / "pi"
                wrapper.parent.mkdir(parents=True, exist_ok=True)
                wrapper.write_text('#!/bin/sh\nprintf "managed\\n"\nprintf "%s\\n" "$@"\n')
                wrapper.chmod(0o755)
                shadow = self.bin / "pi"
                shadow.write_text("#!/bin/sh\nexit 99\n")
                shadow.chmod(0o755)
                result = subprocess.run([BASH, "-c", command],
                                        env={**self.env, "HOME": str(home)},
                                        text=True, capture_output=True, timeout=5)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.splitlines(), ["managed", *pi_args])

    def native_picker(self, rows, query, key):
        self.run_ftm()
        args = self.calls("fzf")[-1]["args"]
        binding = next(arg for arg in args if arg.startswith(f"--bind={key}:"))
        action = binding.split(":", 1)[1]
        master, slave = os.openpty()
        with os.fdopen(master, "rb", buffering=0) as terminal:
            def drain():
                try:
                    while terminal.read(4096):
                        pass
                except OSError:
                    pass
            process = subprocess.Popen(
                [FZF, "--no-height", "--no-tmux", "--ansi", "--delimiter=\t",
                 "--with-nth=3..", "--print-query", "--query=" + query,
                 "--with-shell=" + BASH + " -c", "--bind=load:" + action],
                stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=slave,
                start_new_session=True, preexec_fn=lambda: fcntl.ioctl(2, termios.TIOCSCTTY, 0),
                env={**self.env, "TERM": "xterm-256color"})
            os.close(slave)
            reader = threading.Thread(target=drain, daemon=True)
            reader.start()
            try:
                output, _ = process.communicate(rows.encode(), timeout=8)
                self.assertIn(process.returncode, (0, 1))
                return output.decode()
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait()
                reader.join(timeout=2)

    @unittest.skipUnless(FZF, "native fzf is not installed")
    def test_native_picker_accepts_identity_rows_and_no_match_queries(self):
        row = " project ●  \t\tDisplay ICON\n"
        for key in ("enter", "alt-enter"):
            for query, selected in (("Display", True), ("missing", False)):
                with self.subTest(key=key, query=query):
                    output = self.native_picker(row, query, key)
                    lines = output.splitlines()
                    self.assertEqual(lines[0], query)
                    self.assertEqual("__FTM_FRESH__" in lines, key == "alt-enter")
                    self.assertEqual(row.rstrip("\n") in lines, selected)

    def test_picker_identity_is_independent_of_status_icons(self):
        name = " project ●  "
        self.set_sessions({name: {"id": "$7", "cwd": str(self.root)}})
        self.run_ftm()
        rows = (self.root / "picker-rows").read_text().splitlines()
        row = next(row for row in rows if row.startswith(name + "\t"))
        self.assertEqual(row.split("\t", 2)[:2], [name, ""])
        # A selected empty-path row must reset path/source from the query.
        self.env["FZF_OUTPUT"] = "wrong\t/wrong/path\n" + row + "\n"
        self.run_ftm()
        switches = [c["args"] for c in self.calls("tmux") if c["args"][0] == "switch-client"]
        self.assertEqual(switches[-1][1:3], ["-t", "$7"])
        result = self.run_ftm("--preview=" + name + "\t\t")
        self.assertEqual(result.stdout, "grid-preview\n")
        self.assertEqual(self.calls("ftm-grid-preview")[-1]["args"], [name, "%1"])
        self.assertFalse(any(c["args"][0] == "new-session" for c in self.calls("tmux")))

    def test_status_glyphs_only_appear_in_display_fields(self):
        self.set_sessions({"project": {"id": "$7", "cwd": str(self.root)}})
        status = self.root / "pi" / "status" / "pi-project-agent.status"
        status.parent.mkdir(parents=True)
        self.ftm.write_text(self.ftm.read_text().replace("", "BUSY!").replace("", "IDLE!"))
        for state, icon in (("working", "BUSY!"), ("asking", "BUSY!"), ("idle", "IDLE!")):
            with self.subTest(state=state):
                status.write_text(f"{state} {os.getpid()} project\n")
                self.run_ftm()
                row = (self.root / "picker-rows").read_text().splitlines()[0]
                self.assertEqual(row.split("\t", 2)[:2], ["project", ""])
                self.assertIn(icon, row.split("\t", 2)[2])

    def test_directory_and_layout_rows_keep_data_out_of_display(self):
        cwd = self.home / "dir with spaces"
        cwd.mkdir()
        (self.state / "recent").write_text(f"project\t{cwd}\n")
        (self.layouts / "layout.sh").write_text("# layout preview\n")
        self.run_ftm()
        rows = (self.root / "picker-rows").read_text().splitlines()
        directory = next(row for row in rows if row.startswith("project\t"))
        layout = next(row for row in rows if row.startswith("layout\t"))
        self.assertEqual(directory.split("\t")[:2], ["project", str(cwd)])
        self.assertIn("~/dir with spaces", directory.split("\t", 2)[2])
        self.assertEqual(layout.split("\t")[:2], ["layout", ""])
        self.assertEqual(self.run_ftm("--preview=layout\t\t").stdout, "# layout preview\n")
        preview = self.run_ftm("--preview=project\t" + str(cwd) + "\t")
        self.assertIn("~/dir with spaces", preview.stdout)
        self.env["FZF_OUTPUT"] = "query\n" + directory + "\n"
        self.run_ftm()
        create = next(c["args"] for c in self.calls("tmux") if c["args"][0] == "new-session")
        self.assertEqual(create[create.index("-c") + 1], str(cwd))

    def test_picker_omits_paths_with_row_delimiters(self):
        cwd = self.home / "parent\tdir" / "project"
        cwd.mkdir(parents=True)
        (self.state / "recent").write_text(f"project\t{cwd}\n")
        self.run_ftm()
        self.assertNotIn("project", (self.root / "picker-rows").read_text())

    def test_picker_kill_and_rename_use_exact_name_field(self):
        self.name = " project ●  "
        self.set_sessions({self.name: {"id": "$7", "cwd": str(self.root)}})
        self.run_ftm()
        args = self.calls("fzf")[-1]["args"]
        self.assertIn("--with-nth=3..", args)
        self.assertIn("--delimiter=\t", args)
        for key, verb in (("ctrl-r", "rename-session"), ("ctrl-k", "kill-session")):
            with self.subTest(key=key):
                binding = next(arg for arg in args if arg.startswith(f"--bind={key}:"))
                action = binding.split("(", 1)[1].rsplit(")+reload(", 1)[0]
                result = subprocess.run([BASH, "-c", action.replace("{s1}", shlex.quote(self.name))],
                                        input="renamed\n", env=self.env, cwd=self.root,
                                        text=True, capture_output=True, timeout=15)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                call = next(c["args"] for c in self.calls("tmux") if c["args"][0] == verb)
                self.assertEqual(call[call.index("-t") + 1], "$7")

    def test_picker_ctrl_x_confirms_forget_while_ctrl_k_preserves_snapshot(self):
        self.run_ftm()
        args = self.calls("fzf")[0]["args"]
        kill = next(arg for arg in args if arg.startswith("--bind=ctrl-k:"))
        forget = next(arg for arg in args if arg.startswith("--bind=ctrl-x:"))
        self.assertIn("remove --session", kill)
        self.assertNotIn("--discard-snapshot", kill)
        self.assertIn("--discard-snapshot", forget)
        self.assertIn("read ", forget)
        self.assertNotIn("execute-silent(", forget)

    def run_forget_binding(self, answer):
        self.run_ftm()
        args = self.calls("fzf")[-1]["args"]
        binding = next(arg for arg in args if arg.startswith("--bind=ctrl-x:"))
        action = binding.split("execute(", 1)[1].rsplit(")+reload(", 1)[0]
        return subprocess.run([BASH, "-c", action.replace("{s1}", shlex.quote(self.name))],
                              input=answer, env=self.env, cwd=self.root,
                              text=True, capture_output=True, timeout=15)

    def test_picker_forget_decline_or_eof_keeps_live_and_saved_state(self):
        self.seed_removal()
        before = self.recent.read_bytes()
        for answer in ("n\n", "\n", ""):
            with self.subTest(answer=answer):
                self.run_forget_binding(answer)
                self.assertEqual(self.snapshot.read_text(), "old snapshot\n")
                self.assertEqual(self.recent.read_bytes(), before)
                self.assertIn(self.name, json.loads((self.root / "sessions.json").read_text()))
        self.assertEqual(self.calls("trash"), [])

    def test_picker_confirmed_forget_removes_selected_exact_session(self):
        self.seed_removal()
        result = self.run_forget_binding("y\n")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(self.snapshot.exists())
        self.assertEqual(self.recent.read_text(), self.kept_recent)
        self.assert_unrelated_untouched()
        self.assert_no_snapshot_capture()


if __name__ == "__main__":
    unittest.main()
