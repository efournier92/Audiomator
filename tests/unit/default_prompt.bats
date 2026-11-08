#!/usr/bin/env bats

setup() {
  load "${BATS_TEST_DIRNAME}/../helpers/common"
  load_lib
}

@test "continue uses the previous base name" {
  run calculate_default_prompt_value \
    "continue" \
    "2026-01-01-1000_03" \
    "/in/2026_01_01_12_00_00.WAV" \
    "2026-02-"
  assert_success
  assert_output "2026-01-01-1000"
}

@test "continue handles a suffix-free previous name" {
  run calculate_default_prompt_value \
    "continue" \
    "2026-01-01-1000" \
    "/in/2026_01_01_12_00_00.WAV" \
    "2026-02-"
  assert_success
  assert_output "2026-01-01-1000"
}

@test "restart uses the parsed underscore raw name" {
  run calculate_default_prompt_value \
    "restart" \
    "2026-01-01-1000_03" \
    "/in/2026_01_05_09_00_00.WAV" \
    "2026-02-"
  assert_success
  assert_output "2026-01-05-0900"
}

@test "restart uses the parsed dashed raw name with suffix" {
  run calculate_default_prompt_value \
    "restart" \
    "" \
    "/in/2026-01-01-0800_00.WAV" \
    "2026-02-"
  assert_success
  assert_output "2026-01-01-0800"
}

@test "restart falls back to the year-month when the raw name is unparseable" {
  run calculate_default_prompt_value \
    "restart" \
    "" \
    "/in/recording.WAV" \
    "2026-02-"
  assert_success
  assert_output "2026-02-"
}
