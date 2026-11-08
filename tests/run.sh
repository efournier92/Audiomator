#!/usr/bin/env bash
# Zero-setup entry point for the rc_process test suite.
# Usage: ./tests/run.sh [bats options] [test paths]
# With no arguments it runs tests/unit and tests/integration.

set -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BATS="$ROOT/tests/vendor/bats-core/bin/bats"

# Prefer a modern bash for bats and for every script under test.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export LC_ALL=C
export TZ=UTC
export BATS_TEST_TIMEOUT="${BATS_TEST_TIMEOUT:-30}"

# Never let caller environment changes silently alter the suite.
unset RC_CHUNK_MARGIN RC_MAX_GAP RC_WAIT_MAX RC_POLL_INTERVAL RC_CONVERT_MAX_JOBS
unset RC_FAKE_DURATION RC_FAKE_DURATION_MAP RC_SHIM_LOG
unset RC_TMUX_ALWAYS_FFMPEG RC_TMUX_FAIL_NEW_WINDOW

if ((BASH_VERSINFO[0] * 100 + BASH_VERSINFO[1] < 404)); then
  echo "rc_process tests require bash >= 4.4 (found $BASH_VERSION)" >&2
  exit 1
fi

if [[ ! -x "$BATS" ]]; then
  echo "Vendored bats-core missing at $BATS" >&2
  exit 1
fi

args=("$@")
if [[ ${#args[@]} -eq 0 ]]; then
  args=("$ROOT/tests/unit" "$ROOT/tests/integration")
fi

# Option-only invocations still need a test path for bats.
all_options=true
for arg in "${args[@]}"; do
  [[ "$arg" == -* ]] || all_options=false
done
if [[ "$all_options" == true ]]; then
  args+=("$ROOT/tests/unit" "$ROOT/tests/integration")
fi

exec "$BATS" --print-output-on-failure --timing "${args[@]}"
