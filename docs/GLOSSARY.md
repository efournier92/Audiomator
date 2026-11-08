# Glossary

**Session** A single continuous recording, identified by one timestamp base name shared by all its chunks.
_Avoid_: sequence group, run.

**Chunk** One raw WAV file that is part of a session and carries a two-digit suffix such as `_03`.
_Avoid_: part, segment.

**Base Name** The normalized timestamp shared by all chunks in a session, formatted `YYYY-MM-DD-HHMM`.
_Avoid_: anchor, prefix.

**Raw File** A WAV file as delivered by the recorder, still carrying its original name and not yet renamed.
_Avoid_: source file, input.

**Renamed File** A WAV file the tool has given a base name and a chunk suffix in the `yyyy-mm-dd-HHMM_NN` form.
_Avoid_: output file, processed file.

**Decision** The tool verdict for the next raw file, either `Continuing` when it belongs to the current session or `Restarting` when it starts a new one.
_Avoid_: sequence state, mode.

**Concat File** The temporary text list of chunk paths that ffmpeg reads to encode one session into a single MP3.
_Avoid_: playlist, manifest.

**Slot** One allowance under `RC_CONVERT_MAX_JOBS` for a concurrently running encode.
_Avoid_: worker, thread.

**Tunable** An environment variable that overrides a default such as `RC_CHUNK_MARGIN` or `RC_MAX_GAP`.
_Avoid_: setting, config.
