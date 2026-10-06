"""Offline wrapper checks: python3 -B bin/tests/macos-vm.test.py."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "macos-vm"
TRASH = shutil.which("trash")
FAKE = r'''
import json
import os
from pathlib import Path
import sys

home = Path(os.environ["HOME"])
name = Path(sys.argv[0]).name
args = sys.argv[1:]
if name == "uname":
    print("Darwin" if args == ["-s"] else ("x86_64" if (home / "intel").exists() else "arm64"))
    sys.exit(0)
if name == "mise":
    with (home / "mise-calls").open("a") as stream:
        stream.write(json.dumps(args) + "\n")
    if (home / "missing").exists():
        sys.exit(1)
    print(home / "install with spaces")
    sys.exit(0)
entry = {"args": args, "env": dict(os.environ)}
if args[0] == "exec":
    entry["stdin"] = sys.stdin.read()
with (home / "tart-calls").open("a") as stream:
    stream.write(json.dumps(entry) + "\n")
if args[0] == "exec" and args[3] == "exit-23":
    sys.exit(23)
'''


@unittest.skipUnless(TRASH, "trash is required to clean up test fixtures")
class MacosVmTest(unittest.TestCase):
    def setUp(self):
        self.home = Path(tempfile.mkdtemp(prefix="macos-vm-test-"))
        self.addCleanup(lambda: subprocess.run(
            [TRASH, str(self.home)], check=True, timeout=30))
        self.bin = self.home / "bin"
        self.bin.mkdir()
        tart = self.home / "install with spaces/tart.app/Contents/MacOS/tart"
        tart.parent.mkdir(parents=True)
        for path in (self.bin / "mise", self.bin / "uname", tart):
            path.write_text("#!" + sys.executable + "\n" + FAKE)
            path.chmod(0o755)
        self.env = {
            "HOME": str(self.home), "USER": "tester",
            "PATH": str(self.bin) + ":/usr/bin:/bin",
            "GITHUB_TOKEN": "fake-do-not-forward",
            "SSH_AUTH_SOCK": "/fake/agent.sock",
            "TART_HOME": "/unrelated/user-vms",
            "TART_NO_AUTO_PRUNE": "0",
        }

    def run_vm(self, *args, code=0, stdin=""):
        result = subprocess.run(
            ["/bin/bash", str(SCRIPT), *args], env=self.env,
            input=stdin, text=True, capture_output=True, timeout=15)
        self.assertEqual(result.returncode, code, result.stderr)
        return result

    def calls(self, filename="tart-calls"):
        path = self.home / filename
        return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []

    def test_help_does_not_resolve_or_install_tools(self):
        self.assertIn("Usage:", self.run_vm("--help").stdout)
        self.assertEqual(self.calls("mise-calls"), [])

    def test_run_uses_isolation_flags_and_clean_environment(self):
        self.run_vm("run", "proof")
        call = self.calls()[-1]
        self.assertEqual(call["args"], ["run", "--no-graphics", "--no-audio",
                                      "--no-usb-accessories", "--no-clipboard", "proof"])
        env = call["env"]
        self.assertNotIn("GITHUB_TOKEN", env)
        self.assertNotIn("SSH_AUTH_SOCK", env)
        self.assertEqual(env["TART_NO_AUTO_PRUNE"], "1")
        self.assertEqual(env["TART_HOME"], str(self.home / ".local/share/pi/macos-vms"))
        self.assertEqual(self.calls("mise-calls"), [
            ["--no-config", "where", "aqua:openai/tart@2.40.1"]])

    def test_exec_preserves_stdin_arguments_and_exit_status(self):
        self.run_vm("exec", "proof", "exit-23", "a b", "$(not-host-code)",
                    code=23, stdin="guest script\n")
        call = self.calls()[-1]
        self.assertEqual(call["args"], ["exec", "-i", "proof", "exit-23",
                                      "a b", "$(not-host-code)"])
        self.assertEqual(call["stdin"], "guest script\n")

    def test_create_has_no_overwrite_or_automatic_install(self):
        self.run_vm("create", "proof", "ghcr.io/example/macos@sha256:abc")
        self.assertEqual(self.calls()[-1]["args"], [
            "clone", "ghcr.io/example/macos@sha256:abc", "proof"])
        self.run_vm("create", "proof", "--overwrite", code=1)
        self.assertEqual(len(self.calls()), 1)

    def test_invalid_names_and_extra_flags_are_rejected(self):
        for name in ("../personal", "--dir", "host/path", "", "a;id"):
            with self.subTest(name=name):
                self.run_vm("run", name, code=1)
        self.run_vm("run", "proof", "--dir=/Users", code=1)
        self.run_vm("delete", "proof", code=1)
        self.assertEqual(self.calls(), [])

    def test_missing_tart_never_installs_it(self):
        (self.home / "missing").touch()
        self.assertIn("after approval", self.run_vm("run", "proof", code=1).stderr)
        self.assertEqual(self.calls("mise-calls"), [
            ["--no-config", "where", "aqua:openai/tart@2.40.1"]])
        self.assertEqual(self.calls(), [])

    def test_intel_host_is_rejected(self):
        (self.home / "intel").touch()
        self.assertIn("macOS arm64", self.run_vm("run", "proof", code=1).stderr)
        self.assertEqual(self.calls("mise-calls"), [])

    def test_read_and_stop_commands_are_scoped_to_testing_home(self):
        for args, expected in ((["status", "proof"], ["get", "proof", "--format", "json"]),
                               (["stop", "proof"], ["stop", "proof"]),
                               (["list"], ["list"])):
            self.run_vm(*args)
            self.assertEqual(self.calls()[-1]["args"], expected)


if __name__ == "__main__":
    unittest.main()
