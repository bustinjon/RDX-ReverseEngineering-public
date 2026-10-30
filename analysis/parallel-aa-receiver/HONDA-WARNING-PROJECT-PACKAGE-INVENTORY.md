# RDX project package inventory — phone-free live check, 2026-10-25

**No package was installed/uninstalled or deleted during this phone-free phase.** M5 was installed under the preceding authorization and remains unarmed. All other project package identities are absent.

Authority:132 existing analysis APK paths /86 distinct hashes were inspected with aapt manifest badging, then cross-checked with project source manifests and previous live reports. They contain seven project package identities and the factory AA identity. Names below are manifest-confirmed; they were not guessed solely from a prefix. The remaining APKs outside analysis inspected by filename are saved factory acquisitions, not additional research package builds. Patched/copied factory AA artifacts retain Honda's package name and are **never cleanup targets**.

Full per-APK package/version/SHA256/purpose inventory: [CSV](warning-phonefree-20261025-190517/project-package-history/apk-manifest-inventory.csv), [JSON](warning-phonefree-20261025-190517/project-package-history/apk-manifest-inventory.json). Prior vehicle baseline before fresh M5 is preserved in `m5-live-retry-20261025-185128`; every one of these seven names was absent then.

The normal package list has116 entries before fresh M5 and117 now. The sole difference is M5's new installed code path; [exact comparison](warning-phonefree-20261025-190517/preinstall-current-package-difference.json). No other net package removal or addition appears in that comparison.

|Package|Purpose/history|Current normal list /-u /path /dumpsys|Status/action|
|---|---|---|---|
|com.rdx.fullscreen.projection|M0/M1/M2 synthetic ordinary-app prototype; live01/02 reports establish prior installation|Absent from both lists; empty exact path/dump; no process/service|ABSENT /none|
|com.rdx.fullscreen.usbprobe|M4 passive inventory; prior live PASS, normally uninstalled|Absent from both lists; empty exact path/dump; no process/service|ABSENT /none|
|com.rdx.fullscreen.m5permission|Prior timing-INCONCLUSIVE test uninstalled; today's exact frozen retry installed|Installed UID10049, code3/version0.2.0-m5-single-port-300s, /data/app/com.rdx.fullscreen.m5permission-1/base.apk|INSTALLED /retain; UNARMED|
|com.rdx.fullscreen.gridtest|Prepared visual grid test; no prior live-install proof in reviewed reports|Absent from both lists; empty exact path/dump; no process/service|ABSENT /none|
|com.rdx.fullscreen.decodertest|Prepared decoder artifact; no decoder run authorized here|Absent from both lists; empty exact path/dump; no process/service|ABSENT /none|
|com.rdx.fullscreen.api22tls|Emulator-only offline qualifier; not a vehicle artifact|Absent from both lists; empty exact path/dump; no process/service|ABSENT /none|
|com.rdx.fullscreen.m6aoa|Frozen disabled offline M6; never authorized on vehicle|Absent from both lists; empty exact path/dump; no process/service|ABSENT /none|

The receiver's M7 foundation is pure/offline code, not a separately installed M7 package. No receiver/M7 process/service or unexpected additional project package was found. A cached M5 process can remain after LIST_RESULTS exits; that is not an armed test. Active M5 service is absent; saved-run list is empty.

User inventory reports only user0 (Owner). `pm list packages -3 -f` and `-u -3 -f` show only today's M5. Full normal `dumpsys package` exposes only M5 among the seven project identities; no UNINSTALLED-BUT-STATE-VISIBLE entry or retained UID mapping for the other names was found through those interfaces. No `/data/system` files were read or edited. `/data/app` directory listing itself is denied; normal PackageManager queries and M5's own resolved code path were used instead. That access limitation does not imply package residue.

## Staging checks — no deletion

`/data/local/tmp` root listing showed vendor/cache directories, not APK files. Metadata for DR/logs/logs_carplay/pk-lock is access-denied; these were not traversed or assumed to be ours. `/sdcard/Download` is empty in its normal listing; `/sdcard/Android/data` shows only the media provider entry. `/sdcard` root has old screenshot/XML/text evidence, not APKs; evidence files are not installable residue and are left untouched.

Five exact upload paths reconstructed from historical command metadata were checked individually and are absent:

- /data/local/tmp/rdx-parallel-aa-0.1.0-development.apk
- /data/local/tmp/rdx-parallel-aa-0.1.1-live02-synthetic.apk
- /data/local/tmp/rdx-usb-probe-0.1.1-m4-single-port-development.apk
- /data/local/tmp/rdx-usb-probe-0.1.2-m4-single-port-300s-development.apk
- /data/local/tmp/rdx-m5-permission-0.1.1-m5-single-port-180s-development.apk

[Exact results](warning-phonefree-20261025-190517/staging-path-results.json), [package classification](warning-phonefree-20261025-190517/project-package-status.json). No stale project APK was found in the inspected accessible locations; this is not a whole-filesystem absence claim. The detector code does not scan those paths in any event.
