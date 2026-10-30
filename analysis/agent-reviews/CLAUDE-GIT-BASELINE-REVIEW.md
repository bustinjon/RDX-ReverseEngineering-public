# Claude review of CODEX-GIT-BASELINE-AUDIT.md

Date: 2026-10-25. Reviewer: Claude (lead). Status: audit ACCEPTED with the changes below. Nothing staged or committed.

## Verification of Codex's claims (done by Claude, independently)

| Codex claim | Claude check | Result |
|---|---|---|
| Head-unit serial in ~65 files (+10 filenames) | content scan of candidates | CONFIRMED (65 files by content; 67 incl. filenames) |
| Windows username in ~96 files | content scan | CONFIRMED (99 at the time, 126 in the enlarged set) |
| No private-key PEM markers | content scan | CONFIRMED (0) |
| Literal dev-keystore password in 5 build scripts | read the 5 lines | CONFIRMED (value is self-labelled LOCAL-TEST-ONLY; the .p12 itself is ignored) |
| `analysis/parallel-receiver-initial-query.txt` is decompiled Honda source hits | read head | CONFIRMED |
| `Notes/RDX-Android-Auto-Fullscreen-Findings.md` reproduces a decompiled method | read lines 83-92 | CONFIRMED |
| `analysis/HMIPresenter-video-mode-analysis.md` reproduces the original method | read lines 17-24 | CONFIRMED |
| Google-namespace facades are project-written | file sizes 19/72/48 lines, no decompiler markers, `GalReceiver.java` says "small API22 JNI facade" | SUPPORTED (formal clean-room provenance not established) |
| Project source in `clean-receiver/` etc. was wrongly ignored | directory listing | CONFIRMED - Claude's first `.gitignore` error |

Codex citation spot-check: line numbers cited for `initial-query` (378 vs 377 counted) were off by one; all other spot-checked content matched. Treat Codex line numbers as approximate.

## Claude mistake found and corrected

My first sensitive-content scan piped file *paths* into `Select-String`, which searches the path text, not file contents. Its "no hits" result was invalid. Re-run correctly (`Select-String -LiteralPath`), it now agrees with Codex.

## .gitignore changes applied (all Codex recommendations)

- Replaced whole-directory ignores of `clean-receiver`, `api22-tls-qualifier`, `decoder-test`, `m5-permission`, `m6-aoa`, `usb-probe`, `live-test-*` with ignore-all + allow-list of `source/`, `tests/`, `host/`, `fixtures/`, `golden/`, and top-level `.md/.json/.xml/.csv/.txt`.
- Added: `parallel-receiver-initial-query.txt`, `grid-test/build/`, copied live fixtures (`tests-*/fixtures/*.txt`), generated journal families.
- `Notes/*.txt` now tracked; `Notes/*.md` stays out (contains a decompiled method).
- Held out pending user decision: `HMIPresenter-video-mode-analysis.md`, `am-lock-task-mutator-excerpt.txt`, `getter-dispatch-excerpt.txt` (verbatim decompiled code).

## Resulting candidate set

963 files, 6.6 MB. No forbidden extensions/paths; 0 private-key markers. 778 contain no personal identifier; 185 contain at least one (67 head-unit serial, 126 Windows username, 6 dev-keystore password literal; overlapping).

## Why identifiers are NOT being scrubbed

The M5 readiness guard source (`scripts/Test-M5ArmReadiness.ps1`, `tools/m5/M5ArmReadiness.ps1`, `tools/m5/Test-M5ArmReadinessOffline.ps1`) embeds the head-unit serial to identify the correct device, and `PROJECT-INTEGRITY.json` hashes scripts/tools. Redaction would change safety-critical, hash-protected files and invalidate the preservation audit. Decision deferred to the GitHub step; a local-only commit exposes nothing.

## Open items for the user
1. Keep the 3 decompiled-excerpt files (+ Notes .md) out of Git? (recommended: yes)
2. Accept identifiers in a LOCAL commit and decide scrubbing before any GitHub push? (recommended: yes)
3. Approve the first LOCAL commit of the 963-file set? (recommended: yes, after 1-2)

Unresolved: `analysis/current-update-stack/README.md` (contains the serial, currently ignored with its folder) - leave ignored.
