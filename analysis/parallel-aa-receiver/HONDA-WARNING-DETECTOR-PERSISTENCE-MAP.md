# Detector persistence map — read-only, 2026-10-25

Source of truth: [live-acquired build14 analysis](HONDA-WARNING-DETECTOR-STATIC-ANALYSIS.md). No private detector files were read or modified; the path below is derived from code and standard framework naming.

[Code block omitted from public report; see authored source where available.]

|Event/stage|Classification/storage/action|Natural clearing observed in code|
|---|---|---|
|Specific runtime scan detects ordinary app|Write booleantrue via default private SharedPreferences.apply(); no direct warning in this branch|None|
|Specific lookup fails|NameNotFound returns detected=true; same history setter; package list is not populated on this failure|None|
|First boot scan detects an app|Show warning with Remove all, then write historytrue|None|
|Later boot, no apps detected, historytrue|Show same message with Dismiss only|None|
|Later boot, apps detected, historytrue|Show message with Dismiss and Remove all|None|
|Dismiss|Current HondaDialog default handler closes dialog; no detector callback registered|No preference write/reset|
|Normal uninstall|Application disappears from fresh installed-app scan; detector has no removal handler|Does not reset historical bit|
|Remove all button|Detector iterates its in-memory package list and invokes normal deletion mechanism through reflection|Does not reset historical bit; NOT EXECUTED|
|Process restart|In-memory package names lost; default preferences reloaded by UserLocalRepository|Historical boolean retained|
|Boot|Fresh installed-app scan plus saved boolean condition|History alone is sufficient for warning|

Storage:

- Mechanism: PreferenceManager.getDefaultSharedPreferences(context), MODE_PRIVATE.
- Preference name: `com.honda.maliciousdetector_preferences`.
- Derived conventional file: `/data/data/com.honda.maliciousdetector/shared_prefs/com.honda.maliciousdetector_preferences.xml`.
- Key: `DID_USER_INSTALL_3RD_APP_KEY`, boolean, defaultfalse, only write in APK istrue.
- No persistent package-name table/list/database or additional latch key found in this APK.
- The file/value was **not acquired**. Do not treat the derived path as a disk observation or a request to access/change it.

Naming references: saved `decompiled/Framework/sources/android/preference/PreferenceManager.java`159–168 and `android/app/ContextImpl.java`849–886. The detector's actual default-preference call and true-only setter are independently confirmed in its live-acquired DEX. Framework naming is supporting static evidence, not a new vehicle private-data read.

Current event evidence:18:55:47.318 runtime-scan M5 log; BOOT_COMPLETED service intent captured. An eight-row [static branch table](warning-phonefree-20261025-190517/detector-branch-table.csv) covers runtime/boot ×history ×current detection. It models DEX branches, not measured preference contents.

**Consequence:** normal removal of our remaining M5 can remove the current package but need not remove the recurring historical warning. No permitted package/file cleanup resets this detector bit. No reset/bypass procedure is proposed.
