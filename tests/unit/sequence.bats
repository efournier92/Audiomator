#!/usr/bin/env bats

setup() {
  load "${BATS_TEST_DIRNAME}/../helpers/common"
  load_lib
  T0="$(epoch_of "2026-01-01 10:00:00")"
  CHUNK=7200
}

@test "continues when the next file starts exactly on time" {
  run sequence_decision "$T0" "$CHUNK" "$((T0 + CHUNK))"
  assert_success
  assert_output "continue"
}

@test "continues within the 1 minute restart grace" {
  run sequence_decision "$T0" "$CHUNK" "$((T0 + CHUNK + 60))"
  assert_success
  assert_output "continue"
}

@test "restarts just past the 1 minute restart grace" {
  run sequence_decision "$T0" "$CHUNK" "$((T0 + CHUNK + 61))"
  assert_success
  assert_output "restart"
}

@test "continues a small early start within the duration margin" {
  run sequence_decision "$T0" "$CHUNK" "$((T0 + CHUNK - 3))"
  assert_success
  assert_output "continue"
}

@test "continues a start jitter of tens of seconds either way" {
  run sequence_decision "$T0" "$CHUNK" "$((T0 + CHUNK - 30))"
  assert_output "continue"

  run sequence_decision "$T0" "$CHUNK" "$((T0 + CHUNK - 60))"
  assert_output "continue"

  run sequence_decision "$T0" "$CHUNK" "$((T0 + CHUNK + 60))"
  assert_output "continue"
}

@test "restarts a backward jump larger than the restart grace" {
  run sequence_decision "$T0" "$CHUNK" "$((T0 + CHUNK - 61))"
  assert_success
  assert_output "restart"
}

@test "accounts for a 1 second short chunk" {
  run sequence_decision "$T0" 7199 "$((T0 + CHUNK))"
  assert_success
  assert_output "continue"
}

@test "accounts for a 3 second short chunk" {
  run sequence_decision "$T0" 7197 "$((T0 + CHUNK))"
  assert_success
  assert_output "continue"
}

@test "restarts when the previous file was not a full chunk" {
  run sequence_decision "$T0" 7196 "$((T0 + CHUNK))"
  assert_success
  assert_output "restart"

  run sequence_decision "$T0" 3600 "$((T0 + 3600))"
  assert_success
  assert_output "restart"
}

@test "restarts after a multi day time jump" {
  run sequence_decision "$T0" "$CHUNK" "$((T0 + 2 * 86400))"
  assert_success
  assert_output "restart"
}

@test "restarts when any required value is missing" {
  run sequence_decision "" "$CHUNK" "$((T0 + CHUNK))"
  assert_output "restart"

  run sequence_decision "$T0" "" "$((T0 + CHUNK))"
  assert_output "restart"

  run sequence_decision "$T0" "$CHUNK" ""
  assert_output "restart"
}

@test "restarts when timestamps are not numeric" {
  run sequence_decision "yesterday" "$CHUNK" "$((T0 + CHUNK))"
  assert_output "restart"
}

@test "honours an explicit max gap" {
  run sequence_decision "$T0" "$CHUNK" "$((T0 + CHUNK + 10))" 3 10
  assert_output "continue"

  run sequence_decision "$T0" "$CHUNK" "$((T0 + CHUNK + 11))" 3 10
  assert_output "restart"

  run sequence_decision "$T0" "$CHUNK" "$((T0 + CHUNK - 10))" 3 10
  assert_output "continue"

  run sequence_decision "$T0" "$CHUNK" "$((T0 + CHUNK - 11))" 3 10
  assert_output "restart"
}

@test "honours an explicit duration margin" {
  run sequence_decision "$T0" 7210 "$((T0 + CHUNK))" 10 60
  assert_output "continue"

  run sequence_decision "$T0" 7211 "$((T0 + CHUNK))" 10 60
  assert_output "restart"
}

@test "decide_sequence continues chunks that share a session base" {
  run decide_sequence "/in/202610310900_01.WAV" "2026-10-31-0900_00" "02:00:00" ""
  assert_output "continue"
}

@test "decide_sequence falls back to gap logic for different bases" {
  run decide_sequence "/in/2026_01_01_12_00_00.WAV" "2026-01-01-1000_00" "02:00:00" "" "$(epoch_of "2026-01-01 12:00:00")"
  assert_output "continue"
}

@test "decide_sequence restarts with no previous file" {
  run decide_sequence "/in/202610310900_00.WAV" "" "" "" ""
  assert_output "restart"
}
