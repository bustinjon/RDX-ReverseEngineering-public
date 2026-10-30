# Local API22 asset archaeology — 2026-10-25

**No RUNNABLE_API22 or POTENTIALLY_RUNNABLE image was found. No runtime or ADB was executed.** Full staged inventory is under `../offline-freeze-20261025-015031-430/archaeology/`.

The search visited51260 entries, depth limited to6 with a90000-entry ceiling that was not reached. It inventoried59 local archives without extracting unrelated contents. ZIP central directories were searched for android-22, system-images, system.img, ramdisk.img, kernel-qemu and emulator binaries. The small promising Android-TV-tools RAR was separately listed using installed tar; it contains only two Windows tool executables, not an Android image. Unsupported unrelated7Z archives are recorded as uninspected, not silently treated as proof of absence.

|Candidate/location|Classification|Evidence|
|---|---|---|
|Installed SDK android-33/android-34|PLATFORM_ONLY|API stubs, data and source.properties; no system image or emulator|
|Old Android tool/JDK directories in Program Files|NOT_RELEVANT|JDK/build tools, not bootable Android|
|.android/AVD directory|STALE_REFERENCE|No AVD/image definition|
|VirtualBox Ubuntu registration|STALE_REFERENCE|Referenced Ubuntu.vbox absent; not Android|
|Saved Conscrypt/framework/build.prop and audit ZIPs|SOURCE_ONLY|Saved framework/system files without boot image/kernel/emulator|
|Android TV Tools v3/v4 archives|NOT_RELEVANT|Tool executables; no system image members|
|Downloads/Desktop/Documents and adjacent tools/archive directories|NOT_RELEVANT candidates only|Bounded filename and archive-member searches yielded no API22 image|
|WSL/Docker/Hyper-V/VMware locations|No usable Android candidate|Registry/path metadata checked; no distro/VM boot, mount, image pull or Docker execution|

Only C: is a local fixed drive. D:/E:/F: were classified removable and were **not scanned**. Android SDK roots, .android, AppData Local Android, Local/Roaming Google, C:\Android/android-sdk/SDK/Tools/Archives/Backups/Development/Dev, Downloads, Documents, Desktop, project tools and old ADB tool archives were checked. Reparse points and large unrelated caches/build/generated trees were excluded. Broken unrelated Desktop links are recorded as errors. This is bounded archaeology, not an assertion that every file on the machine was read.

The blocker remains an actual locally supplied bootable API22 image **plus** compatible emulator/runtime binaries. API/platform stubs and saved ARM framework libraries alone cannot create an Android runtime. No downloads, VM starts, physical-device access or attempts to execute target native libraries occurred.

Important provenance distinction: saved full-system/build.prop says build168, while the preserved raw M4 `identity-ro.build.fingerprint.stdout.txt` says build14. Both are Android5.1.1/API22, but they are not interchangeable runtime identities. Both saved Conscrypt copies hash F9937C3490DAE58DDCC68D427739854EE6AB761B3860173B0D283EED1805FDE8; that does not establish this hash on the latest live build. A future generic emulator pass also would not prove vendor-build parity.
