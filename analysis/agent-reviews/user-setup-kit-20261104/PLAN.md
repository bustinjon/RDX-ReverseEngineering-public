# End-user setup kit — design draft, 2026-11-04 (Claude)

Goal (user, 2026-11-04): "a setup file that end users can ADB to their cars, we pull whatever we need and we build the package for them." Draft for review; nothing built yet.

## Flow

1. **Collect** (`Collect-CarProfile.cmd`, read-only ADB, laptop + car, phone unplugged). It gathers:
   - Identity and compatibility: build fingerprint, display ID, API level, model and firmware strings, head-unit serial (kept local).
   - Geometry: physical size/density, overscan, stable/restricted rects, status-bar window and type (`dumpsys window`, `dumpsys display`).
   - Input: device list with key layouts (`getevent -p`, `dumpsys input`), so touchpad size and console key codes/scan codes/source are known.
   - Policy: Home and B-zone handling, the `lcd_service` binder, the location provider list, broadcast permissions (the Check-Signals logic, generalised).
   - Packages: stock AA package/version/path, malicious detector presence, launcher package, accessibility state.
   - Writes `car-profile.json` plus a hash list. **It never installs, changes settings or reads app-private data.**
2. **Assess** (offline, on the user's PC). It compares `car-profile.json` with a compatibility table of known-good firmware families (this RDX, plus the friend's TLX once profiled) and prints a plain report:
   - "Supported", "Supported with differences: …" or "Not supported because …".
   - Which features are expected to work (camera, calls, mic, track buttons, day/night, GPS) and which are blocked by OEM permissions on that firmware.
3. **Build** (offline, user's PC). It generates the receiver configuration from the profile:
   - Touchpad domain, video geometry transform, key mapping, the phone serial the user chooses, and feature flags.
   - Builds the APK locally.
   - **Credentials and the native library come from the user's own car**: the kit pulls the stock AA APK the car already has and extracts what is needed on the user's machine. We never distribute them; this matches the public repo's existing rule.
4. **Install/use** (`Launch-RDX.cmd`, the same launcher as today). The launcher is generated from the profile, so the hash pins, serials and paths are the user's own. It keeps the readiness checks, the Diagnostics checkpoint, and Collect/Recover.
5. **Optional persistent mode** (after T30 is designed). It leaves the helper and accessibility enabled across reboots, with an explicit uninstall.

## Hard rules carried over

- Read-only collection; any car change happens only in the Install step, with the user's explicit START.
- No bypass of readiness guards; no detector tampering (the T26 Dismiss tap only); unplugging always ends a session.
- Never publish a user's profile, serials or extracted material; only the anonymised compatibility table is shared.
- Personal identifiers stay local.

## Feature switches the build offers

| Feature | Default | Note |
|---|---|---|
| Real driving status (speed/gear → restrictions) | off (report parked) | Our car keeps parked mode by user choice. Speed/gear broadcasts were permission-protected on this firmware; the profile decides whether it is even possible |
| Car GPS (T25) | on if a `gps` provider exists | |
| Day/night (T13) | on if `lcd_service` exists | |
| Volume display (T24) | on if Android master-volume broadcasts follow the knob | |
| Console track buttons (T10) | on if seek keys are seen in the input profile | |

## Open questions for the user

1. Who runs Build: the user (needs JDK/SDK, which we can bundle like the launcher bundles PowerShell), or you, from their profile? The second needs their extracted material on your machine, which the rules above avoid.
2. Which cars to profile next (the friend's TLX is the obvious second).
3. Distribution channel for the kit (public repo release vs private).
