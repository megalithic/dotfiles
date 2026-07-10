#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: scripts/test-bootstrap-tart.sh [--mode local|remote] [--seed <vm>] [--vm <name>] [--host <hostname>] [--keep] [--interactive] [--allow-human-gate]

Runs bootstrap.sh inside a disposable Tart macOS VM. Defaults to noninteractive SSH so prompts fail fast instead of spinning.

Modes:
  local   Test the current committed checkout through a read-only Tart mount.
          This is for validating unpushed commits before origin/main moves.
  remote  Test the production curl one-liner against GitHub HEAD.

Defaults:
  --mode local
  --seed tahoe-bootstrap-seed
  --host workbookpro

Required guest credentials use Cirrus Tart defaults: admin / admin.
EOF
}

ORIGINAL_ARGS=("$@")

MODE=local
SEED=tahoe-bootstrap-seed
VM="dotfiles-bootstrap-$(date +%Y%m%d-%H%M%S)"
GUEST_HOST=workbookpro
KEEP=0
GUEST_USER="admin"
GUEST_PASS="admin"
INTERACTIVE=0
ALLOW_HUMAN_GATE=0
REMOTE_BOOTSTRAP_URL="https://raw.githubusercontent.com/megalithic/dotfiles/HEAD/bootstrap.sh"
REMOTE_REPO_URL="https://github.com/megalithic/dotfiles.git"

while [ $# -gt 0 ]; do
  case "$1" in
  --mode)
    shift
    MODE=${1:?--mode requires local or remote}
    ;;
  --seed)
    shift
    SEED=${1:?--seed requires a VM name}
    ;;
  --vm)
    shift
    VM=${1:?--vm requires a VM name}
    ;;
  --host)
    shift
    GUEST_HOST=${1:?--host requires a hostname}
    ;;
  --keep)
    KEEP=1
    ;;
  --interactive)
    INTERACTIVE=1
    ;;
  --allow-human-gate)
    ALLOW_HUMAN_GATE=1
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    echo "unknown argument: $1" >&2
    exit 2
    ;;
  esac
  shift
done

case "$MODE" in
local | remote) ;;
*)
  echo "--mode must be local or remote" >&2
  exit 2
  ;;
esac

if ! command -v tart >/dev/null 2>&1 || ! command -v sshpass >/dev/null 2>&1; then
  if command -v nix >/dev/null 2>&1; then
    export NIXPKGS_ALLOW_UNFREE=1
    exec nix shell --impure nixpkgs#tart nixpkgs#sshpass -c "$0" "${ORIGINAL_ARGS[@]}"
  fi
  echo "missing tart or sshpass, and nix is unavailable" >&2
  exit 127
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
LOG_DIR="$REPO_ROOT/.local_scripts/bootstrap-tart"
mkdir -p "$LOG_DIR"
RUN_LOG="$LOG_DIR/$VM.log"
BOOTSTRAP_LOG="$LOG_DIR/$VM.bootstrap.log"

