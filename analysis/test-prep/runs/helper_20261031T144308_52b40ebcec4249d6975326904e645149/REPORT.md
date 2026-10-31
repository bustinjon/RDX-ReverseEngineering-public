# Profile B — collection result and operator observations

## 1. Files inspected
Existing pinned collection procedure; current session.json, collection.json and saved fresh capture.log. Runtime marker/key summaries saved in input-result.json. Build/comparison provenance remains in page-profile-ab-20261031/REPORT.md.

## 2. Files changed
New Collect-B.ps1/generated collector, Save-BResult.ps1 and current run collection evidence/report. Temporary helper/A11Y/logging/watchdog state cleaned up. No source edit or APK rebuild.

## 3. Commands run
Saved Collect-B.ps1 first returned get-state failure before retrieval because ADB was not connected. User then confirmed connection; the same script completed successfully. Saved Save-BResult.ps1 reads local evidence only. Collection uses the existing explicit-target/time-limited procedure and pulls logs before manual cleanup; no further test prepared.

## 4. Tests run and results
Collection exited0: logs,4 private captures and installed APK saved. Installed APK matched pinned B, E931C7A4368465F52B218C5E973540F26D5C3D438F02751CC3C0B6FB15CEF383. Fresh capture boundary and postchecks verified; original accessibility restored; helper and owned logger/watchdog absent. Local capture hash rechecked against collection.json. No new behavior test or claim of successful repair.

## 5. Findings
Operator reports straight Down still fails to reach the compact Spotify playback row. Sometimes moving straight Right from the starting position reaches controls. A playlist-menu Back transition may once have reached the bottom row, but the operator could not repeat it. Record that Back observation as tentative, not a reproduced result.

The reported sideways access is a useful counterexample to treating the entire row as always unreachable/disabled. Exact starting focus, target control identity, whether it became focused versus activated, and event/frame timing remain UNKNOWN. A's prior result did not establish the same Right-from-identical-focus sequence. Therefore a causal benefit from removing advertised arrows is not established by this observation alone. B still fails the original direct-Down criterion.

## 6. Primary evidence for each finding
collection.json retains the user's same notes, APK/capture hashes,4 captures and cleanup checks. input-result.json records fresh boundary, runtime profile markers with log line references and raw/native key counts. Original capture, private images, initial/final evidence hashes, postchecks.json and manual-cleanup.txt remain local. The first connection failure is retained in collection-failure.txt; successful retry is established by collection.json.

## 7. Assumptions
User confirmed the observations remain the same after correcting the ADB connection. Interpret Right as the reported physical direction, not automatically native DPAD_RIGHT: B's swipe mapping emits MoveEnd123. Do not assume the entire A/B sequence shared identical starting focus or queue state without evidence.

## 8. Unresolved uncertainties
Exact Right/Back route, repeatability, focused control identity, phone focus hierarchy, relation to advertised capabilities, actual phone-side event interpretation and root cause remain UNKNOWN. Native return0 is a local result, not proof of focus movement. StaticAudit PENDING. Further paired review can proceed offline; no device needed for this collection.

## 9. Exact diff summary
Only new pinned collection/report scripts and generated evidence/report; collector substitutions are B run ID/operator result. No guard, production input, native, manifest, APK, frozen artifact or historic A report changes. B source selection remains the reviewed snapshot from its preparation.

## 10. Preservation checks performed
Retrieved installed APK matches pinned B; initial/final evidence/private image hashes saved; capture hash locally reverified; original A11Y and owned-process cleanup verified. No key inspection, frozen rebuild, Git mutation, guard bypass, milestone advancement or external publication. SAFE TO DISCONNECT was given only after successful retrieval/cleanup. No automatic re-arm or new installation.
