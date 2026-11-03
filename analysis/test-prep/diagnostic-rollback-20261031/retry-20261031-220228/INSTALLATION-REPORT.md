# Exact baseline installed — 2026-10-31

1. **Files inspected:** selected D1A29… candidate, generated installer/readiness and live baseline-install metadata.
2. **Files changed:** installed exact previous APK, stopped only own package and saved comparison evidence. No source/build change this turn.
3. **Commands run:** Install-BaselineOnly.ps1, with existing target/firmware/Home checks, ordinary APK replacement, installed-file pull/hash and own-service/settings verification. No helper start or accessibility enable.
4. **Tests/results:** installed hash matches D1A29B34812B2C3188C57C840DB1DE4F44E1362FF8BD8E3D9A52B1317EDABCE4; helper absent; accessibility unchanged; post-install Home check passes.
5. **Findings:** baseline ready for manual Diagnostics comparison; no AA session armed or phone handoff.
6. **Primary evidence:** baseline-install.json, artifact-plan.json, install-output.txt, installed-baseline.apk, helper-after.txt, processes-after.txt, home-after-install.json and commands.jsonl.
7. **Assumptions:** current explicit ADB/Home confirmation authorizes the requested rollback installation and passive comparison evidence.
8. **Uncertainties:** manual shortcut outcome pending. Reinstallation may reset transient state, so any restoration would not isolate a particular feature.
9. **Exact diff summary:** device package replacement plus own stopped state and local evidence only; no OEM setting reset, data clear or app rearm.
10. **Preservation:** original APKs/newer source retained; no frozen rebuild, credential entry inspection, guard bypass, milestone/Git publication. Passive physical input capture is bounded and does not inject keys.
