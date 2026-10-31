# Future Down-only probe — not yet run

Candidate v6h-down-motion-only-a, SHA-256 `28659795FC5228988FB56E0D006328DE0D13F65421560C27DFCEB28CDDF8367A`. Compared with B, only raw146's extra key pulse is suppressed; pad motion and other controls/profile settings remain unchanged.

## Before connection

Use this directory's Prepare-LiveTest.ps1, **not** the old A/B scripts/source selector. No source switch is required. The existing CurrentSource runner verifies the pinned APK against all27 current inputs. B-zone OFF; capture armed once. UI/USB-menu automation remains unqualified and is not silently added. No live authorization follows from this file alone.

## Full instructions at the later real READY cue

1. Vehicle parked, phone unplugged, laptop on head-unit ADB. Accept the operator's Home confirmation without extra Home polls; retain required readiness guard. Confirm prior stock Honda AA preference for this phone remains disabled.
2. After installation/A11Y/logging/watchdog/capture checks, say **READY — plug in phone** with measured remaining time. The watchdog is180seconds from preparation, not after phone connection.
3. Switch USB to phone mode, return normally to Honda Home, plug in phone and let prompts auto-accept. Keep audio/Bluetooth/app/queue settings unchanged.
4. **TEST NOW — large left pad only.** Check Up/Left/Right, Select and Back. If startup Right can enter Spotify's bottom row, enter it, move Up, then try one ordinary Down and one larger Down separately. Also try title->Down directly. Report which button gains focus, not just whether movement happened.
5. Check Down within Spotify's playlist and Maps in the right third. If either loses Down or basic controls regress, stop and reconnect for logs. If time permits, leave/return once and repeat the Spotify row check. Optional operator video with a stated action order would help resolve transient focus paths; no new capture application is needed or selected.
6. Reconnect ADB for logs/private captures. Pull first, verify A11Y/owned-process cleanup, then say **SAFE TO DISCONNECT**. Do not stack another code/settings change into this run.

## Evidence criteria

- Installed APK hash matches2865…8367A; runtime key list remains `[4,23,92,93,122,123]`, pad nav=true abs=false, B-zone enabled=false.
- Raw146 events and active pad DOWN/MOVE/UP must appear, with **no native93 pulse from those gestures and no fallback20**. Other functioning controls/keys plus live video distinguish suppression from an inactive session. Direct raw93 is still supported but is outside this main-pad probe.
- Expect Up152->92, Left148->122, Right150->123, Select23 and Back4 unchanged. Actual native key counts/consumption to be analyzed against operator sequence.
- Down does not call the existing key-consumer screenshot scheduler, so sparse Down-triggered private images are expected. Do not infer success/failure from screenshot count alone.
- Reliable row entry with ordinary Down and preserved controls would implicate the extra delivery under this profile; repeatability still needs confirmation. If nothing changes, the pulse alone is insufficient. If list/Maps Down fails, do not ship blanket suppression.

No Gemini, audio, microphone, coordinate, key-declaration or other input change in this comparison.
