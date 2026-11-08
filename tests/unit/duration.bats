#!/usr/bin/env bats

setup() {
  load "${BATS_TEST_DIRNAME}/../helpers/common"
  load_lib
}

@test "format_duration pads hours, minutes and seconds" {
  run format_duration 0
  assert_output "00:00:00"

  run format_duration 59
  assert_output "00:00:59"

  run format_duration 3599
  assert_output "00:59:59"

  run format_duration 7199
  assert_output "01:59:59"

  run format_duration 7200
  assert_output "02:00:00"

  run format_duration 86399
  assert_output "23:59:59"
}

@test "duration_to_seconds parses valid durations" {
  run duration_to_seconds "00:00:00"
  assert_success
  assert_output "0"

  run duration_to_seconds "01:59:59"
  assert_success
  assert_output "7199"

  run duration_to_seconds "02:00:00"
  assert_success
  assert_output "7200"

  run duration_to_seconds "10:30:05"
  assert_success
  assert_output "37805"
}

@test "duration_to_seconds rejects malformed durations" {
  run duration_to_seconds "7200"
  assert_failure

  run duration_to_seconds "02:00"
  assert_failure

  run duration_to_seconds "02:60:00"
  assert_failure

  run duration_to_seconds "02:00:60"
  assert_failure

  run duration_to_seconds "aa:bb:cc"
  assert_failure
}

@test "is_full_chunk_seconds accepts a 3 second margin around 2 hours" {
  run is_full_chunk_seconds 7200
  assert_success

  run is_full_chunk_seconds 7197
  assert_success

  run is_full_chunk_seconds 7203
  assert_success

  run is_full_chunk_seconds 7199
  assert_success
}

@test "is_full_chunk_seconds rejects durations outside the margin" {
  run is_full_chunk_seconds 7196
  assert_failure

  run is_full_chunk_seconds 7204
  assert_failure

  run is_full_chunk_seconds 0
  assert_failure

  run is_full_chunk_seconds "not-a-number"
  assert_failure
}

@test "is_full_chunk_seconds honours an explicit margin" {
  run is_full_chunk_seconds 7205 5
  assert_success

  run is_full_chunk_seconds 7190 10
  assert_success

  run is_full_chunk_seconds 7206 5
  assert_failure
}
