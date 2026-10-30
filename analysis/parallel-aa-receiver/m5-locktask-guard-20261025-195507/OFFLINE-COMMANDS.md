# Reproduction commands — host only

This records substantive reproducible analysis/test commands, not a fabricated ADB transcript. There were **zero ADB invocations**. Shell reads, patch edits and development test iterations produced the files in the final inventory.

Run from the project root with locally installed PowerShell7/JDK17; substitute a new output directory for each test run. Do not invoke INSTALL/ARM or any ADB command for offline validation.

[Code block omitted from public report; see authored source where available.]

Final test outputs: `tests-final/summary.json`, `tests-final-repeat/summary.json`, matching deterministic-cases JSON. An explicit missing-proof ARM refusal was exercised by the host suite, which checks absence of command records; that execution terminated before any ADB process. Checker refusal cases use a nonexistent executable and stop before process creation. Raw result/command arrays and schema checks are retained.

Static extraction used this local executable and classpath:

[Code block omitted from public report; see authored source where available.]

The same local CLI decompiled `com.android.commands.am.Am` from saved `am.jar` to `am-jadx`. Logs, getter dispatch and mutating am-command excerpts are retained. Pinned JAR hashes were locally verified; no target framework was loaded or executed.

Unchanged pure M5 regression:

[Code block omitted from public report; see authored source where available.]

This does not compile Android Service glue or build an APK. `m5-host-javac.txt` and `m5-host-tests-final.txt` retain actual output. Existing56 deterministic/2400000 property assertions passed. The target DEX and all frozen APKs are verified by hash, not rebuilt. Schema validation used local PowerShell `Test-Json -SchemaFile tools/m5/m5-arm-readiness.schema.json`; there are no schema remote references/downloads.
