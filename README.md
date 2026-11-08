# Audiomator

## Overview

- Bash tool for compressing raw WAV voice recordings into per-session MP3 files using `ffmpeg`.

## Process

- Prompts for a name for each raw file.
- Groups chunks into sessions.
- Builds a concat list.
- Runs one encode per session in tmux.

## Requirements

- `bash` 4.4 or newer.
- `ffmpeg` with `ffprobe` on `PATH`.
- `tmux`.
- `ffplay`, used only to preview a file. Optional.
- `macOS` or `Linux`.
  - `macOS` ships `bash` 3.2.
    - Install `bash` 4.4 or newer and put it first on `PATH`.
  - Date parsing supports both BSD and GNU `date`.

## Usage

### Command

```bash
./rc_process <input_dir> <output_dir> [debugger]
```

### Expectations

- Files in `<input_dir>` are renamed in place.
- Delete removes the raw file immediately, with no confirmation.

### Arguments

- `<input_dir>` holds the raw WAV files. Lowercase and uppercase `.wav` are both accepted.
- `<output_dir>` receives the MP3 files.
- `debugger` prints extra detail.

### Interface

#### Prompts

- For each raw file the tool shows its path, size, and duration, then asks for a name in `yyyy-mm-dd-HHMM` form.
- An empty line accepts the proposed default.

#### Inputs

- Type `d` or `delete` to delete the current file.
- Type a valid timestamp name followed by `d` or `D`, such as `2026-11-01-0817D`, to delete it after reviewing the proposed date.

## Filename Schemes

### Forms For Parsing Raw File Names

| Scheme | Example |
| --- | --- |
| `YYYY_MM_DD_HH_MM_SS` | `2026_01_01_12_00_45` |
| `YYYY-MM-DD-HHMM[_NN]` | `2026-01-01-1200_04` |
| `YYYYMMDDHHMM[_NN]` | `202610310900_01` |

### Chunking

- A shared base name indicates a single recording session.
- Chunks of a session continue each other, and a different base starts a new session.

## Overrides

### Tunables

| Variable | Default | Effect |
| --- | --- | --- |
| `RC_CHUNK_MARGIN` | `3` | Seconds either side of a 2 hour chunk still counted as full. |
| `RC_MAX_GAP` | `60` | Seconds past the expected next start still counted as one session. |
| `RC_WAIT_MAX` | `10000` | Maximum polls waiting on ffmpeg. |
| `RC_POLL_INTERVAL` | `1` | Seconds between polls. |
| `RC_CONVERT_MAX_JOBS` | `4` | Concurrent encodes. `0` means unlimited. |

### Example With Overrides

```bash
RC_CONVERT_MAX_JOBS=8 RC_CHUNK_MARGIN=5 ./rc_process ~/Rc/In ~/Rc/Out
```

## Test Suite

### Test Requirements

- `bash` 4.4 or newer.
- Uses the vendored bats in `tests/vendor/`.
  - No system bats install is required.

### Run All

```bash
./tests/run.sh
```

### Filter By Name/File

```bash
./tests/run.sh --filter sequence
./tests/run.sh tests/unit/sequence.bats
```

## Repo Layout

- `rc_process` is the current tool.
- `tests/` holds unit and integration tests plus the vendored bats.
- `versions/` archives the earlier Ruby script and the original bash script, timestamp-prefixed.
- `docs/` holds the discovery index and glossary.

