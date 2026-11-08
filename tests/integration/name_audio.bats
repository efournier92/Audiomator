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

@test "names three consecutive raw chunks as one sequence" {
  touch "$IN_DIR/2026_01_01_10_00_00.WAV" \
    "$IN_DIR/2026_01_01_12_00_00.WAV" \
    "$IN_DIR/2026_01_01_14_00_00.WAV"

  run bash -c 'source "$SCRIPT_PATH"; printf "2026-01-01-1000\n\n\n" | name_audio_files "$IN_DIR" "$OUT_DIR"'
  assert_success

  assert [ -f "$IN_DIR/2026-01-01-1000_00.WAV" ]
  assert [ -f "$IN_DIR/2026-01-01-1000_01.WAV" ]
  assert [ -f "$IN_DIR/2026-01-01-1000_02.WAV" ]
  assert [ ! -e "$IN_DIR/2026_01_01_10_00_00.WAV" ]
}

@test "restarts the sequence after a long jump between raw chunks" {
  touch "$IN_DIR/2026_01_01_10_00_00.WAV" \
    "$IN_DIR/2026_01_05_09_00_00.WAV"

  run bash -c 'source "$SCRIPT_PATH"; printf "2026-01-01-1000\n\n" | name_audio_files "$IN_DIR" "$OUT_DIR"'
  assert_success

  assert [ -f "$IN_DIR/2026-01-01-1000_00.WAV" ]
  assert [ -f "$IN_DIR/2026-01-05-0900_00.WAV" ]
  assert [ ! -e "$IN_DIR/2026-01-01-1000_01.WAV" ]
}

@test "continues after an already named chunk using a lazily probed duration" {
  touch "$IN_DIR/2026-01-01-1000_00.WAV" \
    "$IN_DIR/2026_01_01_12_00_00.WAV"

  run bash -c 'source "$SCRIPT_PATH"; printf "\n" | name_audio_files "$IN_DIR" "$OUT_DIR"'
  assert_success

  assert [ -f "$IN_DIR/2026-01-01-1000_01.WAV" ]
  assert [ ! -e "$IN_DIR/2026_01_01_12_00_00.WAV" ]
}

@test "restarts after an already named chunk when the next file jumps days ahead" {
  touch "$IN_DIR/2026-01-01-1000_00.WAV" \
    "$IN_DIR/2026_01_05_09_00_00.WAV"

  run bash -c 'source "$SCRIPT_PATH"; printf "\n" | name_audio_files "$IN_DIR" "$OUT_DIR"'
  assert_success

  assert [ -f "$IN_DIR/2026-01-05-0900_00.WAV" ]
  assert [ ! -e "$IN_DIR/2026-01-01-1000_01.WAV" ]
}

@test "continues chunks that share a session anchor" {
  touch "$IN_DIR/202610310900_00.WAV" \
    "$IN_DIR/202610310900_01.WAV" \
    "$IN_DIR/202610310900_02.WAV"

  run bash -c 'source "$SCRIPT_PATH"; printf "\n\n\n" | name_audio_files "$IN_DIR" "$OUT_DIR"'
  assert_success

  assert [ -f "$IN_DIR/2026-10-31-0900_00.WAV" ]
  assert [ -f "$IN_DIR/2026-10-31-0900_01.WAV" ]
  assert [ -f "$IN_DIR/2026-10-31-0900_02.WAV" ]
}

@test "stops with a nonzero status on end of input" {
  touch "$IN_DIR/2026_01_01_10_00_00.WAV"

  run bash -c 'source "$SCRIPT_PATH"; name_audio_files "$IN_DIR" "$OUT_DIR" </dev/null'
  assert_failure
  assert_output --partial "no input; stopping"
  assert [ -f "$IN_DIR/2026_01_01_10_00_00.WAV" ]
}
