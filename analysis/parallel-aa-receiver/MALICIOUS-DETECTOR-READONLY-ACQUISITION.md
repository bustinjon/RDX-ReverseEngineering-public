> 2026-10-25 planning refresh: next car priority is M5 ONLY. This read-only APK/metadata acquisition requires separate explicit authorization and is not chained into M5. Existing path-resolution/pull/hash/signer commands below remain future-only; no detector bypass, suppression, deletion or private-state modification is prepared.

# Future MaliciousDetector collection — separate authorization, NOT part of M4

No command here was executed. Do not add this acquisition to the next M4 session unless the user separately authorizes it. No bypass, warning suppression, whitelist edit, package mutation, private-data access or service invocation.

Target package com.honda.maliciousdetector. Historical active path `/system/app/MaliciousDetector/MaliciousDetector.apk`, version5.1.1-168/code22. Resolve current path before trusting the historical one. Use only the independently verified vehicle serial; never select an unrelated Android device.

Future commands, from project root:

[Code block omitted from public report; see authored source where available.]

Inspect pm-path.txt. **Only if it confirms that exact path**:

[Code block omitted from public report; see authored source where available.]

If pm path differs or lists splits, stop and document/resolve the actual existing readable package paths; do not substitute an installation/update action. Pull is read-only to the head unit; Get-FileHash and signer inspection are local. Keep original raw outputs and exit/error evidence (use bounded capture tooling for live command records). No log clearing. Do not trigger an install/reboot/warning solely for collection.

Offline after collection: decompile manifest/resources/DEX, identify exact dialog text/resource/class, package/boot receiver actions, authorization predicate and certificate/package whitelist, state storage/uninstall behavior, Dismiss acknowledgment and boot-time display logic. Signer identity alone is not the authorization predicate. User-observed warning after verified uninstall is evidence to explain, not a reason to delete files or reset detector data.
