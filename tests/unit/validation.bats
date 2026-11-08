#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  load "${BATS_TEST_DIRNAME}/../helpers/common"
  load_lib
  WORK="$BATS_TEST_TMPDIR/work"
  mkdir -p "$WORK"
}

@test "is_valid_file accepts WAV and wav files" {
  touch "$WORK/2026-01-01-1200_00.WAV" "$WORK/2026-01-01-1200_00.wav"

  run is_valid_file "$WORK/2026-01-01-1200_00.WAV"
  assert_success

  run is_valid_file "$WORK/2026-01-01-1200_00.wav"
  assert_success
}

@test "is_valid_file rejects missing files and non-WAV extensions" {
  touch "$WORK/2026-01-01-1200_00.mp3"

  run is_valid_file "$WORK/2026-01-01-1200_00.mp3"
  assert_failure

  run is_valid_file "$WORK/does-not-exist.WAV"
  assert_failure
}

@test "is_valid_file rejects reserved characters and quote injection" {
  touch "$WORK/bad@name.WAV" "$WORK/bad'name.WAV"

  run is_valid_file "$WORK/bad@name.WAV"
  assert_failure

  run is_valid_file "$WORK/bad'name.WAV"
  assert_failure
}

@test "is_valid_file_name requires a date base and a two digit suffix" {
  run is_valid_file_name "2026-01-01-1200_00"
  assert_success

  run is_valid_file_name "/in/2026-01-01-1200_99.WAV"
  assert_success

  run is_valid_file_name "2026-01-01-1200"
  assert_failure

  run is_valid_file_name "2026-01-01-1200_0"
  assert_failure

  run is_valid_file_name "2026-01-01-1200_000"
  assert_failure

  run is_valid_file_name "not-a-date_00"
  assert_failure
}

@test "is_valid_file_name rejects impossible calendar dates" {
  run is_valid_file_name "2026-13-01-1200_00"
  assert_failure

  run is_valid_file_name "2026-02-30-1200_00"
  assert_failure

  run is_valid_file_name "2026-04-31-1200_00"
  assert_failure

  run is_valid_file_name "2026-01-01-2400_00"
  assert_failure

  run is_valid_file_name "2024-02-29-1200_00"
  assert_success
}

@test "parse_date strips directory, extension and suffix" {
  run parse_date "/in/2026-01-01-1200_03.WAV"
  assert_output "2026-01-01-1200"

  run parse_date "2026-01-01-1200.wav"
  assert_output "2026-01-01-1200"
}

@test "try_parse_filename_from_raw handles both raw naming schemes" {
  run try_parse_filename_from_raw "/in/2026_01_01_12_00_45.WAV"
  assert_output "2026-01-01-1200"

  run try_parse_filename_from_raw "2026-01-01-1200.WAV"
  assert_output "2026-01-01-1200"

  run try_parse_filename_from_raw "2026-01-01-1200_04.WAV"
  assert_output "2026-01-01-1200"

  run try_parse_filename_from_raw "202610301855_02.WAV"
  assert_output "2026-10-30-1855"

  run try_parse_filename_from_raw "202610310900_01.WAV"
  assert_output "2026-10-31-0900"

  run try_parse_filename_from_raw "recording.WAV"
  assert_output ""
}

@test "get_next_increment finds the first free suffix" {
  run get_next_increment "$WORK" "2026-01-01-1200"
  assert_output "2026-01-01-1200_00"

  touch "$WORK/2026-01-01-1200_00.WAV" "$WORK/2026-01-01-1200_01.wav"

  run get_next_increment "$WORK" "2026-01-01-1200"
  assert_output "2026-01-01-1200_02"
}

@test "handle_user_input_and_file_action renames a file with the next suffix" {
  touch "$WORK/raw.WAV"

  run handle_user_input_and_file_action "2026-01-01-1200" "$WORK/raw.WAV" "$WORK" "$WORK/out"
  assert_success
  assert_output "2026-01-01-1200_00"

  assert [ -f "$WORK/2026-01-01-1200_00.WAV" ]
  assert [ ! -e "$WORK/raw.WAV" ]
}

@test "handle_user_input_and_file_action increments past existing chunks" {
  touch "$WORK/raw.WAV" "$WORK/2026-01-01-1200_00.WAV"

  run handle_user_input_and_file_action "2026-01-01-1200" "$WORK/raw.WAV" "$WORK" "$WORK/out"
  assert_success
  assert_output "2026-01-01-1200_01"
}

@test "handle_user_input_and_file_action deletes on the exact token D" {
  touch "$WORK/raw.WAV"

  run --separate-stderr handle_user_input_and_file_action "D" "$WORK/raw.WAV" "$WORK" "$WORK/out"
  assert_success
  assert_output ""
  assert [ ! -e "$WORK/raw.WAV" ]
}

@test "handle_user_input_and_file_action deletes on the exact word delete" {
  touch "$WORK/raw.WAV"

  run --separate-stderr handle_user_input_and_file_action "delete" "$WORK/raw.WAV" "$WORK" "$WORK/out"
  assert_success
  assert [ ! -e "$WORK/raw.WAV" ]
}

@test "handle_user_input_and_file_action does not delete text ending in d" {
  touch "$WORK/raw.WAV"

  run handle_user_input_and_file_action "badd" "$WORK/raw.WAV" "$WORK" "$WORK/out"
  assert_failure
  assert [ -f "$WORK/raw.WAV" ]
}

@test "handle_user_input_and_file_action deletes on a valid name with a trailing D" {
  touch "$WORK/raw.WAV"

  run --separate-stderr handle_user_input_and_file_action "2026-11-01-0817D" "$WORK/raw.WAV" "$WORK" "$WORK/out"
  assert_success
  assert [ ! -e "$WORK/raw.WAV" ]
}

@test "handle_user_input_and_file_action does not delete a bad date ending in D" {
  touch "$WORK/raw.WAV"

  run handle_user_input_and_file_action "2026-99-99-9999D" "$WORK/raw.WAV" "$WORK" "$WORK/out"
  assert_failure
  assert [ -f "$WORK/raw.WAV" ]
}

@test "handle_user_input_and_file_action rejects invalid names and keeps the file" {
  touch "$WORK/raw.WAV"

  run handle_user_input_and_file_action "nope" "$WORK/raw.WAV" "$WORK" "$WORK/out"
  assert_failure
  assert [ -f "$WORK/raw.WAV" ]
}

@test "get_formatted_duration uses ffprobe output and drops decimals" {
  setup_shims
  touch "$WORK/2026-01-01-1200_00.WAV"
  export RC_FAKE_DURATION="7200.000000"

  run get_formatted_duration "$WORK/2026-01-01-1200_00.WAV"
  assert_success
  assert_output "02:00:00"

  export RC_FAKE_DURATION="7199.999999"

  run get_formatted_duration "$WORK/2026-01-01-1200_00.WAV"
  assert_success
  assert_output "01:59:59"
}
