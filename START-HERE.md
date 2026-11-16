# Start here

New to this repo? Read the **[README](README.md)** first — it explains what Hackura is, what it can and can't do, and that there is **no public installer yet** (the project is in compatibility testing).

This page is the map of everything else.

## If you just want to understand the project

- **[README.md](README.md)** — what Hackura does, in plain language, with its full list of capabilities.
- **[What works today](CURRENT-FINDINGS.md)** — the features that have actually been car-tested, each with its limits.
- **[Latest build and test plan](LATEST-TEST-PLAN.md)** — the current build and the open questions.

## If you're a developer or researcher

This repository is a **sanitized research snapshot** — source, findings, and the reasoning behind each change. It is not a packaged app, and it does **not** contain the working receiver, any installer, vendor libraries, or protocol credentials.

- **[Using this on another car](PORTING.md)** — an honest rundown of what adapting it involves.
- **The receiver source** — `analysis/parallel-aa-receiver/usb-helper/source/` (effective sources, override shared files by name) and `analysis/parallel-aa-receiver/src/` (shared).
- **The research write-ups** — under `analysis/`, including the review trail behind each change.
- **[PUBLIC-MANIFEST.json](PUBLIC-MANIFEST.json)** — SHA-256 of every exported file.

Portable host tests (JDK 17, no car needed):

```powershell
./tools/car-test/Test-PublicInputPcm.ps1
./tools/car-test/Test-PublicReceiverChanges.ps1
```

## The one thing you can actually run

- **[Diagnostic app](diagnostic-app/README.md)** — a small, separate, credential-free Android app you can build, sign with your own key, and install. It only reports a screen's display geometry, raw input, and a short test tone. It is **not** an Android Auto receiver and does not connect to a phone — it's a way to read what a given head unit does. Build it with your own signing identity and keep your password and key out of chat, logs, and Git.

## Ground rules if you experiment on your own car

- Nothing here is a general installer. The published serial numbers are placeholders, not working settings.
- Don't weaken a car's identity or safety checks to make a script run on a different vehicle.
- Don't run ADB, install apps, or change car/phone settings until you understand the exact step. Plan parked, bounded tests, collect logs, and confirm the car is back to normal before you finish.
- Never reuse someone else's private keys or credentials.
