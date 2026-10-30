> Current2026-10-25 scope note: M4 proved ordinary passive USB visibility, not grant/open/ownership. M5 remains timing-INCONCLUSIVE; next live is the frozen M5 retry only. This saved trace is static/historical evidence, not current live activity. [Freeze](parallel-aa-receiver/OFFLINE-FOUNDATION-FREEZE.md).

# GAL transport on the D.1.6.4 RDX

2021 RDX / Android5.1.1 API22 / ARMv7. Existing code was reused; a bounded read-only observation refreshed USB state and copied the current receiver library and USB reset server. No USB open/claim/control transfer, socket connection, app launch/install, factory action or setting change was performed.

**Key finding: the protected GAL socket is a USB reset/control service, not the projection transport. Stock AndroidAuto.apk opens the phone through Android UsbManager and exchanges projection bytes through USB bulk endpoints.** An ordinary receiver can use this same public API after a per-device USB grant, subject to actual policy and exclusive interface ownership. No mandatory Honda transport FD broker was identified in this path.

## Complete data path

[Code block omitted from public report; see authored source where available.]

The USB Binder **does** pass an FD: UsbService→UsbHostManager.nativeOpenDevice returns ParcelFileDescriptor, and framework UsbManager/UsbDeviceConnection open the native connection from it. Within AA, ConnectionManager passes a **Java Transport object** through a local callback. GalReceiver does not receive a Honda Binder transport object or a reset-service socket stream.

After Android-accessory setup, input follows `UsbHostTransport.read`→UsbInputReader→InputOutputThreads'4-byte-header reader→nativeGetAdditionalBytesToRead→nativeQueueIncoming. Output follows nativeGetEncodedFrame→Transport.write→bulk OUT. Native TLS/protocol processing delivers service callbacks; VideoSink delivers configuration and video buffers back to Java. Stock ProjectionRenderer uses ordinary MediaCodec configure/start/input/output APIs and a Surface, not a privileged decoder FD passed by Honda.

## Call references

Paths below start at `decompiled/AndroidAuto-current/sources/` unless otherwise stated.

| Boundary | Concrete code |
| --- | --- |
| Stock attach/start | `com/honda/androidauto/projection/sink/receiver/StartReceiver.java`: USB_DEVICE_ATTACHED→explicit GalService intent with original_intent. GalService also installs its USB lifecycle receiver and processes already connected devices. |
| Acceptance / access | `.../service/GalService.java:1035`: hasPermission/requestPermission; `:1047` accepts saved-enabled devices; `:889` constructs ConnectionManager; `:973` switches a compatible phone into accessory mode. |
| AOAP initial setup | `.../transport/usb/UsbHostSetup.java`: openDevice, control request51 to query protocol,52 for accessory strings,53 to start; phone re-enumerates. This changes USB state and was not called. |
| Local transport handoff | `.../integration/ConnectionManager.java`: builds TransportFactory, opens device, forwards onConnected(Transport). AbstractConnectionManager's callback is an ordinary in-process interface. |
| USB data | `com/google/android/projection/transport/UsbHostDelegate.java`, `transport/usb/UsbHostTransport.java`: manager.openDevice, interface0, claimInterface(true), bulk IN/OUT. Stock true permits kernel-driver detachment where applicable; it must not be assumed to revoke another userspace claim safely. |
| GAL framing | `com/google/android/projection/protocol/InputOutputThreads.java`, GalReceiver.java: header/additional bytes, native queue/dequeue and transport lifecycle. |
| Stream/native decoding | VideoSink.java→ProjectionListener→Honda ProjectionRenderer.java; native video callbacks include `(IJLjava/nio/ByteBuffer;)V`. BufferPool allocates/recycles direct buffers. |
| System USB grant | `decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java:818,854,866,891`: UID1000 shortcut or permission map; normal requestPermission resolves caller package/UID and starts SystemUI UsbPermissionActivity. |
| System FD grant | `.../UsbHostManager.java:178`: rejects restricted/missing device, checks per-device permission, then nativeOpenDevice. UsbService.openDevice itself does not require MANAGE_USB. Direct grantDevicePermission does require MANAGE_USB. |

## Ownership and coexistence

1. Kernel/system_server enumerate and broker USB access. Stock AA's own process opens and claims the projection interface when it begins a session. “Initially owns USB” therefore has two meanings: the system controls enumeration/access, while AA becomes the userspace data consumer. A normal app would open a separate FD through the same broker after authorization.
2. Stock AA does open the USB device itself. There is no observed obligatory pre-established GAL data channel handed to it by a Honda daemon.
3. The kernel interface claim is a userspace ownership boundary. Two separately installed apps do not gain two independent Android Auto sessions to the same interface/phone. Opening a descriptor is not proof that a second claim or protocol engine can coexist.
4. Stock UID1000 receives automatic device permission. An ordinary app must obtain a user grant unless the configured dialog-disable option makes it unnecessary. Prototype code never calls privileged grantDevicePermission.
5. Honda's attach **broadcast** is independent of any chooser/default Activity. Selecting our launcher or a USB default does not prove the stock StartReceiver/GalService is suppressed. The current code has no safe cooperative lease/handoff API. Merely foregrounding our app cannot be counted as mutual exclusion.
6. Stock may attempt setup/claim/reset or reconnect after failures even while our app is foreground. A non-forcing custom claim can fail with busy; a custom session that wins a race could still be disrupted by stock recovery logic. Do not force a claim or use the reset service to overcome this.

