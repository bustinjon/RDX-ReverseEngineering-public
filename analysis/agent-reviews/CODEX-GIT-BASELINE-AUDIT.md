The baseline should not be approved as-is. Of **628 in-scope candidates**, I recommend **124 IGNORE, 353 TRACK, and 151 MANUAL REVIEW**. Nothing was changed.

1. **Files inspected**

   Inspected candidate names, sizes, signatures and content patterns across **628 files / 6,390,428 bytes**, with focused content inspection of suspicious files. Git listed 629 candidates; one lead-owned `analysis/agent-reviews/CLAUDE-*.md` file was excluded as instructed.

   Also inspected `PROJECT-RULES.md`, `AGENTS.md`, `.gitignore`, all three `Notes/` files, the three Google-namespace facades and their corresponding local decompilations, 104 ignored project Java files, 244 ignored fixture/provenance files, selected ignored reports, and preservation metadata.

   Below, `P/` means `analysis/parallel-aa-receiver/`; `G/` means `P/m5-locktask-guard-20261025-195507/`.

2. **Files changed**

   **None.**

3. **Commands run**

   Read-only commands included:

   - `git ls-files --others --exclude-standard`
   - `git status --ignored --short`
   - `git ls-files --others --ignored --exclude-standard`
   - `git check-ignore -v <inspected paths>`
   - `git status --short --branch`
   - `git diff --cached --name-only`
   - `git ls-files --stage`
   - `git rev-parse --verify HEAD`
   - `Get-Content`, `Get-Item`, `Get-ChildItem`, `Get-FileHash`, `Get-Command`, and `rg -n`
   - In-memory Node scripts for signature/content scans, counted-line excerpts, classification counts, comparisons and SHA-256 checks.

   Python launch attempts failed; a PowerShell binary-read attempt encountered constrained-language restrictions. Node successfully completed the replacement checks. No project build, validation or device script was executed.

4. **Tests run and results**

   | Audit check | Result |
   |---|---|
   | Candidate starting signatures: ZIP/PK, DEX, ELF, Java class, PE | **0 matches** |
   | Candidate private-key PEM markers and selected common token formats | **0 matches** |
   | Long contiguous Base64-like content exceeding 250 characters | **0 matches** |
   | Candidate NUL-containing files | **2**, both generated 65,537-byte zero-filled corruption fixtures |
   | Saved fixture comparisons against documented live sources | **54/54 byte-identical** |
   | Ignored project Java scan | **104 files**; no tested decompiler markers, personal paths, known serial, email, MAC, private-key markers or token formats |
   | Ignored clean fixture scan | **244 files**, 334,574 bytes; no tested executable signatures, private-key markers, known serial or Windows user paths |
   | Candidate preservation comparison | **628/628 unchanged** |

   No application tests were run.

