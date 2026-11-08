#!/usr/bin/env bats

setup() {
  load "${BATS_TEST_DIRNAME}/../helpers/common"
  load_lib
  setup_shims
  export RC_POLL_INTERVAL=0
  IN_DIR="$BATS_TEST_TMPDIR/in"
  OUT_DIR="$BATS_TEST_TMPDIR/out"
  mkdir -p "$IN_DIR" "$OUT_DIR"
}

@test "writes a concat file and launches ffmpeg for a 00 chunk" {
  touch "$IN_DIR/2026-01-01-1200_00.WAV" \
    "$IN_DIR/2026-01-01-1200_01.WAV" \
    "$IN_DIR/2026-01-01-1200_02.WAV"

  run convert_audio_files "$IN_DIR" "$OUT_DIR"
  assert_success

  concat="$OUT_DIR/.concat/2026-01-01-1200.txt"
  assert [ -f "$concat" ]

  run grep -F "file '$IN_DIR/2026-01-01-1200_00.WAV'" "$concat"
  assert_success

  run grep -F "file '$IN_DIR/2026-01-01-1200_01.WAV'" "$concat"
  assert_success

  run grep -F "file '$IN_DIR/2026-01-01-1200_02.WAV'" "$concat"
  assert_success

  run cat "$concat"
  assert_output "file '$IN_DIR/2026-01-01-1200_00.WAV'
file '$IN_DIR/2026-01-01-1200_01.WAV'
file '$IN_DIR/2026-01-01-1200_02.WAV'"

  run grep -F "tmux new-window ffmpeg -f concat -safe 0 -i \"$concat\" -c:a libmp3lame -ac 1 -q:a 15 \"$OUT_DIR/2026-01-01-1200.mp3\"" "$RC_SHIM_LOG"
  assert_success

  # The wait loop must actually poll tmux after launching.
  run grep -F "tmux list-windows" "$RC_SHIM_LOG"
  assert_success

  assert [ -f "$OUT_DIR/2026-01-01-1200.mp3" ]
}

@test "does not launch ffmpeg for a non 00 chunk" {
  touch "$IN_DIR/2026-01-01-1200_01.WAV"

  run convert_audio_files "$IN_DIR" "$OUT_DIR"
  assert_success

  run grep -F "ffmpeg -f concat" "$RC_SHIM_LOG"
  assert_failure
}

@test "includes lowercase wav chunks" {
  touch "$IN_DIR/2026-01-01-1200_00.wav" "$IN_DIR/2026-01-01-1200_01.wav"

  run convert_audio_files "$IN_DIR" "$OUT_DIR"
  assert_success

  concat="$OUT_DIR/.concat/2026-01-01-1200.txt"
  run grep -F "2026-01-01-1200_00.wav" "$concat"
  assert_success

  run grep -F "2026-01-01-1200_01.wav" "$concat"
  assert_success

  run grep -F "ffmpeg -f concat" "$RC_SHIM_LOG"
  assert_success
}

@test "skips invalid filenames" {
  touch "$IN_DIR/2026-01-01-1200_00.WAV" "$IN_DIR/bad@name.WAV"

  run convert_audio_files "$IN_DIR" "$OUT_DIR"
  assert_success

  concat="$OUT_DIR/.concat/2026-01-01-1200.txt"
  run grep -F "bad@name" "$concat"
  assert_failure
}

@test "keeps separate sequences in separate concat files" {
  touch "$IN_DIR/2026-01-01-1200_00.WAV" "$IN_DIR/2026-01-01-1200_01.WAV"
  touch "$IN_DIR/2026-01-02-0900_00.WAV" "$IN_DIR/2026-01-02-0900_01.WAV"

  run convert_audio_files "$IN_DIR" "$OUT_DIR"
  assert_success

  assert [ -f "$OUT_DIR/.concat/2026-01-01-1200.txt" ]
  assert [ -f "$OUT_DIR/.concat/2026-01-02-0900.txt" ]

  run grep -F "2026-01-02-0900_01.WAV" "$OUT_DIR/.concat/2026-01-02-0900.txt"
  assert_success

  run grep -F "2026-01-01-1200_01.WAV" "$OUT_DIR/.concat/2026-01-02-0900.txt"
  assert_failure
}

@test "the ffmpeg wait loop terminates even when no window reports ffmpeg" {
  touch "$IN_DIR/2026-01-01-1200_00.WAV"
  start="$(date +%s)"

  run convert_audio_files "$IN_DIR" "$OUT_DIR"
  assert_success

  elapsed=$(( $(date +%s) - start ))
  assert [ "$elapsed" -lt 5 ]
}

@test "slot wait is a no-op when the cap is zero" {
  run wait_for_ffmpeg_slots 0
  assert_success
  assert_output ""
}

@test "slot wait times out with a warning when the cap stays full" {
  export RC_TMUX_ALWAYS_FFMPEG=1
  export RC_WAIT_MAX=1
  export RC_POLL_INTERVAL=0

  run wait_for_ffmpeg_slots 1
  assert_success
  assert_output --partial "timed out waiting for an ffmpeg slot after 1 polls"
}

@test "reports a tmux launch failure" {
  export RC_TMUX_FAIL_NEW_WINDOW=1
  touch "$IN_DIR/2026-01-01-1200_00.WAV"

  run convert_audio_files "$IN_DIR" "$OUT_DIR"
  assert_success
  assert_output --partial "failed to launch ffmpeg for 2026-01-01-1200"
}

@test "warns when the wait loop hits its poll cap" {
  export RC_TMUX_ALWAYS_FFMPEG=1
  export RC_WAIT_MAX=2
  touch "$IN_DIR/2026-01-01-1200_00.WAV"

  run convert_audio_files "$IN_DIR" "$OUT_DIR"
  assert_success
  assert_output --partial "timed out waiting for ffmpeg after 2 polls"
}
