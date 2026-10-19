"""Offline checks for wt prune's keep-artifacts prompt: python3 -B bin/tests/wt-keep-agent-artifacts.test.py."""

import os
from pathlib import Path
import pty
import subprocess
import tempfile
import unittest


LIB = Path(__file__).resolve().parents[1] / "wt-v2-lib"
CALL = 'source "$LIB"; V2_PATH="$WT_PATH"; V2_REPO_ROOT="$WT_ROOT"; v2_keep_agent_artifacts; echo "rc=$? ${V2_ERROR_CODE:-}"'


class KeepAgentArtifactsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        base = Path(self.tmp.name).resolve()
        self.home = base / "home"
        self.root = base / "myrepo"
        self.path = self.root / ".worktrees" / "feature"
        (self.path / ".config/pi/audits").mkdir(parents=True)
        (self.path / ".config/pi/plans").mkdir()
        (self.path / ".config/pi/audits/trail.tsv").write_text("row\n")
        (self.path / ".config/pi/plans/x_PLAN.md").write_text("plan\n")
        self.archive = self.home / ".local/share/pi"

    def tearDown(self):
        self.tmp.cleanup()

    def run_keep(self, answer=None):
        env = {**os.environ, "HOME": str(self.home), "LIB": str(LIB), "WT_PATH": str(self.path), "WT_ROOT": str(self.root)}

        if answer is None:
            return subprocess.run(["bash", "-c", CALL], stdin=subprocess.DEVNULL, env=env, capture_output=True, text=True)
        master, slave = pty.openpty()

        try:
            os.write(master, answer.encode())
            return subprocess.run(["bash", "-c", CALL], stdin=slave, env=env, capture_output=True, text=True)
        finally:
            os.close(master)
            os.close(slave)

    def test_yes_copies_each_kind_under_repo_and_worktree(self):
        result = self.run_keep("y\n")
        self.assertIn("rc=0", result.stdout)
        self.assertIn("[y/N]", result.stderr)
        self.assertEqual((self.archive / "audits/myrepo/feature/trail.tsv").read_text(), "row\n")
        self.assertEqual((self.archive / "plans/myrepo/feature/x_PLAN.md").read_text(), "plan\n")

    def test_enter_defaults_to_no(self):
        result = self.run_keep("\n")
        self.assertIn("rc=0", result.stdout)
        self.assertFalse(self.archive.exists())

    def test_no_terminal_never_prompts(self):
        result = self.run_keep()
        self.assertIn("rc=0", result.stdout)
        self.assertNotIn("[y/N]", result.stderr)
        self.assertFalse(self.archive.exists())

    def test_earlier_archive_is_never_overwritten(self):
        earlier = self.archive / "audits/myrepo/feature"
        earlier.mkdir(parents=True)
        (earlier / "trail.tsv").write_text("old\n")
        self.run_keep("yes\n")
        self.assertEqual((earlier / "trail.tsv").read_text(), "old\n")
        copies = sorted((self.archive / "audits/myrepo").glob("feature-*/trail.tsv"))
        self.assertEqual([c.read_text() for c in copies], ["row\n"])


if __name__ == "__main__":
    unittest.main()
