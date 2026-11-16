# Using this on another car

**Short version: you can't install Hackura on another car today, and there's no guarantee it will ever work on a given one.** This page is honest about why, and what adapting it would actually involve.

## Why it isn't plug-and-play

Hackura was built and tuned for **one specific head unit** — a particular Honda/Acura wide-screen unit on a particular software version. The parts that make Android Auto go full-screen, authenticate, and route audio depend on details that differ from car to car: the exact screen geometry, the vehicle's own app and service layout, how it handles a USB accessory, and material that lives inside that car. Change the model year or the firmware and those details change too.

There is also no installer yet (see the [README](README.md)). The long-term plan is a setup tool each owner runs once on their **own** car to build their own copy — because an app that already contained another car's material couldn't be shared. That tool isn't released.

So "porting" here does not mean "download and flash." It means a developer studying their own vehicle and carefully rebuilding the pieces for it.

## If you're a developer adapting the approach

Start with offline study of the target car — not by installing this project's historical APK or running its live scripts.

1. **Record the target precisely:** car model/year, head-unit hardware, Android/API level, firmware build, and display/input hardware. Decide what you actually want to change.
2. **Gather your own authorized, offline evidence:** package/service layout, UI behavior, USB accessory handling, display geometry, native ABI, and the input/audio interfaces. Keep identifiers and raw captures private.
3. **Compare against the failure layers** in [CURRENT-FINDINGS.md](CURRENT-FINDINGS.md). The most reusable ideas are the input-event model, the PCM/audio-focus accounting, the screen-geometry model, and the independent cleanup approach. Identity strings, binder transaction IDs, package names, service bindings, and protocol prerequisites are all target-specific.
4. **Re-qualify every low-level call** against that target's own framework before using it. A read-only system call that worked on the original firmware is not valid by analogy on another — confirm it on the actual target.
5. **Write an explicit per-car configuration and a cleanup/restore plan.** The published placeholder serials deliberately do not authorize any real car. Don't add a bypass or remove a safety check just to make a script proceed.
6. **Run the host tests, then stop.** Only consider a parked, bounded live test after the owner understands the exact steps and authorizes that specific test. Preserve evidence and verify the car is restored before doing anything else.

## What you still have to supply yourself

The public repository does **not** include the receiver's protocol credentials or the proprietary native library, and it never will. An offline test passing is not the same as the car working. Do not substitute a copied platform certificate or private key, a factory-app replacement, a force-stop loop, or a disabled safety check for actually understanding the target. Never use another person's private material.

The latest build and its remaining open questions are in [LATEST-TEST-PLAN.md](LATEST-TEST-PLAN.md); its source is available for review. Run both host-test scripts listed in the [README](README.md) before adapting anything.
