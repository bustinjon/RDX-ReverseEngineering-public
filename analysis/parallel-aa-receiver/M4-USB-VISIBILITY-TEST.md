# M4 passive USB visibility — 2026-10-23

Status: **READY FOR BOUNDED LIVE M4 TEST**, based on [independent APK audit](usb-probe/M4-INDEPENDENT-AUDIT.md). Not run on vehicle. Follow [NEXT-LIVE-TEST.md](NEXT-LIVE-TEST.md) for the consolidated operator procedure.

Purpose: determine whether an ordinary app can see the phone's descriptor inventory, including any factory-induced accessory re-enumeration. A visible device with hasPermission=false is a valid visibility PASS. Empty inventory is a successful empty snapshot, not phone visibility PASS. Baseline M0–M2 remain historical; M4 is not demonstrated.

Package `com.rdx.fullscreen.usbprobe`, explicit Service `.UsbInventoryService`, action `com.rdx.fullscreen.usbprobe.SNAPSHOT`. No Activity, requested permission, receiver/filter, native library, credentials, media, USB open/request/claim/transfer, AOA, GAL, or shell execution. Fifteen snapshots and fourteen 1-second delays maximum; duplicate starts are ignored. Local logger tag `RDX.M4` reports PID/UID/API/native path, clocks, device/configuration/interface counts, VID/PID/class/protocol, hasPermission, interfaces and endpoints. It ends with `END; passive enumeration only; no open/claim/permission-request/transfer performed`.

Future commands only (substitute independently verified `$Serial` and absolute `$Apk` from the build matrix):

[Code block omitted from public report; see authored source where available.]

No `-r` install. If already installed, installation fails, wrong serial/build, unexpected Activity/request/open/native behavior, crash/AVC, no termination, lost ADB or uninstall failure: STOP and preserve evidence; no privilege escalation. Phone attachment itself may trigger factory behavior. Low harness risk, with acknowledged OEM warning/history and normal phone-attachment side effects. Cleanup is own Service stop/uninstall plus normal phone disconnect, not rollback of Honda's own history/preferences.
