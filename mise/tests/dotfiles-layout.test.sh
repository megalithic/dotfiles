#!/usr/bin/env bash
# Deploy the [dotfiles] trees into a throwaway HOME from a throwaway copy of
# the repo and check the resulting layout. Nothing under the real HOME or the
# real repo is read by mise or written: the fixture repo is a copy (not a
# link) and every mise/XDG directory points into the fixture.
#
# The fixture index is built from the working tree (tracked + untracked, not
# ignored), so it shows what deploys once the current moves are staged.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
tmp=$(mktemp -d)
trap 'chmod -R u+w "$tmp" 2>/dev/null; /usr/bin/trash "$tmp"' EXIT
home="$tmp/home"
repo="$home/.dotfiles"
host=workbookpro

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# -- fixture repo -------------------------------------------------------------
mkdir -p "$repo"
(
  cd "$repo_root"
  git ls-files -c -o --exclude-standard -z -- config home bin tools mise .gitignore |
    while IFS= read -r -d '' path; do
      [ -e "$path" ] || [ -L "$path" ] || continue # deleted in the working tree
      printf '%s\0' "$path"
    done |
    rsync -a0 --files-from=- --links . "$repo"
)
# Files the ignore rules must keep out of the index (and so out of the deploy).
printf 'nope\n' >"$repo/home/.ssh/id_probe"
printf 'nope\n' >"$repo/home/.ssh/known_hosts"
printf '{}\n' >"$repo/home/.claude/history.jsonl"
git_fixture() { HK=0 git -C "$repo" -c commit.gpgsign=false -c user.name=fixture -c user.email=fixture@localhost "$@"; }
git_fixture init -q
git_fixture add -A
git_fixture commit -q -m fixture
git_fixture ls-files --error-unmatch home/.ssh/id_probe >/dev/null 2>&1 && fail "home/.ssh/id_probe entered the index"
git_fixture ls-files --error-unmatch home/.claude/history.jsonl >/dev/null 2>&1 && fail "home/.claude/history.jsonl entered the index"
"$repo/mise/scripts/check-ssh-allowlist" >/dev/null || fail "check-ssh-allowlist rejected the fixture index"
# Paths the exclude lists must hide have to be in the index for the checks to mean anything.
for tracked in home/.ssh/allowed_signers home/.zshenv home/.local/bin/pi home/.pi/agent/extensions/_sentinel.ts home/.pi/agent/skills/_handoff/SKILL.md config/git/disabled/gitmessage config/atuin/AGENTS.md bin/tests/ftm.test.py; do
  git_fixture ls-files --error-unmatch "$tracked" >/dev/null 2>&1 || fail "$tracked missing from the fixture index"
done

# -- fixture home -------------------------------------------------------------
mkdir -p "$home/.local/share/mise/shims" "$home/.local/share/fnox/generated" "$home/.local/bin" "$home/.config/mise"
: >"$home/.local/share/mise/shims/lat"
: >"$home/.local/share/fnox/generated/s3cfg"
mkdir -m 700 "$home/.ssh"
printf 'keep me\n' >"$home/.ssh/known_hosts"
printf '# keep me\n' >"$home/.config/mise/config.local.toml"

# Run from inside the fixture: mise also loads .config/mise/config.toml from
# the working directory's ancestors, which would pull in the real HOME config.
apply() {
  cd "$home" && HOME="$home" \
    XDG_CONFIG_HOME="$home/.config" \
    XDG_DATA_HOME="$home/.local/share" \
    XDG_STATE_HOME="$home/.local/state" \
    XDG_CACHE_HOME="$home/.cache" \
    MISE_DATA_DIR="$home/.local/share/mise" \
    MISE_STATE_DIR="$home/.local/state/mise" \
    MISE_CACHE_DIR="$home/.cache/mise" \
    MISE_CONFIG_DIR="$repo/config/mise" \
    MISE_ENV="$host" \
    MISE_AUTO_INSTALL=false \
    MISE_TRUSTED_CONFIG_PATHS="$repo" \
    DOTFILES_DIR="$repo" \
    mise bootstrap dotfiles apply --yes "$@"
}

apply >"$tmp/apply1.log" 2>&1 || {
  cat "$tmp/apply1.log" >&2
  fail "first apply failed"
}

# -- checks -------------------------------------------------------------------
link_to() { # target source-relative-to-repo
  [ -L "$home/$1" ] || fail "$1 is not a symlink"
  [ "$(readlink "$home/$1")" = "$repo/$2" ] || fail "$1 -> $(readlink "$home/$1"), want $repo/$2"
}
absent() {
  [ ! -e "$home/$1" ] && [ ! -L "$home/$1" ] || fail "$1 should not be deployed"
}
real_dir() {
  [ -d "$home/$1" ] && [ ! -L "$home/$1" ] || fail "$1 should be a real directory"
}

