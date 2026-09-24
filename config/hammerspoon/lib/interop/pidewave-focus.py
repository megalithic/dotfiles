#!/usr/bin/env python3
"""Resolve a focused tmux Pi; caller must bound this process with gtimeout."""

import datetime as dt
import json
import os
import re
import stat
import subprocess
import sys
from urllib.parse import urlsplit

PANE_FORMAT = "|".join("#{" + key + "}" for key in (
    "session_name", "window_index", "pane_index", "pane_pid", "pane_id",
    "pane_tty", "pane_in_mode", "pane_active", "window_active", "pane_current_path",
))
CLIENT_FORMAT = "|".join("#{" + key + "}" for key in (
    "client_pid", "client_tty", "client_session", "pane_id", "client_flags",
    "client_control_mode", "client_prefix", "client_key_table",
))
IDENTITY_FIELDS = (
    "pane", "pid", "owner", "cwd", "socket", "session", "window",
    "tidewaveEndpoint", "tidewaveConnected", "ephemeral",
)


def run(argv):
    # Do not detach: the caller's timeout must kill this entire process group.
    return subprocess.run(argv, check=True, stdout=subprocess.PIPE,
                          stderr=subprocess.DEVNULL, text=True).stdout.rstrip("\n")


def pane_for_title(title):
    match = re.match(r"^([^:|\r\n]+):([0-9]+):([0-9]+):([0-9]+)\s", title)
    if not match:
        return None
    session, window, index, pid = match.groups()
    target = f"={session}:{window}.{index}"
    row = run(["tmux", "display-message", "-p", "-t", target, PANE_FORMAT])
    fields = row.split("|", 9)
    if len(fields) != 10 or fields[:4] != [session, window, index, pid]:
        return None
    _, _, _, _, pane, tty, mode, active, window_active, cwd = fields
    if (not re.fullmatch(r"%[0-9]+", pane) or not tty.startswith("/dev/")
            or (mode, active, window_active) != ("0", "1", "1") or not cwd):
        return None
    return {"pane": pane, "cwd": cwd, "pid": int(pid), "tty": tty}


def focused_client(title, pane):
    session = title.split(":", 1)[0]
    rows = run(["tmux", "list-clients", "-F", CLIENT_FORMAT])
    matches = []
    for row in rows.splitlines():
        fields = row.split("|")
        if len(fields) != 8:
            return None
        pid, tty, client_session, client_pane, flags, control, prefix, table = fields
        flags = set(flags.split(","))
        if (client_session != session or client_pane != pane["pane"]
                or "focused" not in flags):
            continue
        if (not pid.isdecimal() or not tty.startswith("/dev/")
                or "attached" not in flags or control != "0" or prefix != "0"
                or table != "root" or "active-pane" in flags):
            # list-clients pane_id is session-wide, not a private active-pane override.
            return None
        matches.append((pid, tty, client_session, client_pane))
    return matches[0] if len(matches) == 1 else None


def valid_endpoint(endpoint):
    if (not isinstance(endpoint, dict) or endpoint.get("pathname") != "/tidewave/mcp"
            or not isinstance(endpoint.get("origin"), str)):
        return False
    origin = endpoint["origin"]
    try:
        parsed = urlsplit(origin)
        if (parsed.scheme not in ("http", "https")
                or parsed.hostname not in ("localhost", "127.0.0.1")
                or parsed.username is not None or parsed.password is not None
                or parsed.path or parsed.query or parsed.fragment):
            return False
        default = 80 if parsed.scheme == "http" else 443
        port = parsed.port if parsed.port is not None else default
        if not 1 <= port <= 65535 or port == 9832:
            return False
        canonical = f"{parsed.scheme}://{parsed.hostname}"
        if port != default:
            canonical += f":{port}"
        return origin == canonical
    except ValueError:
        return False


