# T240 scope

Task: build the next test for T230's evidenced per-device Off failure. Start from the preserved T230 source, not the restored development baseline.

In scope: SettingsActivity, WirelessProbeService, AaSessionService and pure policy helpers in HondaPhonePolicy; their T240 snapshot only, host checks, package metadata and test instructions. Persist first, notify live services, stop only the disallowed wireless owner, recheck pending bootstrap/handoff admission. No HFP adapter/pairing changes.

Must not change: T230 artifacts/results/logs; frozen PROJECT-RULES anchors; historical milestones/readiness guard; audio, input, navigation, teardown scheduling or unversioned session-end ownership. No live device actions or Git mutation.

Acceptance: current-owner Off / USB-only closes its bootstrap and requests existing AA teardown; another device's setting leaves an allowed owner alone; Wireless-only / Both remain allowed; pending work rechecks current policy. Unknown/ambiguous TCP ownership is refused rather than assigned to the last device by guess. Host checks and API compilation must pass; APK/source identity and host-baseline restoration must be verified if packaging is authorized. Live behavior remains UNKNOWN until the parked test.

Private-material build: existing standard builder is prohibited without the operator's explicit exception; source preparation, host tests, compilation and DEX generation require none of that material. Do not inspect or display private material even if an exception is granted.

Operator exception granted November 9, 2026: permission to build the APK and test file in the existing todo-tests-20261103 suite, responding to the explicit private-material workflow question. Existing local build/sign/package workflow is authorized for T240 only. Its build wrapper, generated Start/Collect shortcuts, package verification and report updates are in scope. No publication or device action authorized.
