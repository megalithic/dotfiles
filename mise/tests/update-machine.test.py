"""Check native mise orchestration with harmless replacement update tasks."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib


ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "config/mise/config.toml"
PHASES = [
    "update:tools", "update:packages", "update:dotfiles", "update:system",
    "update:nvim", "update:fnox", "update:pi", "reload:hammerspoon",
]


def main():
    config = CONFIG.read_text()
    up = tomllib.loads(config)["tasks"]["up"]
    assert up["run"][1:] == [{"task": task} for task in PHASES]
    up_config = "[tasks.up]" + config.split("[tasks.up]", 1)[1].split("\n[tasks.", 1)[0]
    mise = shutil.which("mise")
    assert mise, "mise is required"
    root = Path(tempfile.mkdtemp())
    try:
        repo = root / "repo"
        repo.mkdir()
        elsewhere = root / "elsewhere"
        elsewhere.mkdir()
        for directory in ("home", "config", "data", "cache", "state"):
            (root / directory).mkdir()
        env = {
            "PATH": os.environ["PATH"],
            "HOME": str(root / "home"),
            "DOTFILES_DIR": str(repo),
            "MISE_CONFIG_DIR": str(root / "config"),
            "MISE_GLOBAL_CONFIG_FILE": str(root / "config.toml"),
            "MISE_SYSTEM_CONFIG_FILE": str(root / "missing.toml"),
            "MISE_DATA_DIR": str(root / "data"),
            "MISE_CACHE_DIR": str(root / "cache"),
            "MISE_STATE_DIR": str(root / "state"),
            "MISE_AUTO_INSTALL": "false",
            "MISE_TRUSTED_CONFIG_PATHS": str(root),
            "MISE_COLOR": "0",
            "CALLS": str(root / "calls"),
        }
        stubs = ""
        for phase in PHASES:
            command = f'echo {phase} >> "$CALLS"; [ "${{FAIL_PHASE:-}}" != {phase} ]'
            stubs += f'\n[tasks."{phase}"]\nrun = {json.dumps(command)}\n'
        (root / "config.toml").write_text(up_config + stubs)
        subprocess.run(["git", "init", "-q", str(repo)], env=env, check=True)

        def run(*args):
            result = subprocess.run(
                [mise, "--no-hooks", "run", *args], cwd=elsewhere, env=env,
                text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            )
            return result.returncode, result.stdout

        calls = root / "calls"
        status, output = run("up")
        assert status == 0, output
        assert "WARNING:" not in output, output
        assert calls.read_text().splitlines() == PHASES
        calls.write_text("")

        (repo / "file").write_text("untracked\n")
        status, output = run("dot")
        assert status == 0, output
        assert "Untracked files or unstaged changes may not take effect" in output
        assert calls.read_text().splitlines() == PHASES
        calls.write_text("")

        subprocess.run(["git", "-C", str(repo), "add", "file"], env=env, check=True)
        (repo / "file").write_text("unstaged\n")
        env["FAIL_PHASE"] = "update:packages"
        status, output = run("up")
        assert status != 0, output
        assert "WARNING:" in output, output
        assert calls.read_text().splitlines() == PHASES[:2]
        calls.write_text("")

        status, output = run("--dry-run", "up")
        assert status == 0, output
        assert calls.read_text() == "", output
        status = subprocess.check_output(
            ["git", "-C", str(repo), "status", "--porcelain"], env=env, text=True,
        )
        assert status.strip() == "AM file", status
        print("update-machine tests passed")
    finally:
        subprocess.run(["trash", str(root)], check=True)


if __name__ == "__main__":
    main()