def fresh_manifest(manifest, now=None):
    if (not isinstance(manifest, dict) or manifest.get("tidewaveConnected") is not True
            or ("ephemeral" in manifest and manifest["ephemeral"] is not False)
            or type(manifest.get("pid")) is not int or manifest["pid"] <= 0
            or not valid_endpoint(manifest.get("tidewaveEndpoint"))):
        return False
    if any(not isinstance(manifest.get(key), str) or not manifest[key]
           for key in ("owner", "cwd", "socket")):
        return False
    heartbeat = manifest.get("heartbeatAt")
    if not isinstance(heartbeat, str) or not re.fullmatch(
            r"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}Z", heartbeat):
        return False
    try:
        timestamp = dt.datetime.fromisoformat(heartbeat.replace("Z", "+00:00"))
        age = ((now or dt.datetime.now(dt.timezone.utc)) - timestamp).total_seconds()
        return 0 <= age < 45 and stat.S_ISSOCK(os.stat(manifest["socket"]).st_mode)
    except (ValueError, OSError):
        return False


def foreground_pi(manifest, pane):
    pid = manifest["pid"]
    row = run(["/bin/ps", "-p", str(pid), "-o", "pid=,pgid=,tpgid=,tty=,stat=,comm="])
    fields = row.split(None, 5)
    if len(fields) != 6:
        return False
    actual_pid, group, foreground, tty, state, command = fields
    if (actual_pid != str(pid) or not group.isdecimal() or int(group) <= 0
            or group != foreground or "/dev/" + tty != pane["tty"]
            or "T" in state or "Z" in state
            or (command != "pi" and not command.endswith("/pi"))):
        return False
    sockets = run(["/usr/sbin/lsof", "-a", "-p", str(pid), "-U", "-Fn"])
    owner = None
    for line in sockets.splitlines():
        if line.startswith("p"):
            owner = line[1:]
        if owner == str(pid) and line == "n" + manifest["socket"]:
            return True
    return False


def read_manifest(path):
    try:
        with open(path, encoding="utf-8") as stream:
            return json.load(stream)
    except (OSError, ValueError, UnicodeError):
        return None


def manifest_files(directory):
    return sorted(name for name in os.listdir(directory) if name.endswith(".info"))


def resolve(directory, title):
    pane = pane_for_title(title)
    if not pane:
        return None
    client = focused_client(title, pane)
    if not client:
        return None
    files = manifest_files(directory)
    found = None
    snapshots = {}
    for name in files:
        path = os.path.join(directory, name)
        manifest = read_manifest(path)
        fresh = (isinstance(manifest, dict) and manifest.get("pane") == pane["pane"]
                 and fresh_manifest(manifest))
        snapshots[name] = (manifest, fresh)
        if not fresh:
            continue
        try:
            eligible = foreground_pi(manifest, pane)
        except subprocess.CalledProcessError:
            eligible = False
        if eligible:
            if found:
                return None
            found = (path, manifest)
    if not found:
        return None
    path, manifest = found
    if pane_for_title(title) != pane or focused_client(title, pane) != client:
        return None
    for name in files:
        if os.path.join(directory, name) == path:
            continue
        before, was_fresh = snapshots[name]
        after = read_manifest(os.path.join(directory, name))
        if any(isinstance(value, dict) and value.get("pane") == pane["pane"]
               for value in (before, after)):
            if (not isinstance(before, dict) or not isinstance(after, dict)
                    or any(before.get(key) != after.get(key) for key in IDENTITY_FIELDS)
                    or was_fresh != fresh_manifest(after)):
                return None
    current = read_manifest(path)
    if (not fresh_manifest(current)
            or any(current.get(key) != manifest.get(key) for key in IDENTITY_FIELDS)
            or manifest_files(directory) != files):
        return None
    return {"pane": pane, "manifest": current}


def main(argv):
    if len(argv) != 2:
        return 1
    try:
        result = resolve(*argv)
        if result is None:
            return 1
        print(json.dumps(result, separators=(",", ":"), allow_nan=False))
        return 0
    except (OSError, ValueError, TypeError, subprocess.SubprocessError):
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
