# Maps navigation-focus candidate

Task: implement the confirmed always-native navigation-focus reply defect documented in `analysis/agent-reviews/maps-route-20261031/REPORT.md`, test it offline, and build a separate APK for a future controlled route comparison.

Production edit scope: only `analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/GalReceiver.java`, specifically navigationFocusCallback. Honor valid stock values1/2, log numeric request/reply/rejection, reject unknown values without native forwarding. Keep the JNI method name/descriptor unchanged.

Additional scope: this candidate's tests, build provenance, preparation scripts and report under this directory; normal generated builder outputs and latest-build pointer. Reuse the established untimed workflow for a future test, retaining every readiness check. No live action is authorized by this scope file.

Must not change: input/Select/Back/Spotify handling; audio, sensors, video/overlay, USB transport; shared runner/readiness guard; prior APKs/reports and frozen artifacts. No key inspection, Git mutation or device command.

Acceptance: valid request2 reaches the native boundary as2; valid1 as1; unknown values do not reach it; callback logging is present; installed candidate DEX is verified; only the intended recorded Java input changes; non-DEX APK payload remains identical; prior/frozen artifact hashes remain intact. Hardware causality/stability stays UNKNOWN until the future route comparison.