5. **Findings**

   Recommendations below apply to the files as currently written.

   | Finding | Recommendation | Confidence | Scope |
   |---|---|---|---|
   | Bulk decompiled Honda/Google source-search output survives under an innocent `.txt` name | **IGNORE** | **CONFIRMED** | `analysis/parallel-receiver-initial-query.txt` — **1 file**, 77,797 bytes |
   | Live evidence was copied back into nominal test-fixture directories | **IGNORE** | **CONFIRMED** | Seven raw `.txt` names under `G/tests-*/fixtures/` — **63 files**, including 54 complete copied dumps |
   | Generated grid build/audit output remains eligible, including DEX disassembly and strings | **IGNORE** | **CONFIRMED** | `P/grid-test/build/` — **20 files** |
   | Generated journal outputs and corruption/boundary-test payloads remain eligible | **IGNORE** | **CONFIRMED** | Four directory families listed below — **40 files** |
   | Personal Windows paths and the actual head-unit serial remain in reports, manifests, source and test results | **MANUAL REVIEW** | **CONFIRMED** | **143 additional candidates**, after excluding the six overlapping generated files above |
   | Complete decompiled methods/framework excerpts remain outside the existing decompilation holdouts | **MANUAL REVIEW** | **CONFIRMED** | `analysis/HMIPresenter-video-mode-analysis.md`; `G/am-lock-task-mutator-excerpt.txt`; `G/getter-dispatch-excerpt.txt` — **3 files** |
   | A literal development-keystore password is present in build scripts | **MANUAL REVIEW** | **SUPPORTED** | **5 scripts** listed in item 6. Documentation calls it test-only; reuse outside that purpose is **UNKNOWN** |
   | Remaining candidates have no exclusion finding from this audit | **TRACK** | **SUPPORTED** | **353 files**, including the three JNI facades |

   The four generated-journal families are:

   ```text
   G/m5-host-journal/
   P/m6-offline-20261025-130328-474/m5-host-tool-tests/persistence/
   P/m6-offline-20261025-130328-474/m5-host-tool-tests/journal-files/
   P/offline-freeze-20261025-015031-430/m5-journal-probe-data/
   ```

   Identifier counts cover the entire 628-file candidate set and overlap:

   | Category | Count and examples |
   |---|---|
   | Personal Windows username `[REDACTED]ti` | **1,820 occurrences in 96 files**; `NOTES.md:695`, `P/BUILD-VALIDATION-MATRIX-before-decoder02.json:4`, `P/warning-evidence/archive-search.json:3` |
   | Head-unit serial `[REDACTED]56` | **138 content occurrences in 65 files**; **10 filenames** also contain it; **67 files** affected by content or filename. Examples: `P/PROJECT-STATE.json:217`, `:290`; `tools/m5/Test-M5ArmReadinessOffline.ps1:65` |
   | Email `[REDACTED]om` | **1 occurrence**, `P/HONDA-WARNING-DETECTOR-STATIC-ANALYSIS.md:18`; identified there as public vendor signer metadata. **TRACK — SUPPORTED** |
   | VIN-shaped matches | **72 matches**, all numeric test seeds/seed-array values; no confirmed VIN |
   | Strict 15-digit IMEI, Android-ID assignment, colon-form MAC, tested phone-model patterns | **0 matches** |

   The personal-path/serial union is **149 files**, with six already included in IGNORE groups. Device identity checks occur in safety-related source: resolving publication privacy must preserve those checks.

   Wrongly ignored material:

   | Material | Recommendation | Confidence |
   |---|---|---|
   | Both `Notes/*.txt` handoffs | **TRACK** | **SUPPORTED** — project research prose, no code blocks/method bodies or tested personal identifiers; vendor platform/build metadata remains |
   | `Notes/RDX-Android-Auto-Fullscreen-Findings.md` | **MANUAL REVIEW** | **CONFIRMED** — contains a complete method explicitly attributed to APK decompilation |
   | **104 Java files** across clean receiver, qualifier, decoder, M5, M6, USB probe and live-test-02 prototype | **TRACK** | **SUPPORTED** — content supports project authorship |
   | **244 clean fixture/provenance files**, including 120 `.bin` files | **TRACK** | **SUPPORTED** — small protocol fixtures, with documented construction/provenance |
   | Authored manifests, reviewed READMEs and provenance documents in those trees | **TRACK** | **SUPPORTED** |
   | `analysis/current-update-stack/README.md` | **MANUAL REVIEW** | **CONFIRMED** — project-authored report containing the actual serial at line 3 |
   | `analysis/deployment-evidence/README.md`, `analysis/local-software-search/README.md`, `analysis/recovery-root-evidence/README.md`, `analysis/fullscreen-candidate/TEST-PLAN.md` | **TRACK** | **SUPPORTED** — inspected authored reports hidden with their surrounding evidence |
   | Existing declared binary, decompilation, raw-bundle and credential holdouts | **IGNORE** | **SUPPORTED** — retain those boundaries |

   All **96 scripts** and **27 tools files** are candidates. No `scripts/` files were ignored; the five ignored `tools/` files belong to the FFmpeg distribution.

   Suggested `.gitignore` changes, **not applied**:

   ```gitignore
   /analysis/parallel-receiver-initial-query.txt
   /analysis/parallel-aa-receiver/grid-test/build/
   /analysis/parallel-aa-receiver/m5-locktask-guard-*/tests-*/fixtures/*.txt
   /analysis/parallel-aa-receiver/m5-locktask-guard-*/m5-host-journal/
   /analysis/parallel-aa-receiver/m6-offline-*/m5-host-tool-tests/persistence/
   /analysis/parallel-aa-receiver/m6-offline-*/m5-host-tool-tests/journal-files/
   /analysis/parallel-aa-receiver/offline-freeze-*/m5-journal-probe-data/
   ```

   Replace `/Notes/` with:

   ```gitignore
   /Notes/*
   !/Notes/*.txt
   ```

   For each currently excluded directory `clean-receiver`, `api22-tls-qualifier`, `decoder-test`, `m5-permission`, `m6-aoa`, and `usb-probe`, replace its directory exclusion with an immediate-child exclusion, then whitelist authored subtrees. For example:

   ```gitignore
   /analysis/parallel-aa-receiver/clean-receiver/*
   !/analysis/parallel-aa-receiver/clean-receiver/source/
   !/analysis/parallel-aa-receiver/clean-receiver/tests/
   !/analysis/parallel-aa-receiver/clean-receiver/fixtures/
   !/analysis/parallel-aa-receiver/clean-receiver/test-fixtures/
   !/analysis/parallel-aa-receiver/clean-receiver/README.md
   !/analysis/parallel-aa-receiver/clean-receiver/PROVENANCE.md
   !/analysis/parallel-aa-receiver/clean-receiver/SESSION-FIXTURE-PROVENANCE.md
   ```

   Apply the same narrow approach to the other five directories, exposing their `source/`, `tests/`, `host/`, reviewed manifests and documentation. Keep builds, credential assets and native evidence excluded. The ignored live-test-02 prototype needs ancestor exceptions through `live-test-02/prototype/` before its `src/` can be restored.

