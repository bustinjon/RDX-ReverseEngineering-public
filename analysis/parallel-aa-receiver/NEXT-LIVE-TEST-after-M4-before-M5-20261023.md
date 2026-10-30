# Next live test — M4 completed, STOP before M5

Updated2026-10-23 after actual single-port M4 session. **M4 PASS; M4 package cleanly uninstalled. No M5 or later milestone authorized or executed.** The pre-session M4 operator plan is preserved in NEXT-LIVE-TEST-before-M4-PASS-20261023.md.

## Observed result

[Full results](M4-LIVE-TEST-RESULTS.md), [evidence](m4-single-port-20261023-170305-676/). UID10049/untrusted_app directly saw18D1:2D01 at two successive USB paths,2 interfaces/four bulk endpoints,hasPermission=false. Honda/system logs separately show22D9:2769→18D1:2D01→22D9:2765→18D1:2D01; brief normal identities were not caught by the1sec app samples. One timing repeat was explicitly requested by the user; the first120sec run ended26.49sec before phone attach, and the longer300sec bound captured the phone.

Own result file/Service survived ADB disconnection. Retrieve app external evidence through /sdcard alias on this unit rather than assuming shell can resolve the process-view /storage/emulated/0 path. Cleanup succeeded; app code/data/process/external files absent. Factory AA package dump/APK SHA/signer and WM geometry unchanged; no reboot. Honda private data equality is not claimed because normal factory phone sessions occurred. OEM installation detector log recorded, not altered.

## Recommended next step — not execution authorization

First perform OFFLINE review of a **single-port-compatible M5 permission-only** workflow. The currently built M5 has a45sec request window and exact device identity/path gates; phone and ADB cannot coexist on this port, and paths can change during Honda re-enumeration. Do not blindly reuse a stale /dev/bus/usb path or launch existing M5 immediately. Resolve timing, exact selection, permission-dialog observation and retrievable evidence while keeping one-shot/no-open/no-transfer behavior.

Only after that review and separate user authorization should M5 request normal UsbManager permission. M4 does not prove grant/openability/ownership. No suppression of stock AA, USB force claim/reset, root, GAL/native loading, AA protocol/TLS, decoder/fullscreen/TTI or display/settings changes are authorized. Stop vehicle work here.
