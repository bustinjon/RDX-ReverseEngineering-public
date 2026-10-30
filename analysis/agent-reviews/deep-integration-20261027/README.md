# Evidence and host counterexamples

These artifacts support `../CODEX-DEEP-INTEGRATION-REVIEW-20261027.md`.

The probes compile the repository's **unchanged** `VideoDecoder.java` or `AaSessionService.java` directly with small synthetic dependencies. They do not compile an APK, execute ARM code, load the native receiver, read credential assets, emulate a phone, or access any device. An OBSERVED result confirms a Java control-flow counterexample under the injected conditions; it is not an Android runtime test or a playback success.

From the repository root:

[Code block omitted from public report; see authored source where available.]

Both runners use the installed JDK 17, write classes only in their own `classes/` directories, save `results.txt`, and compare the inspected production source hash before and after. The exact dependency fakes are in each runner's `src/` directory. The two classpaths are intentionally separate.

Results: decoder probe confirms three counterexamples with 22 assertions; session probe confirms three with 13 assertions. These assertions describe existing defects and are expected to change once those defects are fixed. They are review evidence rather than a proposed permanent regression suite.

Native evidence was produced with repository-local Rizin 0.9.1, read-only, `-N` to suppress user scripts and without `-w` or `-d`:

[Code block omitted from public report; see authored source where available.]

Rizin printed `Cannot determine entrypoint, using 0x000bb180.` The commands disassemble explicit symbol addresses, so they do not depend on its guessed executable entrypoint. Function starts/sizes came from the existing `analysis/parallel-aa-receiver/evidence/receiver-native-symbols.json`. Addresses are normalized Thumb addresses. This is static instruction decoding, not native execution.

`jni-table-offsets.json` records interface slots derived from the installed JDK's `include/jni.h`: count four reserved entries, then ordered `JNICALL` function pointers; multiply indices by four for this ARM32 library. The observed disassembly dispatches through those same offsets.

`selected-transcript-log-records.json` contains 44 selected log lines from tool-result records in Claude's local transcript, with physical JSONL record numbers and recording timestamps. It contains no tool commands, private credential values, or phone serial fields. These are saved outputs, not newly sampled device state. `permission-success-record-11368.txt` preserves the successful permission sequence, with unrelated extras omitted. The original transcript remains at `C:/Users/REDACTED/.claude/projects/C--Users-REDACTED-Desktop-RDX-ReverseEngineering/6b8797e0-4208-4e67-9c1f-18ad6acc866f.jsonl`.

The sibling `.evidence.json` contains the 34 native descriptor comparisons, library hashes, inspected-source hashes, frozen artifact hashes, and initial Git status. It is separate from the host-probe results because descriptor compatibility and Java failure behavior prove different things.
