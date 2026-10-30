# DRAFT v2 — request to 2022+ RDX owners (NOT posted; edit freely)

Suggested places: Acurazine "3G RDX" section, r/AcuraRDX, Facebook RDX owner groups. Post under your own handle. Don't include VIN, serial, plate or location. Nothing here has been published.

---

## Main post

**Title:** Reverse engineering full-screen Android Auto for the 2021 RDX — need help from 2022+ owners with ADB access

I'm reverse engineering my 2021 RDX (software D.1.6.4) to get full-screen Android Auto. On the 2021 it's stuck in a narrower picture with black bars. The 2022–2025 RDX has it: Acura's bulletin B23066 says software **F.1.4.1** "adds support for full screen CarPlay and Android Auto", but 2021 isn't covered and Acura won't update it.

I've already done a lot of groundwork on the 2021: I have ADB access, I've decompiled Honda's Android Auto receiver and found where the smaller video size is set, and I've cleared the side panel with a reversible display command. What I'm missing is **Honda's newer receiver from a 2022+ unit** to compare against. That would show me exactly how Acura changed it, and whether it can safely be done on a 2021.

**What I need from a 2022+ owner who has ADB access to the head unit** (all read-only, nothing on your car is changed):
1. `adb shell pm path com.honda.androidauto.projection.sink`, and tell me the path it prints.
2. `adb pull` the APK at that path, plus any other `.apk` in the same folder.
3. `adb pull` the `lib` folder next to it (it contains `libautoreceiver_jni.so`).
4. `adb shell getprop ro.build.fingerprint`
5. `adb shell dumpsys package com.honda.androidauto.projection.sink` (the version lines are what matter).
6. If you can, `adb shell dumpsys window | grep -i -E "mOverscan|mStable|mRestricted"` and a photo of Android Auto running full width.

**How to get ADB on the head unit** (this is how I did it on my 2021; the 2022+ menus may differ a little, so tell me if yours does):
1. Ignition ON (or engine running), parked.
2. Press and hold these three physical buttons under the touchpad at the same time: **Back + Home + Track/Card**. Hold about 3–5 seconds until a screen appears with **Self-Diagnosis Mode** and **Detail Information & Setting** (that's Dealer Diagnostics).
3. Select **Detail Information & Setting**. On that screen, press and hold the same three buttons (the **Track/Card** button is the one that matters) for about 5 seconds. A hidden **Developer Diagnostics** list opens.
4. Switch **USB Mode Switch** from *Apple CarPlay* to **ADB**. (It's the first item in the list.) This turns the head-unit USB port into an ADB port until you switch it back, so Android Auto/CarPlay won't work on that port meanwhile.
5. Optional, for the normal Developer Options page: in that same list, scroll to the end and set **Enable Developer Option**. Then go to the regular **Settings → System → About**, tap **Build Number** 10 times, and a **Developer Options** line appears. Inside it, **USB debugging** does the same thing as step 4.
6. Connect your computer with a USB cable to the head-unit port. On the first connection the car asks **Allow USB debugging?** and you accept on the car's screen.
7. When you're done, set USB Mode Switch back to *Apple CarPlay*.

**Careful:** the Developer Diagnostics list contains items that can damage the unit, including **Compulsion Loading**, **Factory Flashing**, **Bootloader Update** and firmware updates. Don't touch those. Only use USB Mode Switch (and Enable Developer Option).

Please **don't** send VIN, serial numbers, phone info or anything personal. None of the above contains any, but glance over before sharing. Please don't flash, delete or change anything on your car.

I'll share what I learn here, and I won't pass your files on to anyone else. If you don't have ADB access, even your **Acura software version** and a **photo of Android Auto full-screen** help. If you know how to reach the hidden developer/diagnostic menu on a 2022+ unit, that's useful too — tell me how you got there.

Thanks! Happy to answer questions and post my findings on the 2021 side.

---

## Shorter Reddit version

Reverse engineering full-screen Android Auto for the 2021 RDX (D.1.6.4). I have ADB on the 2021 and have decompiled Honda's receiver (`com.honda.androidauto.projection.sink`); I found where the narrower video size is set. 2022–2025 has full screen via software F.1.4.1 (bulletin B23066). **I need a 2022+ owner with ADB to pull that app** (read-only): `adb shell pm path com.honda.androidauto.projection.sink`, then `adb pull` that APK and the `lib` folder next to it (has `libautoreceiver_jni.so`). No VIN/personal data. I'll share findings. Even just your software version + a screenshot helps. Thanks!

---

## Verification of the ADB steps (not part of the post)
Checked against code from this unit's own saved firmware (build 168 audit; live build 14 not guaranteed identical) plus a real log, because the public web had nothing for the 2019-2021 RDX.
| Your step | Result | Evidence |
|---|---|---|
| Hold Back + Home + Track/Card | **CONFIRMED.** Keys are HOME (3), BACK (4) and the Guide key (172, "Track/Card"). Needs a 3-second hold, not 5 (5 is fine). | `PhoneWindowManager.java:2126-2130` and `:121` (decompiled/Policy); real log `adb/AA-live-logcat.txt:989` "Diagnostics combo key detected. Starting Dealer Diagnostics" |
| Screen has Self Diagnosis + Detail Information & Setting | **CONFIRMED** | `adb/diag-dealer.xml`; `dealer/MainActivity.java:104` |
| Select Detail Info, hold again 5 s | **CONFIRMED for 5 s.** The code only needs the Guide (Track/Card) key held 5 s on that screen; holding all three includes it. | `MenuActivity.java:290-299` (`LONG_KEY_TIMEOUT = 5000`) |
| "Enable Developer Option" in that list | **CONFIRMED the item exists** (3rd page of Developer Diagnostics) | `adb/diag-developer-3.xml`; used by `DeveloperOptionsActivity.java:91` and `StatusActivity.java:195` |
| Tap Build Number 7-10 times | **Needs 10 taps**, and only works if Enable Developer Option is already on. The "You are now a developer!" popup was NOT found in the code; what appears is a new "Developer Options" line. | `StatusActivity.java:195` (counter >= 10 AND `isDeveloperOptionEnabled()`) |
| Developer Options -> USB debugging ON | **CONFIRMED** (sets system property `dev.adb` = 1) | `OptionWithButtonsActivity.java:289` |
| "USB Mode / Host Role" -> ADB Mode | **Wording differs.** The real screen is **USB Mode Switch** with two choices, "Apple CarPlay" and "ADB". It sets the SAME property `dev.adb`. So you do NOT need steps 3 and 4 of your list if you use USB Mode Switch. | `USBModeSwitchActivity.java:16-20, 47-48` |
Not verified: that the 2022+ menus are identical; the physical button names/positions on your car (code calls them HOME, BACK and GUIDE; your notes call GUIDE "Cards List"); whether the car's "Allow USB debugging?" prompt always appears.
Side effect worth knowing: holding only BACK + HOME triggers a harmless log-capture/screenshot broadcast (`PhoneWindowManager.java:6015`).

## Notes for you (not part of the post)
- Expect few replies: ADB on these units normally needs a hidden diagnostics path most owners don't know about.
- We only ever *receive* files to read offline. Never run or install anything someone sends for the head unit. I check hash and signer first; nothing is installed without your separate approval.
- Don't offer or accept anything that involves faking a vehicle data file for Honda's update portal.
- Check the claims in the post are ones you're comfortable making publicly (ADB access, decompiling, overscan command).
- Reference: [Acura bulletin B23066 (NHTSA)](https://static.nhtsa.gov/odi/tsbs/2026/MC-11028529-0001.pdf)
