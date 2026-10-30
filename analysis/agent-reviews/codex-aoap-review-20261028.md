A–D pass: the request types, six strings, indices, and unsigned little-endian decoding are correct. **The write recovery has two high-severity risks. Do not add an interface-count requirement of `>= 2`.**

**1. Files inspected**

- `PROJECT-RULES.md`, `AGENTS.md`
- [UsbHelperService.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java:465)
- [Honda UsbHostSetup.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/transport/usb/UsbHostSetup.java:43)
- [UsbBulkTransport.java](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/UsbBulkTransport.java:103)
- Supporting excerpts: Honda `GalService.java`, our `AaSessionService.java` and `ProjectionSession.java`.
- Targeted searches also covered transport callers and `GalReceiver.java`.
- Primary AOSP/Linux protocol and implementation sources linked below.

**2. Files changed**

None by this review. Both implementation files changed externally during review; findings below use the final inspected snapshots.

**3. Commands run**

Read-only commands: `Get-Content`, `Select-Object`, `Select-String`, `rg`, `rg --files`, `Get-FileHash -Algorithm SHA256`, `Get-Location`, `git status --short`, and scoped `git diff`.

Also ran in-memory source comparisons and arithmetic checks, plus primary-source web lookups. No build, device command, or Git mutation was run.

**4. Tests run and results**

- **PASS:** automated comparison found six identical Honda string values with ordered indices `0–5`.
- **PASS:** expected request tuples and SEND_STRING loop were present.
- **PASS:** unsigned decoding arithmetic matched a little-endian `DataView` for all **65,536** possible two-byte responses.
- **PASS:** supplied `UsbHostSetup.java` contains **zero** `getInterfaceCount` calls.
- These were source/arithmetic checks, **not Java execution or USB integration tests**.
- Preliminary checks encountered an inaccessible Python executable, constrained PowerShell methods, and parsing failures. The successful checks above used the tool’s JavaScript runtime.

**5. Findings**

- **HIGH — Retrying a negative bulk-write result can duplicate delivered bytes.**  
  [UsbBulkTransport.java:109](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/UsbBulkTransport.java:109) retries from unchanged `pos` after every `n <= 0`. Linux can report an error after partial transfer; its synchronous usbfs interface returns the error instead of the partial byte count. Replaying the same range can therefore corrupt the GAL byte stream. Positive short writes are handled correctly by advancing `pos`. Recovery needs known transfer progress or session termination when progress is ambiguous. Actual occurrence on this target is **UNKNOWN**.

- **HIGH — Raw CLEAR_FEATURE is incomplete host-side halt recovery.**  
  [UsbBulkTransport.java:119](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/src/com/rdx/fullscreen/projection/UsbBulkTransport.java:119) sends the correct endpoint CLEAR_FEATURE request, but standard Linux halt recovery additionally resets the host endpoint state/data toggle. A raw control transfer does not perform that additional operation. The constructor does the same at lines 54–55. Successful device-side clearing can therefore leave host/device state inconsistent. The code also logs `clr` without requiring success before retrying.

- **MEDIUM — SEND_STRING accepts incomplete nonnegative results.**  
  [UsbHelperService.java:496](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java:496) checks only `r < 0`. Require `r == strBytes.length`, matching Honda’s exact-length validation at `UsbHostSetup.java:106`. Otherwise an incomplete transfer can be followed by START_ACCESSORY.

- **LOW — Both implementations omit required string terminators.**  
  Our helper sends UTF-8 bytes without a trailing NUL at [UsbHelperService.java:492](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/UsbHelperService.java:492); Honda likewise uses plain `str.getBytes()` at `UsbHostSetup.java:106`. This matches Honda but deviates from AOA’s zero-terminated requirement. AOSP’s accessory driver supplies termination, explaining tolerance there; target-phone behavior is **UNKNOWN**.

- **INFORMATIONAL — No missing-delay race between clearing and the next write.**  
  The same thread completes the blocking control transfer before submitting its next bulk transfer. Adding a sleep does not address the recovery problems above. `close()` can interleave with I/O because `write()` does not share its synchronization; that is a separate shutdown interaction.

- **Resolved during review:** the latest helper returns a boolean, checks negative START_ACCESSORY results, and gates its switch-sent state on success. The initial snapshot lacked those checks.

