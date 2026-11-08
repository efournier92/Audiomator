#!/usr/bin/env bats

setup() {
  load "${BATS_TEST_DIRNAME}/../helpers/common"
}

@test "env tunables are validated and normalized" {
  run bash -c 'RC_MAX_GAP=08; RC_CHUNK_MARGIN=1m; RC_WAIT_MAX=abc; RC_POLL_INTERVAL=007; RC_CONVERT_MAX_JOBS=xyz; source "$1"; printf "%s %s %s %s %s\n" "$RC_MAX_GAP" "$RC_CHUNK_MARGIN" "$RC_WAIT_MAX" "$RC_POLL_INTERVAL" "$RC_CONVERT_MAX_JOBS"' _ "$SCRIPT"
  assert_success
  assert_output "8 3 10000 7 4"
}

@test "env max gap feeds the sequence logic" {
  run bash -c 'RC_MAX_GAP=0; source "$1"; sequence_decision 0 7200 7200' _ "$SCRIPT"
  assert_output "continue"

  run bash -c 'RC_MAX_GAP=0; source "$1"; sequence_decision 0 7200 7201' _ "$SCRIPT"
  assert_output "restart"
}

@test "env chunk margin feeds the duration logic" {
  run bash -c 'RC_CHUNK_MARGIN=10; source "$1"; is_full_chunk_seconds 7210 && echo yes' _ "$SCRIPT"
  assert_output "yes"

  run bash -c 'RC_CHUNK_MARGIN=10; source "$1"; is_full_chunk_seconds 7211 || echo no' _ "$SCRIPT"
  assert_output "no"
}