while IFS='|' read -r target source; do link_to "$target" "$source"; done <<'EOF'
.bashrc|home/.bashrc
.profile|home/.profile
.bash_profile|home/.bash_profile
.iex.exs|home/.iex.exs
.ignore|home/.ignore
.zshenv|home/.zshenv
.claude/settings.json|home/.claude/settings.json
.ssh/allowed_signers|home/.ssh/allowed_signers
.ssh/shared.config|home/.ssh/shared.config
.ssh/config|home/.ssh/config.workbookpro
.pi/agent/settings.json|home/.pi/agent/settings.json
.pi/agent/AGENTS.md|home/.pi/agent/AGENTS.md
.pi/agent/web-search.json|home/.pi/agent/web-search.json
.pi/agent/extensions/answer.ts|home/.pi/agent/extensions/answer.ts
.pi/agent/skills/bro/SKILL.md|home/.pi/agent/skills/bro/SKILL.md
.pi/agent/prompts/plan.md|home/.pi/agent/prompts/plan.md
.pi/agent/agents/scout.md|home/.pi/agent/agents/scout.md
Library/Application Support/espanso/match/base.yml|home/Library/Application Support/espanso/match/base.yml
Library/Application Support/MailMate/Resources/KeyBindings/megamate.plist|home/Library/Application Support/MailMate/Resources/KeyBindings/megamate.plist
.config/starship.toml|config/starship.toml
.config/1Password/ssh/agent.toml|config/1Password/ssh/agent.toml
.config/ripgrep/rc|config/ripgrep/rc
.config/ripgrep/ignore|config/ripgrep/ignore
.config/fd/ignore|config/fd/ignore
.config/btop/btop.conf|config/btop/btop.conf
.config/git/config|config/git/config
.config/git/ignore|config/git/ignore
.config/fish/config.fish|config/fish/config.fish
.config/mise/config.toml|config/mise/config.toml
.config/mise/config.workbookpro.toml|config/mise/config.workbookpro.toml
.config/mise/config.megabookpro.toml|config/mise/config.megabookpro.toml
.config/mise/mise.lock|config/mise/mise.lock
.config/nvim/init.lua|config/nvim/init.lua
.config/kanata/macbook.kbd|config/kanata/macbook.kbd
.config/kanata/icons/base.png|config/kanata/icons/base.png
.config/fnox/yubikey-identity.txt|config/fnox/yubikey-identity.txt
.config/aeroplayd/config.json|config/aeroplayd/config.json
.local/bin/pi|home/.local/bin/pi
.local/bin/work-tickets|home/.local/bin/work-tickets
bin|bin
EOF
[ "$(readlink "$home/.s3cfg")" = "$home/.local/share/fnox/generated/s3cfg" ] || fail ".s3cfg link"
[ "$(readlink "$home/.pi/agent/bin/lat")" = "$home/.local/share/mise/shims/lat" ] || fail ".pi/agent/bin/lat link"

while read -r path; do absent "$path"; done <<'EOF'
.ssh/config.workbookpro
.ssh/config.megabookpro
.ssh/id_probe
.claude/history.jsonl
.pi/AGENTS.md
.pi/scripts
.pi/tests
.pi/patches
.pi/disabled
.pi/agent/extensions/_sentinel.ts
.pi/agent/extensions/_lat.ts
.pi/agent/skills/_handoff
.pi/agent/SYSTEM.md
.config/AGENTS.md
.config/atuin/AGENTS.md
.config/git/AGENTS.md
.config/git/disabled
.config/fnox/shared.toml
.config/fnox/yubikey-identity-15759055.txt
.config/s3cmd
.config/llama-cpp
.config/fish/fish_variables
.config/mise/conf.d
.config/mise/locks
.local/bin/hs-reload
.local/bin/tests
EOF
# config/superfile and config/zsh/.zcompdump are untracked in the real repo;
# the fixture index may include them, so no assertion either way.

for dir in .config .config/fish .config/mise .config/nvim .config/git .config/1Password/ssh .ssh .pi/agent .pi/agent/extensions .pi/agent/extensions/observational-memory .pi/agent/skills/bro "Library/Application Support/espanso" "Library/Application Support/espanso/match" "Library/Application Support/MailMate/Resources/KeyBindings" .claude .local/bin; do
  real_dir "$dir"
done
[ "$(/usr/bin/stat -f %Lp "$home/.ssh")" = 700 ] || fail "~/.ssh mode changed to $(/usr/bin/stat -f %Lp "$home/.ssh")"
[ "$(cat "$home/.ssh/known_hosts")" = "keep me" ] || fail "unmanaged ~/.ssh/known_hosts was touched"
[ "$(cat "$home/.config/mise/config.local.toml")" = "# keep me" ] || fail "unmanaged ~/.config/mise/config.local.toml was touched"

# The repo copy is untouched: no source became a self-link, nothing was
# created or removed.
[ -z "$(git_fixture status --porcelain)" ] || {
  git_fixture status --porcelain >&2
  fail "apply modified the fixture repo"
}

# Second apply converges without changes.
apply >"$tmp/apply2.log" 2>&1 || {
  cat "$tmp/apply2.log" >&2
  fail "second apply failed"
}
[ -z "$(git_fixture status --porcelain)" ] || fail "second apply modified the fixture repo"
link_to .bashrc home/.bashrc
link_to .config/1Password/ssh/agent.toml config/1Password/ssh/agent.toml

echo "dotfiles-layout: ok"