**6. Primary evidence for each finding**

| Requested verification | Result and evidence |
|---|---|
| **A. Request types** | **Correct.** Helper lines **476, 493, 501** use `0xC0/51`, `0x40/52`, `0x40/53`. Honda lines **115, 123** use equivalent decimal values `192` and `64`. These agree with [AOSP’s request definitions](https://android.googlesource.com/platform/packages/services/Car/+/d485956/car-usb-handler/src/android/car/usb/handler/AoapInterface.java). |
| **B. Six indices** | **Correct on the successful path.** Helper lines **487–493** iterate six strings using `i` as `wIndex`; Honda lines **74–94** explicitly send indices `0–5`. Both stop on detected errors. |
| **C. String values** | **Identical:** `Android`, `Android Auto`, `Android Auto`, `1.0`, `http://www.android.com/auto`, `0000000012345678`. Helper lines **487–488**; Honda lines **74–94**. |
| **D. GET_PROTOCOL** | **Correct.** Helper lines **477–483** require two bytes, mask both bytes unsigned, combine little-endian, and reject zero. Honda line **117** omits unsigned masks; our decoding is more robust. |
| **E. Stock steps/delays** | Honda claims interface 0 before switching: `UsbHostSetup.java:49–56`; our switch skips that. Standard Linux permits vendor control requests without an interface claim: [check_ctrlrecip](https://raw.githubusercontent.com/torvalds/linux/v3.10/drivers/usb/core/devio.c). Honda has **no inter-request sleeps** in lines **68–123**. Its request timeout is **100,000 ms**, versus our **1,000 ms**. Honda’s outer service uses a **3/10-second re-enumeration timer**, `GalService.java:973–1005`; our latest helper has a 10-second timeout at lines **203–205**. |
| **F. Interface count** | **The premise is contradicted by this stock source.** Honda checks **`> 0` before switching**, at [GalService.java:975](C:/Users/REDACTED/Desktop/RDX-ReverseEngineering/decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/service/GalService.java:975). Requiring `>= 2` would reject valid `0x2D00` devices, which have one interface. [AOA documentation](https://source.android.google.cn/docs/core/interaction/accessories/aoa?hl=en) identifies the second `0x2D01` interface as debugging. Our transport already requires interface 0 with bulk IN/OUT endpoints at lines **26–37**. |

For the high-severity write findings, Linux [`proc_bulk`](https://raw.githubusercontent.com/torvalds/linux/v3.10/drivers/usb/core/devio.c) returns the error rather than `len2` on failure; [`usb_start_wait_urb` and `usb_clear_halt`](https://raw.githubusercontent.com/torvalds/linux/v3.10/drivers/usb/core/message.c) show partial-progress accounting, synchronous completion, and the additional host endpoint reset. Android’s [JNI implementation](https://android.googlesource.com/platform/frameworks/base/+/android-4.4.2_r2.0.1/core/jni/android_hardware_UsbDeviceConnection.cpp) delegates control requests to [libusbhost’s USBDEVFS_CONTROL path](https://android.googlesource.com/platform/system/core/+/bfec3a3/libusbhost/usbhost.c).

The NUL requirement is explicit in the AOA documentation above; [AOSP’s accessory driver](https://android.googlesource.com/kernel/common/+/8c51adb100d9453a35a66c6336d2ca33321673e7/drivers/usb/gadget/function/f_accessory.c) appends termination in `acc_complete_set_string`.

**7. Assumptions**

The supplied decompilation is the intended Honda comparison baseline. Platform recovery conclusions describe the cited standard Android/Linux implementations.

**8. Unresolved uncertainties**

Target vendor kernel/framework parity, actual endpoint toggle state, partial-delivery incidents, phone-specific timing, and live handshake behavior are **UNKNOWN**. No live validation occurred.

**9. Exact diff summary**

None authored. Existing working-tree changes were preserved.

**10. Preservation checks performed**

Hashes matched immediately before and after reading each final implementation snapshot:

[Code block omitted from public report; see authored source where available.]

Rules-file hashes also remained unchanged. No frozen artifact was rebuilt or modified; frozen binary hashes were not checked. No key material was read.