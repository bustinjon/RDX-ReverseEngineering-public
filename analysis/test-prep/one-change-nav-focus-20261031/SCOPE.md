# One-change test preparation

Task: prepare only the existing Maps navigation-focus correction against the restored D1A29 baseline. Reuse the already built 21037 APK; do not rebuild.

Production scope: only GalReceiver.java, restored from its preserved, hash-verified corrected copy. All other 26 Java inputs must remain baseline-identical. No media-key, volume, touchpad, sensor, manifest or native change.

Acceptance: exactly one recorded source difference; current effective inventory matches all 27 candidate inputs; existing APK hashes match; ten callback tests pass. Preserve the rollback source, archived newer sources, 18 artifacts and six guard/runner files. Do not alter historical reports, run device commands, arm anything, publish Git changes, read credentials or advance milestones.

Live installation/testing belongs to the authorized operator. Current AGENTS.md prohibits this agent from using ADB or touching devices.
