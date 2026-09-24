"""Run with python3 -B config/hammerspoon/tests/pidewave-focus.test.py."""

import contextlib
import copy
import datetime as dt
import importlib.util
import io
import json
from pathlib import Path
import socket
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("pidewave_focus", Path(__file__).resolve().parents[1] / "lib/interop/pidewave-focus.py")
focus = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(focus)


class FocusTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.socket_path = str(self.directory / "pi-%42.sock")
        self.socket = socket.socket(socket.AF_UNIX)
        self.socket.bind(self.socket_path)
        self.addCleanup(self.socket.close)
        self.title = "project:2:1:100 pi"
        self.pane = "project|2|1|100|%42|/dev/ttys010|0|1|1|/work/project"
        self.client = "123|/dev/ttys000|project|%42|attached,focused,UTF-8|0|0|root"
        self.process = "200 200 200 ttys010 S+ pi"
        self.sockets = "p200\nf22\nn" + self.socket_path
        self.manifest = {
            "pane": "%42", "pid": 200, "owner": "owner-a", "cwd": "/work/project",
            "socket": self.socket_path, "session": "project", "window": "2",
            "tidewaveConnected": True,
            "tidewaveEndpoint": {"origin": "http://localhost:4123", "pathname": "/tidewave/mcp"},
            "heartbeatAt": self.heartbeat(),
        }
        self.save()
        self.calls = []
        self.on_command = None
        self.mock_run = patch.object(focus.subprocess, "run", side_effect=self.run_command).start()
        self.addCleanup(patch.stopall)

    def heartbeat(self, age=0):
        return (dt.datetime.now(dt.timezone.utc) - dt.timedelta(seconds=age)).isoformat(timespec="milliseconds").replace("+00:00", "Z")

    def save(self, name="1.info", manifest=None):
        (self.directory / name).write_text(json.dumps(self.manifest if manifest is None else manifest))

    def run_command(self, argv, **kwargs):
        self.assertNotIn("shell", kwargs)
        self.assertNotIn("start_new_session", kwargs)
        self.assertEqual(kwargs["stderr"], subprocess.DEVNULL)
        self.calls.append(argv)
        if self.on_command:
            self.on_command(argv)
        if argv[:2] == ["tmux", "display-message"]:
            session, window, index = self.title.split(":")[:3]
            self.assertEqual(argv[2:], ["-p", "-t", f"={session}:{window}.{index}", focus.PANE_FORMAT])
            output = self.pane
        elif argv[:2] == ["tmux", "list-clients"]:
            output = self.client
        elif argv[0] == "/bin/ps":
            self.assertEqual(argv, ["/bin/ps", "-p", "200", "-o", "pid=,pgid=,tpgid=,tty=,stat=,comm="])
            output = self.process
        elif argv[0] == "/usr/sbin/lsof":
            self.assertEqual(argv, ["/usr/sbin/lsof", "-a", "-p", "200", "-U", "-Fn"])
            output = self.sockets
        else:
            self.fail("unexpected command " + repr(argv))
        if output is None:
            raise subprocess.CalledProcessError(1, argv)
        return subprocess.CompletedProcess(argv, 0, output + "\n")

    def resolve(self):
        return focus.resolve(str(self.directory), self.title)

    def rejected_cli(self):
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            self.assertEqual(focus.main([str(self.directory), self.title]), 1)
        self.assertEqual(stdout.getvalue(), "")

    def test_success_and_cli_json(self):
        result = self.resolve()
        self.assertEqual(result["pane"], {"pane": "%42", "pid": 100, "tty": "/dev/ttys010", "cwd": "/work/project"})
        self.assertEqual(result["manifest"], self.manifest)
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            self.assertEqual(focus.main([str(self.directory), self.title]), 0)
        self.assertEqual(json.loads(stdout.getvalue()), result)

    def test_title_and_tmux_failures(self):
        original_title, original_pane = self.title, self.pane
        for title in ("shell", "project:2:1:999 pi", "project:2:1:100", "project|bad:2:1:100 pi", "project:2:1:-1 pi"):
            with self.subTest(title=title):
                self.title = title
                self.rejected_cli()
        self.title = original_title
        for pane in (None, "", "bad row", original_pane.replace("project|", "other|"),
                     original_pane.replace("|2|", "|3|", 1), original_pane.replace("|100|", "|999|"),
                     original_pane.replace("|0|1|1|", "|1|1|1|"),
                     original_pane.replace("|0|1|1|", "|0|0|1|"),
                     original_pane.replace("|0|1|1|", "|0|1|0|"),
                     original_pane.replace("%42", "42"), original_pane.replace("/dev/", "")):
            with self.subTest(pane=pane):
                self.pane = pane
                self.rejected_cli()

    def test_session_name_is_one_literal_argument(self):
        session = "project'$(touch injected)*"
        self.title = self.title.replace("project", session)
        self.pane = self.pane.replace("project|", session + "|")
        self.client = self.client.replace("project|", session + "|")
        self.assertIsNotNone(self.resolve())
        self.assertEqual(self.calls[0][4], "=" + session + ":2.1")

    def test_cwd_may_contain_pipe(self):
        self.pane += "|suffix"
        self.assertEqual(self.resolve()["pane"]["cwd"], "/work/project|suffix")

    def test_client_gate(self):
        original = self.client
        for client in (None, "", "malformed", original + "\n" + original,
                       original.replace("project|", "other|"), original.replace("%42", "%43"),
                       original.replace("attached,", ""), original.replace("focused,", ""),
                       original.replace("|0|0|root", "|1|0|root"),
                       original.replace("|0|0|root", "|0|1|root"),
                       original.replace("|root", "|prefix"),
                       original.replace("UTF-8", "active-pane")):
            with self.subTest(client=client):
                self.client = client
                self.rejected_cli()

    def test_manifest_fields(self):
        original = copy.deepcopy(self.manifest)
        invalid = {
            "tidewaveConnected": [None, False, "true", 1], "ephemeral": [True, None, 1, "true", [], {}],
            "pid": [None, True, "200", 0, -1, 200.5], "owner": [None, "", 12],
            "cwd": [None, "", 12], "socket": [None, "", 12, "/absent/socket"],
            "pane": [None, "%43"], "tidewaveEndpoint": [None, {}, "http://localhost:4123"],
            "heartbeatAt": [None, "", "2026-02-30T10:00:00.000Z", "not a timestamp", self.heartbeat(46), self.heartbeat(-2)],
        }
        for key, values in invalid.items():
            for value in values:
                with self.subTest(key=key, value=value):
                    self.manifest = copy.deepcopy(original)
                    self.manifest[key] = value
                    self.save()
                    self.rejected_cli()

    def test_heartbeat_exact_boundaries(self):
        now = dt.datetime(2026, 9, 22, 12, 0, 0, 500000, tzinfo=dt.timezone.utc)
        for age, expected in ((0, True), (44.999, True), (45, False), (-0.001, False)):
            with self.subTest(age=age):
                self.manifest["heartbeatAt"] = (now - dt.timedelta(seconds=age)).isoformat(timespec="milliseconds").replace("+00:00", "Z")
                self.assertEqual(focus.fresh_manifest(self.manifest, now), expected)

    def test_endpoint_validation(self):
        for origin in ("http://localhost", "https://localhost", "http://localhost:4123", "https://127.0.0.1:4123"):
            with self.subTest(origin=origin):
                self.assertTrue(focus.valid_endpoint({"origin": origin, "pathname": "/tidewave/mcp"}))
        for origin in ("http://localhost:9832", "https://127.0.0.1:9832", "http://localhost:0", "http://localhost:65536",
                       "http://localhost:80", "https://localhost:443", "http://localhost:04123", "HTTP://localhost:4123",
                       "http://LOCALHOST:4123", "http://localhost:4123/", "http://localhost:4123?", "http://localhost:4123#",
                       "http://user@localhost:4123", "http://localhost:4123/?x=1", "http://localhost:4123/#x",
                       "http://localhost.evil:4123", "http://[::1]:4123", "file://localhost:4123", "\nhttp://localhost:4123"):
            with self.subTest(origin=origin):
                self.assertFalse(focus.valid_endpoint({"origin": origin, "pathname": "/tidewave/mcp"}))
        self.assertFalse(focus.valid_endpoint({"origin": "http://localhost:4123", "pathname": "/other"}))

    def test_malformed_manifest_and_missing_directory(self):
        for contents in ("{bad", "null", "[]", "true", '"value"'):
            with self.subTest(contents=contents):
                (self.directory / "1.info").write_text(contents)
                self.rejected_cli()
        (self.directory / "1.info").write_bytes(b"\xff")
        self.rejected_cli()
        self.directory = self.directory / "missing"
        self.rejected_cli()

    def test_duplicates_and_irrelevant_files(self):
        self.save("2.info")
        self.rejected_cli()
        other = copy.deepcopy(self.manifest)
        other["pane"] = "%43"
        self.save("2.info", other)
        (self.directory / "bad.info").write_text("invalid json")
        self.save("ignored.json")
        self.assertIsNotNone(self.resolve())

    def test_process_gate(self):
        for process in (None, "", "malformed", "201 200 200 ttys010 S+ pi", "200 200 300 ttys010 S pi",
                        "200 0 0 ttys010 S+ pi", "200 200 -1 ttys010 S pi", "200 200 200 ttys011 S+ pi",
                        "200 200 200 ttys010 T+ pi", "200 200 200 ttys010 Z+ pi",
                        "200 200 200 ttys010 S+ fish", "200 200 200 ttys010 S+ /bin/piano"):
            with self.subTest(process=process):
                self.process = process
                self.rejected_cli()
        self.process = "200 200 200 ttys010 S+ /path/to/pi"
        self.assertIsNotNone(self.resolve())

    def test_socket_gate(self):
        for sockets in (None, "", "p201\nn" + self.socket_path, "p200\nn" + self.socket_path + ".other",
                        "p200\nn/other\np201\nn" + self.socket_path):
            with self.subTest(sockets=sockets):
                self.sockets = sockets
                self.rejected_cli()
        self.manifest["socket"] = str(self.directory / "1.info")
        self.save()
        self.rejected_cli()

    def test_tmux_or_client_changes_during_check(self):
        for field, value in (("pane", self.pane.replace("/work/project", "/other")),
                             ("pane", self.pane.replace("|0|1|1|", "|1|1|1|")),
                             ("client", self.client.replace("|root", "|prefix")),
                             ("client", self.client.replace("123|", "124|"))):
            with self.subTest(field=field, value=value):
                original = getattr(self, field)
                self.on_command = lambda argv: setattr(self, field, value) if argv[0] == "/usr/sbin/lsof" else None
                self.rejected_cli()
                setattr(self, field, original)
        self.on_command = None

    def test_existing_stale_registration_becomes_current(self):
        duplicate = copy.deepcopy(self.manifest)
        duplicate["heartbeatAt"] = self.heartbeat(46)
        self.save("2.info", duplicate)
        count = 0
        def change(argv):
            nonlocal count
            if argv[:2] == ["tmux", "display-message"]:
                count += 1
                if count == 2:
                    self.save("2.info")
        self.on_command = change
        self.rejected_cli()

    def test_unrelated_heartbeat_refresh_is_allowed(self):
        other = copy.deepcopy(self.manifest)
        other["pane"] = "%43"
        other["heartbeatAt"] = self.heartbeat(10)
        self.save("2.info", other)
        def change(argv):
            if argv[0] == "/usr/sbin/lsof":
                other["heartbeatAt"] = self.heartbeat()
                self.save("2.info", other)
        self.on_command = change
        self.assertIsNotNone(self.resolve())

    def test_explicit_non_ephemeral_registration(self):
        self.manifest["ephemeral"] = False
        self.save()
        self.assertIsNotNone(self.resolve())

    def test_manifest_changes_during_check(self):
        original = copy.deepcopy(self.manifest)
        for field, value in (("owner", "owner-b"), ("pid", 201), ("cwd", "/other"), ("socket", "/other.sock"),
                             ("tidewaveEndpoint", {"origin": "http://localhost:4222", "pathname": "/tidewave/mcp"}),
                             ("tidewaveConnected", False), ("pane", "%43"), ("ephemeral", True),
                             ("heartbeatAt", self.heartbeat(46))):
            with self.subTest(field=field):
                self.manifest = copy.deepcopy(original)
                self.save()
                def change(argv):
                    if argv[0] == "/usr/sbin/lsof":
                        self.manifest[field] = value
                        self.save()
                self.on_command = change
                self.rejected_cli()

    def test_heartbeat_refresh_allowed(self):
        self.manifest["heartbeatAt"] = self.heartbeat(10)
        self.save()
        def refresh(argv):
            if argv[0] == "/usr/sbin/lsof":
                self.manifest["heartbeatAt"] = self.heartbeat()
                self.save()
        self.on_command = refresh
        self.assertEqual(self.resolve()["manifest"], self.manifest)

    def test_chosen_manifest_disappears_or_corrupts_during_check(self):
        original_reader = focus.read_manifest
        for value in (None, [], {"owner": "other"}):
            with self.subTest(value=value):
                reads = 0
                def read(path):
                    nonlocal reads
                    reads += 1
                    return original_reader(path) if reads == 1 else value
                with patch.object(focus, "read_manifest", side_effect=read):
                    self.rejected_cli()

    def test_new_registration_during_check(self):
        self.on_command = lambda argv: self.save("2.info") if argv[0] == "/usr/sbin/lsof" else None
        self.rejected_cli()

    def test_missing_executable_and_arguments(self):
        self.mock_run.side_effect = FileNotFoundError("tmux")
        self.rejected_cli()
        self.assertEqual(focus.main([]), 1)
        self.assertEqual(focus.main([str(self.directory)]), 1)


if __name__ == "__main__":
    unittest.main()
