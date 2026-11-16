# Hackura — full-screen Android Auto for Honda & Acura

**Status: in compatibility testing — there is no public installer yet.** You can't download and install Hackura today. This page explains what it does, what it can and can't do, and where the project stands. Last updated 2026-11-16. Not affiliated with Honda, Acura, or Google.

---

## What Hackura does

Many Honda and Acura vehicles (roughly 2019–2021, Android 5.1 head units) show Android Auto in a small box in the middle of a wide screen, with black bars down the sides. Hackura is an experimental app that changes that. On the one car it's been built for so far, it can:

- **Fill the whole widescreen.** Android Auto uses the entire display instead of the small centered box.
- **Run Android Auto wirelessly.** The head unit hosts the connection over Wi-Fi, so your phone can stay in your pocket. (Wired over USB works too.)
- **Play audio in sync.** Media starts aligned with the screen — no lingering delay — and keeps playing cleanly.
- **Stay up reliably.** Recent fixes stopped a start-up restart loop, so the session holds steady.
- **Use the car's controls.** The touchpad moves the cursor and the physical selector and Back button work.
- **Follow day/night.** The map switches with the car's day/night mode.
- **Reconnect on its own.** Unplug and replug (or reconnect wirelessly) and it comes back — no laptop needed.
- **Show the volume level** on screen as you adjust it.

### Works right alongside your car's features

Turning on Hackura doesn't take over the car. These keep working normally:

- Reverse camera
- Bluetooth phone calls, including answering and the steering-wheel call buttons
- Google Maps routes and turn-by-turn
- Navigation voice prompts (music ducks for them, then comes back)
- Google Assistant — the on-screen mic and "Hey Google," even with the fan on high
- The console **Next / Previous** track buttons

### What it can't do (locked by the carmaker)

Some things are reserved by the vehicle's own software and need system-level permissions a normal app isn't allowed to have. Hackura **cannot**:

- Use the **steering-wheel** Next/Previous or talk button
- Send the phone **vehicle speed or gear** information
- Switch the car's built-in microphone mode

These aren't bugs — they're boundaries the car enforces, and Hackura deliberately stays inside them.

---

## Where the project stands

Hackura is **experimental research**, built and tested on a single owner's own car. It is **not** a finished product, and there is **no installer to download yet**, for two honest reasons:

1. **It's still being tested.** Every change is flashed to a real car and checked one at a time. The newest build is waiting on its next car test, and compatibility across different model years and firmware versions hasn't been worked out yet.
2. **It can't ship as one app for everyone.** Making Android Auto run this way depends on material that lives inside *your own car*. An app that already contained that material couldn't be handed out. The plan is a **setup tool** each owner runs once to build their own copy from their own vehicle — and that tool isn't released yet either.

When something is ready for wider testing, it will be announced here.

## Can I try it on my car?

Not yet, and maybe not ever on your exact car — that's what the current compatibility-testing phase is figuring out. It targets Honda/Acura units with a particular wide screen and software generation, and even within that group small differences between model years can change the result. There's nothing to install today. See [Using this on another car](PORTING.md) for an honest rundown of what's realistic.

---

## For developers and researchers

This repository is a **sanitized research snapshot** — the source, findings, and the reasoning behind each change — not a packaged app. If you want the technical story:

- **[START-HERE.md](START-HERE.md)** — how the repo is laid out and where to look first.
- **[What works today](CURRENT-FINDINGS.md)** — the tested results, with the limits of each.
- **[Latest build and test plan](LATEST-TEST-PLAN.md)** — the current build and what's still open.
- **[Using this on another car](PORTING.md)** — adapting the approach to a different vehicle.
- **[Diagnostic app](diagnostic-app/README.md)** — a small, separate, credential-free app you *can* build and run; it only checks a screen's display/input/audio behavior and is **not** an Android Auto receiver.
- **[PUBLIC-MANIFEST.json](PUBLIC-MANIFEST.json)** — SHA-256 list of every exported file.

The receiver code lives under `analysis/parallel-aa-receiver/usb-helper/source/` (these override shared files by name), with shared sources under `analysis/parallel-aa-receiver/src/`. A portable host test (JDK 17) runs with:

```powershell
./tools/car-test/Test-PublicInputPcm.ps1
./tools/car-test/Test-PublicReceiverChanges.ps1
```

## What's intentionally not in this repo

To keep this snapshot safe to publish, it leaves out the working Android Auto receiver app itself, any installer or setup tool, proprietary vendor libraries, firmware/framework dumps, protocol credentials, signing keys and passwords, raw car/phone logs, and photos. Because of that, some reports mention files that aren't in the public copy.

Device serial numbers in the text are placeholders (head unit `00000000`, phone `11111111`), and personal paths and network addresses were removed. These are stand-ins for publication, not real settings — please don't weaken a car's identity or safety checks to force Hackura onto a different vehicle.

## License and disclaimer

No license has been chosen yet, and none is granted on behalf of any third party. Vendor code and binaries are excluded. Treat this as source-available research. Use it on your own vehicle, at your own risk; this project is independent and not affiliated with or endorsed by Honda, Acura, or Google.