6. **Primary evidence for findings**

   - **Bulk proprietary query:** `analysis/parallel-receiver-initial-query.txt:1` begins with decompiled Honda source hits; lines 22–25 reproduce implementation signatures/statements. Counted length: **378 lines**.
   - **Copied live fixtures:** `G/tests-07/fixtures/provenance.json:3`–`:10` identifies saved live inputs. `tools/m5/Test-M5ArmReadinessOffline.ps1:15` copies them. Direct comparison produced **54 copied / 54 identical** across nine runs.
   - **Grid output:** `P/grid-test/build/20261023-103955-076/independent-audit-20261023-104059-155/dexdump.txt:2` identifies DEX 035; `:4` identifies the project class. This is generated project disassembly, rather than evidence of a disguised Honda binary.
   - **Journal output:** byte-frequency inspection found two files containing exactly **65,537 zero bytes**; the two byte-bound fixtures each contain **65,489 `x` bytes** within 65,536-byte files.
   - **Embedded decompiled code:** `analysis/HMIPresenter-video-mode-analysis.md:19` explicitly introduces the complete original method; its body begins at `:22`. Framework excerpts begin at `G/am-lock-task-mutator-excerpt.txt:1` and `G/getter-dispatch-excerpt.txt:1`; `G/static-getter-evidence.json:8` records local decompilation provenance.
   - **Password:** `scripts/Build-RdxParallelReceiver.ps1:63`; literal signing arguments at `scripts/Build-RdxApi22Qualifier.ps1:28`, `scripts/Build-RdxBoundedHarness.ps1:34`, `scripts/Build-RdxLive02Synthetic.ps1:29`, and `scripts/Build-RdxM6Aoa.ps1:19`. The value is `[REDACTED]LY`.
   - **Google namespace:** these files are **already candidates**, with no `git check-ignore` match. `analysis/CUSTOM-RECEIVER-ARCHITECTURE.md:41` describes independently written ABI facades; `:68` explains required names. Local/original line counts were **20/92, 73/559, 49/184**, with only **2, 8, 5** identical trimmed lines longer than 24 characters. No tested decompiler artifacts or license headers appeared. This supports independent implementation; it does not establish formal clean-room provenance.
   - **Notes:** research objectives appear at the two `.txt` files’ lines 6–15; the export explicitly omits the device serial at `Notes/2021_Acura_RDX_Fullscreen_Android_Auto_Research_Export.txt:66`. The Markdown file attributes decompilation at `:84` and reproduces the method at `:90`–`:104`.
   - **Ignored source:** `git check-ignore -v` attributes exclusions to `.gitignore:49`–`:53`, `:62`, `:66`–`:67`. Authored behavior is visible in `P/clean-receiver/source/com/rdx/fullscreen/clean/ProtoWire.java:7`, `P/m5-permission/source/com/rdx/fullscreen/m5permission/PermissionMachine.java:7`, and `P/m6-aoa/source/com/rdx/fullscreen/m6aoa/LiveExecutionPolicy.java:2`–`:6`.
   - **Fixtures:** `P/clean-receiver/PROVENANCE.md:29`, `:35`, `:43`; `P/clean-receiver/SESSION-FIXTURE-PROVENANCE.md:3`, `:24` document independently constructed fixtures and their reference context.

7. **Assumptions**

   Counts classify the current candidate snapshot, with IGNORE taking precedence over overlapping privacy findings. Supplemental ignored-file findings are **not** added to the 628-candidate totals. TRACK means suitable under this audit’s checks, rather than proof of unrestricted redistribution rights.

8. **Unresolved uncertainties**

   Arbitrary encoded credentials, undocumented copying, password reuse and redistribution rights remain **UNKNOWN**. Pattern scans cannot prove their absence.

   Git reported Windows “Filename too long” warnings inside the already excluded third-party archive. Its **50,317-file ignored inventory is therefore not guaranteed exhaustive**. The 628-candidate snapshot was fully readable.

9. **Exact diff summary**

   **No diff; no files changed, staged or committed.**

10. **Preservation checks performed**

   Final state remained `main` with **no commits**, no staged entries, and **628/628 candidate hashes unchanged**. `.gitignore`, `PROJECT-RULES.md` and `AGENTS.md` hashes also remained unchanged.

   Frozen artifact hashes matched the rule-file anchors:

   | Artifact | SHA-256 result |
   |---|---|
   | M5 APK | `A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40` — **PASS** |
   | Disabled M6 APK | `D4DAC2DD8B2AFF1FA7B64BFB32D2A5E889854CCEB4B4A9F7AD5AEF89FB28761F` — **PASS** |
   | Receiver DEX, both manifest-listed copies | `2FDBC63F2F9D63B764697D311AF89D460AE6B8E14B0FADABA9C9339F7FE7C235` — **PASS** |
   | API22 qualifier APK | `86350131FFC5CBE5766E523AB03AE07D4C9F5EAD78F0570B68255C9A3999FC1F` — **PASS** |

   Signing `.p12` and `assets/private-test-material/platform.creds` existence was checked without reading their contents. No device access, milestone action, rebuild or repository mutation occurred.