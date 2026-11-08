# Discovery

One line per finding, decision, assumption, trap, question, or outcome. Newest first. Evidence required.
Scope tokens: cli, naming, sequence, tests

## Entries

- D-20261108-07 | 2026-11-08 | [outcome] | tests | Suite covers parsing, sequence decisions, naming flow, conversion, and CLI with 76 tests, all green. | `./tests/run.sh`
- D-20261108-06 | 2026-11-08 | [decision] | cli | Prompt display goes to stderr so the command substitution that captures the chosen name sees only the name. | `rc_process` prompt_for_file_name
- D-20261108-05 | 2026-11-08 | [decision] | cli | Delete fires only on exact d or delete, or on a valid timestamp name plus a trailing D. Arbitrary text ending in d never deletes. | `tests/unit/validation.bats`
- D-20261108-04 | 2026-11-08 | [decision] | naming | Three raw schemes are parsed: YYYY_MM_DD_HH_MM_SS, YYYY-MM-DD-HHMM[_NN], and YYYYMMDDHHMM[_NN]. | `tests/unit/filename.bats`
- D-20261108-03 | 2026-11-08 | [trap] | naming | Recorder names encode the session start, so every chunk shares the base and a start-based gap check restarts them all. | `tests/integration/name_audio.bats`
- D-20261108-02 | 2026-11-08 | [decision] | sequence | A shared base name continues a session. Different bases fall back to a start-versus-start-plus-duration gap check bounded by RC_MAX_GAP. | `tests/unit/sequence.bats`
- D-20261108-01 | 2026-11-08 | [decision] | sequence | Chunk length is fixed at 7200 seconds and the full-chunk test allows RC_CHUNK_MARGIN of 3 seconds either side. | `rc_process` is_full_chunk_seconds
