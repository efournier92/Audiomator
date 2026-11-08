# Shared helpers for rc_process tests.
# Only agents edit these files. Keep assertions explicit and isolated.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/rc_process"

load "$ROOT/tests/vendor/bats-support/load"
load "$ROOT/tests/vendor/bats-assert/load"

# Source the script without running main.
load_lib() {
  # shellcheck disable=SC1090
  source "$SCRIPT"
}

# Build PATH shims for external tools. Every writable path lives under
# BATS_TEST_TMPDIR so tests never share state.
setup_shims() {
  SHIM_DIR="$BATS_TEST_TMPDIR/shims"
  mkdir -p "$SHIM_DIR"
  export RC_SHIM_LOG="$BATS_TEST_TMPDIR/shim.log"
  : >"$RC_SHIM_LOG"

  cat >"$SHIM_DIR/ffprobe" <<'SHIM'
#!/usr/bin/env bash
target="${@: -1}"
base="${target##*/}"
if [[ -n "${RC_FAKE_DURATION_MAP:-}" && -f "$RC_FAKE_DURATION_MAP" ]]; then
  while IFS='=' read -r key value; do
    if [[ "$key" == "$base" ]]; then
      echo "$value"
      exit 0
    fi
  done <"$RC_FAKE_DURATION_MAP"
fi
echo "${RC_FAKE_DURATION:-7200}"
SHIM

  cat >"$SHIM_DIR/ffmpeg" <<'SHIM'
#!/usr/bin/env bash
printf 'ffmpeg %s\n' "$*" >>"${RC_SHIM_LOG:?}"
out="${@: -1}"
case "$out" in
  *.mp3) : >"$out" ;;
esac
exit 0
SHIM

  cat >"$SHIM_DIR/tmux" <<'SHIM'
#!/usr/bin/env bash
printf 'tmux %s\n' "$*" >>"${RC_SHIM_LOG:?}"
# new-window: run the requested command through the shim PATH so the ffmpeg
# shim is exercised too. RC_TMUX_FAIL_NEW_WINDOW simulates a launch failure.
# list-windows: normally report no ffmpeg windows so the wait loop ends after
# one tick. RC_TMUX_ALWAYS_FFMPEG=1 keeps reporting one window.
if [[ "$1" == "new-window" ]]; then
  [[ "${RC_TMUX_FAIL_NEW_WINDOW:-0}" == "1" ]] && exit 1
  eval "$2"
  exit 0
fi
if [[ "$1" == "list-windows" ]]; then
  [[ "${RC_TMUX_ALWAYS_FFMPEG:-0}" == "1" ]] && echo "0: ffmpeg*"
  exit 0
fi
exit 0
SHIM

  cat >"$SHIM_DIR/ffplay" <<'SHIM'
#!/usr/bin/env bash
exit 0
SHIM

  chmod +x "$SHIM_DIR/ffprobe" "$SHIM_DIR/ffmpeg" "$SHIM_DIR/tmux" "$SHIM_DIR/ffplay"
  export PATH="$SHIM_DIR:$PATH"
}

# Epoch seconds for a UTC wall-clock string, used to build expectations.
epoch_of() {
  date -u -j -f "%Y-%m-%d %H:%M:%S" "$1" "+%s" 2>/dev/null \
    || date -u -d "$1" "+%s"
}
