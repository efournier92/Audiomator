# Critique Ledger: rc-process chunk sequencing

- Goal: Extend 2-hour chunk detection to a 3 second margin, restart sequences on long timestamp jumps, and prove the behavior with tests.
- Started: 2026-11-07
- Branch: master
- Lens set: correctness, testing, scale, product

## Findings

- C-20261107-01 | 2026-11-07 | correctness | high | high | addressed | Sequences split at chunk 3 because continuity used the anchor base, not the previous start | resolve_sequence_decision. tests/integration/name_audio.bats
- C-20261107-02 | 2026-11-07 | correctness | medium | high | addressed | Local-TZ epoch parsing made DST or timezone changes look like one hour jumps | rc_process filename_to_epoch uses date -u wall-clock labels. tests/unit/filename.bats
- C-20261107-03 | 2026-11-07 | correctness | medium | high | addressed | Non-numeric env values caused bash arithmetic errors and skipped the restart check | rc_process config normalization. tests/unit/config.bats
- C-20261107-04 | 2026-11-07 | correctness | low | high | addressed | Minute-truncated bases reduced the restart grace by up to 59 seconds | rc_process stores previous raw epoch. default_prompt jitter test
- C-20261107-05 | 2026-11-07 | correctness | low | high | addressed | Impossible calendar dates normalized to other days and month-13 names passed validation | rc_process is_valid_calendar_timestamp. filename.bats and validation.bats
- C-20261107-06 | 2026-11-07 | testing | high | high | addressed | name_audio_files had zero callers, so replacing its body left every test green | tests/integration/name_audio.bats drives rename, delete-free flow, defaults, and EOF
- C-20261107-07 | 2026-11-07 | testing | high | high | addressed | Shims allowed broken argv and decimal parsing to pass | tests pin exact concat order and exact ffmpeg argv. ffprobe emits decimals
- C-20261107-08 | 2026-11-07 | testing | medium | high | addressed | main, ensure_valid_directories, and start_conversion were unpinned | tests/integration/main.bats covers conversion, cleanup, bad args, and status propagation
- C-20261107-09 | 2026-11-07 | testing | medium | high | addressed | Caller RC_* variables leaked into the suite | tests/run.sh unsets them. tests/unit/config.bats exercises env overrides
- C-20261107-10 | 2026-11-07 | testing | medium | high | addressed | Helpers hardcoded BSD date and never exercised the GNU fallback | tests/helpers/common.bash epoch_of has a GNU fallback. run.sh sets TZ=UTC
- C-20261107-11 | 2026-11-07 | testing | medium | high | addressed | Calendar-invalid timestamps and second-60 values were untested | tests/unit/filename.bats adds leap-day, Feb-29, Apr-31, day-32, and second-60 cases
- C-20261107-12 | 2026-11-07 | testing | medium | high | addressed | Delete was under-asserted and any text ending in d deleted the file | rc_process requires exact d or delete. validation.bats asserts output and survival
- C-20261107-13 | 2026-11-07 | testing | medium | high | addressed | The wait loop was unpinned and its cap was untestable | convert.bats asserts tmux list-windows and the poll-cap warning via RC_WAIT_MAX
- C-20261107-14 | 2026-11-07 | testing | low | high | rejected | is_in_split_sequence has no production caller | Retained as the compatible public helper the user asked to widen. duration.bats pins it
- C-20261107-15 | 2026-11-07 | testing | low | high | addressed | Option-only runner invocations failed and the bash guard only checked the major version | tests/run.sh appends default paths for option-only args and checks 4.4
- C-20261107-16 | 2026-11-07 | scale | high | high | addressed | The name phase probed every already-named file, costing 1200 ffprobes per rerun | rc_process defers probe and epoch parsing. benchmark 14.4s to 0.13s for 1200 files
- C-20261107-17 | 2026-11-07 | scale | high | medium | addressed | Convert launched every sequence ffmpeg at once | rc_process caps at RC_CONVERT_MAX_JOBS default 4 with a bounded slot wait. convert.bats slot-wait tests
- C-20261107-18 | 2026-11-07 | scale | high | medium | addressed | The wait loop hit a silent 10000 poll cap | rc_process warns on timeout. convert.bats pins it. RC_WAIT_MAX tunes it
- C-20261107-19 | 2026-11-07 | scale | medium | high | rejected | Naming is human-serial with one prompt and 0.1s preview sleep per raw file | Inherent to the interactive archival workflow. a batch mode needs a new CLI surface
- C-20261107-20 | 2026-11-07 | scale | medium | high | rejected | Convert forks about five substitutions per chunk and seven per sequence | Measured 20s per 1000 files with shims. payoff is low against change risk
- C-20261107-21 | 2026-11-07 | scale | low | high | addressed | filename_to_epoch recomputed the previous file epoch on every prompt | rc_process caches the previous epoch and target. three-chunk test exercises it
- C-20261107-22 | 2026-11-07 | scale | low | high | rejected | ffprobe output still pipes through cut | About 2s per 1000 files, low payoff, and trimming it would complicate parsing
- C-20261107-23 | 2026-11-07 | scale | low | medium | addressed | tmux window names are grepped every poll and unrelated ffmpeg windows can pin the cap | wait_for_ffmpeg_slots bounds the wait with RC_WAIT_MAX and warns instead of hanging
- C-20261107-24 | 2026-11-07 | product | high | high | addressed | Any input ending in d deleted a raw WAV with no confirmation or undo | rc_process only deletes on exact d or delete. validation.bats pins the guard
- C-20261107-25 | 2026-11-07 | product | medium | high | addressed | The prompt did not say whether it was continuing or restarting | rc_process prints a continue or restart line before each prompt
- C-20261107-26 | 2026-11-07 | product | medium | high | addressed | EOF or non-TTY stdin looped forever respawning previews | rc_process returns nonzero on read failure. name_audio.bats and main.bats cover EOF
- C-20261107-27 | 2026-11-07 | product | medium | high | addressed | Missing ffplay or headless SSH failed silently | rc_process checks command -v ffplay before previewing
- C-20261107-28 | 2026-11-07 | product | medium | high | addressed | Directory and launch errors were opaque and exit codes were weak | rc_process names paths, returns status, reports launch failures, and warns on timeout
- C-20261107-29 | 2026-11-07 | product | medium | high | rejected | No counts, progress summary, or conversion feedback | A summary needs counters threaded through both phases. deferred against minimal-CLI constraint
- C-20261107-30 | 2026-11-07 | product | medium | high | rejected | An unparseable filename prefills the current year-month, an unusable base | Original fallback retained. the user can type a full name and EOF now exits cleanly
