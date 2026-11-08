# rc_process Test Suite

Run everything from the repository root:

```
./tests/run.sh
```

Filter by name or file:

```
./tests/run.sh --filter duration
./tests/run.sh tests/unit/sequence.bats
```

## Layout

- `tests/unit/` pure function tests. No real media.
- `tests/integration/` naming, conversion, and CLI tests with PATH shims.
- `tests/helpers/common.bash` loads the script without running `main`, builds shims, and defines `epoch_of`.
- `tests/vendor/` pinned bats-core 1.14.0, bats-support v0.3.0, and bats-assert v2.2.4.

## Rules For Agents

- Never edit `tests/vendor/`. Run the vendored binary through `tests/run.sh`.
- Every test file starts with `#!/usr/bin/env bats`. Use `load "${BATS_TEST_DIRNAME}/../helpers/common"`.
- Keep all writable state under `BATS_TEST_TMPDIR`. Never use fixed `/tmp` names.
- Use `run` for commands expected to fail. Assert `$status` explicitly with `assert_success` or `assert_failure`.
- Do not write `local x=$(cmd)` in tests. It hides failures. Split the assignment.
- Use `run --separate-stderr` when stdout and stderr must be asserted apart, and declare `bats_require_minimum_version 1.5.0`.
- Shims live only in the per-test shim directory. `ffprobe` reads `RC_FAKE_DURATION` or `RC_FAKE_DURATION_MAP`.
- `tmux` shim runs `new-window` through the shim PATH. `RC_TMUX_FAIL_NEW_WINDOW=1` and `RC_TMUX_ALWAYS_FFMPEG=1` cover failure and timeout paths.
- Set `RC_POLL_INTERVAL=0` in conversion tests so the wait loop is instant.

## Script Test Seam

`rc_process` runs `main` only when executed directly:

```
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
```

Tests source the script, so functions are callable without side effects.

## Environment

`tests/run.sh` sets `LC_ALL=C`, `TZ=UTC`, `BATS_TEST_TIMEOUT=30`, puts Homebrew bash first on `PATH`, and unsets `RC_*` overrides so caller state cannot change results.
