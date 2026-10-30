# Applying the findings to another car

Begin with offline comparison, not by installing this project's historical APK or running its live scripts.

1. Record the friend's exact car model/year, head-unit hardware, Android/API level, firmware build and display/input hardware. Establish what they actually want to change.
2. Gather their own authorized offline evidence: package/service layout, UI state behavior, USB accessory handling, display geometry, native ABI and input/audio interfaces. Keep their identifiers and raw captures private.
3. Compare with the failure layers in CURRENT-FINDINGS.md. The most reusable pieces are the event distinction, PCM/focus accounting, geometry model and independent cleanup approach. Identity strings, binder transaction IDs, package names, service bindings and protocol prerequisites are target-specific.
4. Qualify any read-only binder getter against that target's own framework/services code before invoking it. Getter 217 was qualified only for the original recorded firmware. Do not reuse a transaction number by analogy.
5. Build an explicit target configuration and preservation/cleanup plan. The published dummy serials deliberately do not authorize a real target. Do not add a bypass or remove readiness checks to make a script proceed.
6. Run applicable host tests. Only propose a parked, bounded live test after the owner understands the exact steps and authorizes that specific test. Preserve evidence and verify restoration before further changes.

For the original v5 test procedure, see [NEXT-TEST.md](analysis/test-prep/pad-select-20261030/NEXT-TEST.md). It includes the OnePlus Settings → Bluetooth → car details → Media audio isolation step. This is a historical procedure for the original setup, not a general installation guide.

Do not substitute a copied platform certificate/private key, factory app replacement, persistent force-stop loop or disabled readiness guard for understanding the target. No credentials, vendor native libraries or installable APK are provided in this public snapshot.