cleanup() {
  if [ "$KEEP" -eq 1 ]; then
    echo "keeping VM: $VM"
    return 0
  fi
  tart stop "$VM" >/dev/null 2>&1 || true
  tart delete "$VM" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "== bootstrap Tart test =="
echo "mode: $MODE"
echo "seed: $SEED"
echo "vm:   $VM"
echo "logs: $LOG_DIR"
echo "interactive: $INTERACTIVE"
echo "allow_human_gate: $ALLOW_HUMAN_GATE"

if ! tart list | awk '{print $2}' | grep -qx "$SEED"; then
  echo "seed '$SEED' missing; pulling Tahoe vanilla image"
  tart clone ghcr.io/cirruslabs/macos-tahoe-vanilla:latest "$SEED"
fi

tart clone "$SEED" "$VM"
tart set "$VM" --cpu 4 --memory 8192

TART_RUN_ARGS=()
if [ "$MODE" = local ]; then
  # Tart exposes this inside macOS guests at /Volumes/My Shared Files/dotfiles.
  TART_RUN_ARGS+=(--dir="dotfiles:$REPO_ROOT:ro")
fi

(tart run "${TART_RUN_ARGS[@]}" "$VM" >"$RUN_LOG" 2>&1 &)

ssh_probe() {
  sshpass -p "$GUEST_PASS" ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o "PreferredAuthentications=keyboard-interactive,password" \
    -o PubkeyAuthentication=no \
    -o ConnectTimeout=5 \
    "$GUEST_USER@$1" 'true' >/dev/null 2>&1
}

# Right after boot, sshd accepts one auth and then flakes while login services
# settle. Require two consecutive successful auths a few seconds apart before
# treating the guest as ready.
IP=""
READY=0
for _ in $(seq 1 240); do
  IP=$(tart ip "$VM" 2>/dev/null || true)
  if [ -n "$IP" ] && ssh_probe "$IP"; then
    sleep 5
    if ssh_probe "$IP"; then
      READY=1
      break
    fi
  fi
  sleep 2
done

if [ "$READY" -ne 1 ]; then
  echo "VM never became reachable over SSH; Tart log: $RUN_LOG" >&2
  exit 1
fi

echo "ip: $IP"
SSH_TTY_FLAGS=()
if [ "$INTERACTIVE" -eq 1 ]; then
  SSH_TTY_FLAGS=(-tt)
fi
SSH_BASE=(sshpass -p "$GUEST_PASS" ssh "${SSH_TTY_FLAGS[@]}"
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o "PreferredAuthentications=keyboard-interactive,password"
  -o PubkeyAuthentication=no
  "$GUEST_USER@$IP")

# shellcheck disable=SC2016 # remote shell expands command substitutions
"${SSH_BASE[@]}" 'sw_vers; uname -m; echo "user=$(id -un) uid=$(id -u) groups=$(id -Gn)"; command -v brew || true; command -v mise || true; xcode-select -p 2>/dev/null || true'

if [ "$MODE" = local ]; then
  BOOTSTRAP_URL='file:///Volumes/My%20Shared%20Files/dotfiles/bootstrap.sh'
  DOTFILES_REPO_URL='file:///Volumes/My%20Shared%20Files/dotfiles'
else
  BOOTSTRAP_URL="$REMOTE_BOOTSTRAP_URL"
  DOTFILES_REPO_URL="$REMOTE_REPO_URL"
fi

REMOTE_CMD=$(
  cat <<EOF
set -euo pipefail
printf '%s\\n' '$GUEST_PASS' | sudo -S -v
export DOTFILES_REPO_URL='$DOTFILES_REPO_URL'
bash -c "\$(curl -fsSL '$BOOTSTRAP_URL')" -- --force --host '$GUEST_HOST'
EOF
)

echo "bootstrap_url: $BOOTSTRAP_URL"
echo "dotfiles_repo:  $DOTFILES_REPO_URL"
echo "running bootstrap; log: $BOOTSTRAP_LOG"

set +e
"${SSH_BASE[@]}" "$REMOTE_CMD" 2>&1 | tee "$BOOTSTRAP_LOG"
STATUS=${PIPESTATUS[0]}
set -e

if [ "$STATUS" -ne 0 ]; then
  if [ "$ALLOW_HUMAN_GATE" -eq 1 ] && grep -q "op-signin-gate: op not signed in and no tty" "$BOOTSTRAP_LOG"; then
    echo "bootstrap reached expected 1Password human gate after noninteractive phases"
    echo "bootstrap log: $BOOTSTRAP_LOG"
    exit 0
  fi
  echo "bootstrap failed with status $STATUS" >&2
  echo "bootstrap log: $BOOTSTRAP_LOG" >&2
  exit "$STATUS"
fi

echo "bootstrap succeeded"
