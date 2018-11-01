#!/usr/bin/env zsh

source "$DOTS/zsh/components/zshrc/async.zsh"

async_init

async_start_worker git_upstream_worker -n

git_upstream_completed_callback() {
  echo "completed a thing"
}

git_fetch_upstream() {
  echo "fetch a thing"
}

async_register_callback git_upstream_worker git_upstream_completed_callback

async_job git_upstream_worker git_fetch_upstream
