"""Offline checks: python3 -B bin/tests/pi-docs-dir.test.py."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "pi-docs-dir"


def git(*args, cwd):
    subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True)


class PiDocsDirTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name).resolve()
        self.home = self.root / "home"
        self.home.mkdir()
        self.repo = self.root / "myrepo"
        self.repo.mkdir()
        git("init", "-q", "-b", "main", cwd=self.repo)
        git("-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty", "-m", "init", cwd=self.repo)

    def tearDown(self):
        self.tmp.cleanup()

    def run_script(self, *args, cwd):
        env = {**os.environ, "HOME": str(self.home)}
        return subprocess.run([str(SCRIPT), *args], cwd=cwd, env=env, capture_output=True, text=True)

    def test_main_checkout_uses_share_dir_named_after_the_repo(self):
        sub = self.repo / "lib"
        sub.mkdir()
        result = self.run_script("plans", cwd=sub)
        expected = self.home / ".local/share/pi/plans/myrepo"
        self.assertEqual(result.stdout.strip(), str(expected))
        self.assertTrue(expected.is_dir())

    def test_linked_worktree_uses_its_own_config_dir(self):
        worktree = self.repo / ".worktrees" / "feature"
        git("worktree", "add", "-q", "-b", "feature", str(worktree), cwd=self.repo)
        result = self.run_script("audits", cwd=worktree)
        expected = worktree / ".config/pi/audits"
        self.assertEqual(result.stdout.strip(), str(expected))
        self.assertTrue(expected.is_dir())

    def test_path_argument_and_non_git_dir(self):
        plain = self.root / "notes"
        plain.mkdir()
        result = self.run_script("docs", str(plain), cwd=self.root)
        self.assertEqual(result.stdout.strip(), str(self.home / ".local/share/pi/docs/notes"))

    def test_unknown_kind_is_rejected_and_creates_nothing(self):
        result = self.run_script("../escape", cwd=self.repo)
        self.assertEqual(result.returncode, 2)
        self.assertFalse((self.home / ".local").exists())


if __name__ == "__main__":
    unittest.main()