The prototype deliberately has no USB-attach manifest receiver/filter and no mode-switch control transfers. It only attempts interface0 on an already enumerated Google AOAP device, using claimInterface(false), after a separate user grant/manual start. It never opens hubs, the TCU or an arbitrary device. If ownership is busy, it closes its FD and aborts. This is a useful diagnostic boundary, not a solution to the coexistence race.

## `/data/misc/gal/socket`: exact role and remaining limits

`common/GalUsbReset.java` is its only direct stock-AA socket client. `resetUSB(String)` connects with LocalSocket.Namespace.FILESYSTEM, sends a length-prefixed reset command/device path, reads an OK/error response, and closes. Callers use USB/VBUS reset/recovery operations around attach/disconnect failures. Projection frames do not use this socket.

Freshly copied `/system/bin/usbresetserver` is157332 bytes, SHA256 `FF9BD63334EB11854D1515834C187E62AFBD321A020593718176B4926A6BA08D`. It contains the exact socket path, reset_usbdevice_fs socket create/bind/listen/accept messages and VBUS command strings. A root process with this executable was captured (PID3135 in this snapshot). Together these identify usbresetserver as the reset listener. The binary is stripped/static in the available ELF view: no function symbols/import table were recovered, so precise chmod/chown/bind instruction flow is not claimed. [Binary evidence](parallel-aa-receiver/evidence/usbresetserver.selected-strings.json).

Saved file_contexts assigns `/data/misc/gal(/.*)?` to hrao_data_file and `/system/bin/usbresetserver` to hrao_native_service_exec. The current shell cannot even list the directory/socket: both return Permission denied. `/proc/net/unix` shows a listening Unix stream socket at the path (inode5988 in this snapshot), but it does **not** reveal filesystem owner/group/mode or peer checks. Exact UID/GID/mode, effective MAC rules and any socket peer authorization remain unknown. The root process may chown its socket, so process UID must not be substituted for socket ownership.

The path is a singleton service endpoint, not a per-APK transport address. It is not tied to our desired app package, and access would not provide Android Auto frames. This removes reset-socket access from the minimum-video privilege requirements.

## Current read-only snapshot

[Observation log](parallel-aa-receiver/evidence/device/commands.json):11 recorded successful read-only operations plus initial adb devices check. Commands were getprop, dumpsys usb/package/user/permission-definitions, ps, cat /proc/net/unix, mode/context listings and two pulls. Target reported D.1.6.4. Stock AA was UID1000, PID2440, active codePath `/system/app/AndroidAuto`, versionCode22/versionName5.1.1-14. PIDs/inodes are historical snapshot values, not future command targets.

No AOAP phone was in the host inventory; it contained host controllers/hubs and a DENSO TCU. Device/gadget `mConnected` is a separate field and must not be used alone to infer phone-host connectivity. No data-session ownership was observed. Raw USB dump includes incidental device identifiers/public ADB-key metadata and is retained locally, not reproduced in reports.

Current receiver native library pull is1918948 bytes, SHA256 `031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50`. Package path is a system_file symlink to `/system/lib/libautoreceiver_jni.so`, whose captured mode is read-only world-readable. [Provenance](parallel-aa-receiver/evidence/device/native-provenance.json).

## Remaining narrow observations / future tests

| Question | Read-only evidence that would help | What would still require separate approval |
| --- | --- | --- |
| Phone VID/PID, interface/endpoints, ordinary grant/dialog | dumpsys usb while an already-connected phone is in use; current SystemUI package/version and saved logs. Historical SystemUI DEX contains UsbPermissionActivity/UsbConfirmActivity/UsbResolverActivity. | Asking for a grant or opening/claiming a phone is a stateful app test. Not performed. |
| Actual data owner | Fresh ps and, if readable, `ls -l /proc/<current-AA-pid>/fd` matching the current usbfs device while projection is active; service/device logs. Root-protected entries may remain unreadable. | Stealing/releasing a stock FD, force-stopping AA or probing ownership with arbitrary traffic is not a read-only observation. |
| Normal-app SELinux access | Existing AVC logs and authoritative effective policy/type-attribute analysis. Saved structural evidence includes appdomain→usb_device class10 mask0x17 (read/write/ioctl/getattr-shaped common file permissions). | Actual custom-app grant/open/claim and any newly generated AVC require a separately approved app test. No denial bypass proposed. |
| Reset listener owner/mode | Readable stat/ls context output, or existing init/server source; if permitted, server FD inode correlation. | Connecting/sending a reset command is prohibited and irrelevant to the first video path. |
| Safe custom/stock arbitration | Logs showing stock's connection/retry lifecycle, explicit existing public lease API if found. | An actual non-forcing claim/handshake is a later test. Stock must not be disabled/cleared/uninstalled to discover behavior. |

No narrow read-only observation can prove two protocol engines safely share one phone. If a future ordinary-app test reaches grant but cannot claim exclusively, the next investigation is a **cooperative USB handoff**, not blanket UID1000/root or reset-socket access.
