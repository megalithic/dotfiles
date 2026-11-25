#!/usr/bin/env bash
# Prepare this checkout's toolchain: mise tools, Pi config, Hex and rebar.
# Run by `mise run wt:init`. Hex and rebar are installed only when missing, so
# a checkout that already has them never touches the network (a flaky
# `mix local.rebar` download used to fail whole setups).
set -euo pipefail

mise trust --quiet
# A fresh worktree may not have its declared toolchain yet.
mise install
# Pi/MCP config is cheap, atomic, and safe to repair on every run.
mise run bootstrap

if mise exec -- elixir -e 'Mix.start(); Mix.Local.append_archives(); Code.ensure_loaded?(Hex) || System.halt(1)' 2>/dev/null; then
  echo 'hex already installed'
else
  mise exec -- mix archive.install github hexpm/hex branch main --force
fi
mise exec -- mix local.rebar --if-missing --force
