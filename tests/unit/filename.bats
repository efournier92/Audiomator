#!/usr/bin/env bats

setup() {
  load "${BATS_TEST_DIRNAME}/../helpers/common"
  load_lib
}

@test "filename_to_epoch parses raw phone names with seconds" {
  run filename_to_epoch "2026_01_01_12_00_00.WAV"
  assert_success
  assert_output "$(epoch_of "2026-01-01 12:00:00")"
}

@test "filename_to_epoch parses renamed base names" {
  run filename_to_epoch "2026-01-01-1200.WAV"
  assert_success
  assert_output "$(epoch_of "2026-01-01 12:00:00")"
}

@test "filename_to_epoch parses names with a chunk suffix" {
  run filename_to_epoch "2026-01-01-1200_05.WAV"
  assert_success
  assert_output "$(epoch_of "2026-01-01 12:00:00")"
}

@test "filename_to_epoch ignores directories and extensions" {
  run filename_to_epoch "/some/dir/2026-01-01-1200_01.WAV"
  assert_success
  assert_output "$(epoch_of "2026-01-01 12:00:00")"
}

@test "filename_to_epoch preserves seconds in raw names" {
  run filename_to_epoch "2026_01_01_12_00_45.WAV"
  assert_success
  assert_output "$(epoch_of "2026-01-01 12:00:45")"
}

@test "filename_to_epoch rejects unsupported or impossible timestamps" {
  run filename_to_epoch "not-a-date.WAV"
  assert_failure

  run filename_to_epoch "2026_01_01.WAV"
  assert_failure

  run filename_to_epoch "2026-13-01-1200.WAV"
  assert_failure

  run filename_to_epoch "2026-01-01-2500.WAV"
  assert_failure

  run filename_to_epoch "2026-01-01-1260.WAV"
  assert_failure

  run filename_to_epoch ""
  assert_failure
}

@test "filename_to_epoch rejects impossible calendar dates" {
  run filename_to_epoch "2025-02-29-1200.WAV"
  assert_failure

  run filename_to_epoch "2026-04-31-1200.WAV"
  assert_failure

  run filename_to_epoch "2026-01-32-1200.WAV"
  assert_failure

  run filename_to_epoch "2026_01_01_12_00_60.WAV"
  assert_failure

  run filename_to_epoch "202602291200_00.WAV"
  assert_failure
}

@test "filename_to_epoch parses compact raw names" {
  run filename_to_epoch "202610301855_02.WAV"
  assert_success
  assert_output "$(epoch_of "2026-10-30 18:55:00")"

  run filename_to_epoch "202610310900_00.WAV"
  assert_success
  assert_output "$(epoch_of "2026-10-31 09:00:00")"
}

@test "filename_to_epoch accepts a real leap day" {
  run filename_to_epoch "2024-02-29-1200.WAV"
  assert_success
  assert_output "$(epoch_of "2024-02-29 12:00:00")"
}
