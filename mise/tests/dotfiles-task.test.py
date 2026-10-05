"""Check the dotfiles task's arguments and exit status without applying files."""

from pathlib import Path
import os
import subprocess
import tomllib


ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "config/mise/config.toml"


def task_run():
    with CONFIG.open("rb") as config_file:
        task = tomllib.load(config_file)["tasks"]["update:dotfiles"]
    assert task["description"] == "Apply declared dotfile targets without overwriting conflicts"
    return task["run"]


def execute(run, host, status=0):
    shell = f'''\
mise() {{
    printf 'MISE_ENV=%s\\n' "$MISE_ENV"
    printf 'HOME=%s\\n' "$HOME"
    printf 'MISE_CONFIG_DIR=%s\\n' "$MISE_CONFIG_DIR"
    printf 'ARGV='
    printf '%s ' "$@"
    printf '\\n'
    return "$STUB_STATUS"
}}
{run}
'''
    env = os.environ.copy()
    env.pop("DOTFILES_DIR", None)
    env.update(
        HOME=f"/fake/home/{host}",
        MISE_ENV=host,
        STUB_STATUS=str(status),
    )
    return subprocess.run(
        ["/bin/sh", "-c", shell],
        cwd=ROOT,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )


def main():
    run = task_run()
    expected = (
        "MISE_ENV={host}\n"
        "HOME=/fake/home/{host}\n"
        "MISE_CONFIG_DIR=/fake/home/{host}/.dotfiles/config/mise\n"
        "ARGV=--verbose bootstrap dotfiles apply --yes \n"
    )
    for host in ("megabookpro", "workbookpro"):
        result = execute(run, host)
        assert result.returncode == 0, result.stderr
        assert result.stdout == expected.format(host=host)
        assert "--force" not in result.stdout

    result = execute(run, "megabookpro", status=23)
    assert result.returncode == 23
    assert result.stdout == expected.format(host="megabookpro")


if __name__ == "__main__":
    main()
