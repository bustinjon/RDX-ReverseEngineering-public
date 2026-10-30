# Offline harness build validation — 2026-10-23

No new vehicle result. Readiness below is static readiness for the specified bounded experiment, not install authorization. M4 is the next session; grid is separate; decoder is not ready for decoding.

| Artifact | Package/version | APK | SHA256 | API/signature/alignment/audit | Ready for car? |
|---|---|---|---|---|---|
| usb-probe | com.rdx.fullscreen.usbprobe / 0.1.0-m4-passive | [usb-probe/build/20261023-081948-336/rdx-usb-probe-0.1.0-development.apk](usb-probe/build/20261023-081948-336/rdx-usb-probe-0.1.0-development.apk) | BAD93C688F7019E4205DC86EF34E6078B695623DB85770C789F29B0A3CFF4148 | min21 target22; v1/zipalign/JADX/DEXDUMP/static PASS | True: Static PASS; only separately authorized bounded scope, runtime untested |
| grid-test | com.rdx.fullscreen.gridtest / 0.1.0-grid | [grid-test/build/20261023-103955-076/rdx-grid-test-0.1.0-development.apk](grid-test/build/20261023-103955-076/rdx-grid-test-0.1.0-development.apk) | 24843A11B417B20F37D33C9FB269007A9F69158E39D27882E67CEAFBF33B7214 | min21 target22; v1/zipalign/JADX/DEXDUMP/static PASS | True: Static PASS; only separately authorized bounded scope, runtime untested |
| decoder-test | com.rdx.fullscreen.decodertest / 0.1.0-decoder | [decoder-test/build/20261023-104441-074/rdx-decoder-test-0.1.0-development.apk](decoder-test/build/20261023-104441-074/rdx-decoder-test-0.1.0-development.apk) | A9509D00E312725F0062292950F513FF44BD9D5AB3C38C4B9A6B864397504B05 | min21 target22; v1/zipalign/JADX/DEXDUMP/static PASS | False: Static PASS but six clip assets missing; not ready for decoding |

All three: independently signed with development signer SHA256 `c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831`; no shared UID, requested permissions, intent filters or native libraries. Java-only APKs are suitable in principle for ARMv7 API22; runtime remains untested.

M4: one headless exported Service in :probe; only inventory/hasPermission/descriptor USB APIs. Grid: one Activity/SurfaceView and drawing APIs, no USB or codec. Decoder: one Activity; explicit TI MediaCodec/MediaExtractor/Surface, no USB or software fallback. No Honda/protocol classes or credentials.

M5: source/design only under m5-permission; no APK/hash/signature/alignment/decompilation claim and NOT READY. M4 PASS and separate authorization/build/audit required. M6: documentation only.

Machine-readable JSON contains absolute source/APK/audit paths, full components, API inventories, signer, readiness reasons and hashes. See each latest-audit directory for final-artifact evidence and manual-review.json. Earlier failed/incomplete build/decompilation attempts are preserved and must not be used instead of this matrix.

Source compilation used installed android-33.jar and Java7 bytecode/D8 min21; APIs were reviewed for API22 compatibility. Compile SDK is not runtime API proof. No upstream implementation or proprietary native library was copied into these harnesses.
