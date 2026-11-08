#!/usr/bin/env bats

setup() {
  load "${BATS_TEST_DIRNAME}/../helpers/common"
  load_lib
  setup_shims
  export RC_POLL_INTERVAL=0
  IN_DIR="$BATS_TEST_TMPDIR/in"
  OUT_DIR="$BATS_TEST_TMPDIR/out"
  mkdir -p "$IN_DIR" "$OUT_DIR"
  export SCRIPT_PATH="$SCRIPT"
  export IN_DIR OUT_DIR
}

@test "main converts pre-named chunks and removes the concat directory" {
  touch "$IN_DIR/2026-01-01-1200_00.WAV" "$IN_DIR/2026-01-01-1200_01.WAV"

  run bash -c 'source "$SCRIPT_PATH"; main "$IN_DIR" "$OUT_DIR"'
  assert_success

  assert [ -f "$OUT_DIR/2026-01-01-1200.mp3" ]
  assert [ ! -e "$OUT_DIR/.concat" ]
}

@test "main names and messages the missing input directory" {
  run bash -c 'source "$SCRIPT_PATH"; main "$1" "$2"' _ "$BATS_TEST_TMPDIR/missing" "$OUT_DIR"
  assert_failure
  assert_output --partial "Input and output directories expected"
  assert_output --partial "$BATS_TEST_TMPDIR/missing"
}

@test "main propagates a naming failure on end of input" {
  touch "$IN_DIR/2026_01_01_10_00_00.WAV"

  run bash -c 'source "$SCRIPT_PATH"; main "$IN_DIR" "$OUT_DIR" </dev/null'
  assert_failure
  assert_output --partial "no input; stopping"
}
