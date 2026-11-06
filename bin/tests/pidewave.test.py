"""Offline checks for bin/pidewave: python3 -B bin/tests/pidewave.test.py."""

import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import threading
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "pidewave"


class Bridge:
    """A fake bridge socket that records control requests and answers ok."""

    def __init__(self, path):
        self.path = path
        self.requests = []
        self.server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.server.bind(path)
        self.server.listen(4)
        threading.Thread(target=self.serve, daemon=True).start()

    def serve(self):
        while True:
            try:
                conn, _ = self.server.accept()
            except OSError:
                return
            with conn:
                data = b""
                while b"\n" not in data:
                    data += conn.recv(4096)
                self.requests.append(json.loads(data.split(b"\n")[0]))
                conn.sendall(b'{"ok":true}\n')

    def close(self):
        self.server.close()


class PidewaveCli(unittest.TestCase):
    def setUp(self):
        # Short path: Unix socket paths are limited to 104 bytes on macOS.
        self.tmp = tempfile.mkdtemp(prefix="pw-", dir="/tmp")
        self.ports = Path(self.tmp, "state", "pidewave", "ports")
        self.ports.mkdir(parents=True)
        self.bin = Path(self.tmp, "bin")
        self.bin.mkdir()
        self.bridge = Bridge(os.path.join(self.tmp, "b.sock"))

    def tearDown(self):
        self.bridge.close()
        subprocess.run(["trash", self.tmp], check=False)

    def lease(self, port, **extra):
        lease = {
            "v": 1,
            "port": port,
            "origin": "http://localhost:%d" % port,
            "root": "/tmp/wt-%d" % port,
            "pid": os.getpid(),
            "socket": self.bridge.path,
            "terminal": {"kind": "plain"},
        }
        lease.update(extra)
        (self.ports / ("%d.json" % port)).write_text(json.dumps(lease))

    def run_cli(self, *args):
        env = dict(os.environ, PI_STATE_DIR=str(Path(self.tmp, "state")), PATH="%s:/usr/bin:/bin" % self.bin)
        return subprocess.run([sys.executable, str(SCRIPT), *args], env=env, capture_output=True, text=True)

    def test_inspect_by_rex_block(self):
        self.lease(4001, terminal={"kind": "rex", "rex": {"session": "s", "block": "block:a"}})
        result = self.run_cli("inspect", "--rex-block", "block:a")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.bridge.requests[0]["operation"], "pidewave.inspect")

    def test_inspect_through_a_tmux_client_in_the_block(self):
        self.lease(4002, terminal={"kind": "tmux", "tmux": {"pane": "%9"}})
        tmux = self.bin / "tmux"
        tmux.write_text("#!/bin/sh\nprintf '111\\t%%1\\n222\\t%%9\\n'\n")
        tmux.chmod(0o755)
        result = self.run_cli("inspect", "--rex-block", "block:other", "--pid", "222")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.bridge.requests), 1)

    def test_inspect_by_port_and_by_nested_cwd(self):
        self.lease(4003)
        self.assertEqual(self.run_cli("inspect", "--port", "4003").returncode, 0)
        self.assertEqual(self.run_cli("inspect", "--cwd", "/tmp/wt-4003/lib/app").returncode, 0)
        self.assertEqual(len(self.bridge.requests), 2)

    def test_dead_or_missing_holders_do_nothing(self):
        proc = subprocess.Popen(["true"])
        proc.wait()
        self.lease(4004, pid=proc.pid)
        result = self.run_cli("inspect", "--port", "4004")
        self.assertEqual(result.returncode, 3)
        self.assertEqual(self.run_cli("inspect", "--rex-block", "block:none").returncode, 3)
        self.assertEqual(self.bridge.requests, [])

    def test_list_marks_liveness(self):
        self.lease(4005)
        listed = json.loads(self.run_cli("list").stdout)
        self.assertEqual([(lease["port"], lease["alive"]) for lease in listed], [(4005, True)])


if __name__ == "__main__":
    unittest.main()
