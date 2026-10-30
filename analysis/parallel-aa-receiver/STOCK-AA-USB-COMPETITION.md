# Stock AA attachment/ownership — 2026-10-23 offline continuation

Current Java evidence: StartReceiver handles USB_DEVICE_ATTACHED and starts GalService if its singleton is absent, forwarding original_intent. A running GalService registers dynamic attach/detach handling. Manifest vendor filters cover Google and several phone vendors. It is not necessary for our package to have an attach filter to enumerate devices.

GalService.onUsbDeviceConnected checks full operating mode and per-phone policy, can query AOA through openDevice, enters switching, and may select UI/start the conversion path. UsbHostSetup.processDevice opens interface0 and force-claims before request51/52/53. On accessory re-enumeration, allowed serial/ALWAYS policy can startGal; ASK/NEVER have different behavior and must be observed, not changed. UsbHostTransport opens and force-claims interface0, selects bulk IN/OUT, then starts transport. Its cleanup includes reset behavior; do not copy it into clean early tests.

`startGal` constructs ConnectionManager before reading the should-AA-auto-start preference; that preference controls foreground/minimized presentation/resumption decisions. **auto-start=false is not a USB ownership or protocol-disable switch.** This differs from separate per-phone ALWAYS/ASK/NEVER policy. Both must remain untouched.

UID1000 bypasses normal USB permission prompting in the pulled UsbSettingsManager. Ordinary apps can enumerate and use the supported permission dialog. Permission does not grant interface exclusivity; a non-forcing claim may later fail busy. ForceClaim may detach a kernel driver and is not a justified way to arbitrate with stock AA.

Predicted M4 observation: original phone descriptors -> stock attachment handling/AOA query -> disappearance -> accessory18D1 descriptors -> stock open/claim/protocol. M4 only logs inventory/permission state. Seeing only accessory mode remains valid visibility PASS; a1-second sample interval can miss the initial transient and does not prove it never existed. Log factory and RDX timestamps together. A visible device does not prove ability to open it; hasPermission=true does not prove claim success.

No suppression of factory AA is needed for passive M4. Active transport arbitration remains unresolved. Do not infer ownership from foreground UI, launch order or auto-start=false. No factory launch/force-stop/disable/clear, socket traffic, USB claim or protocol test was performed here.

## 2026-10-23 clips and clean-foundation continuation

Predicted attachment timeline, not a new runtime capture:

| Stage | Event | Evidence/confidence |
|---|---|---|
| T0 | Phone physically attached | External event; no current vehicle observation |
| T1 | USB host enumerates and framework emits USB_DEVICE_ATTACHED | Pulled UsbHostManager/UsbSettingsManager; HIGH |
| T2 | Honda StartReceiver starts GalService if absent; running service handles attach | Manifest/StartReceiver/GalService; HIGH |
| T3 | M4 may sample original phone descriptors | Passive getDeviceList; timing unknown and transient can be missed |
| T4 | Honda acceptDevice opens/query51 before user-acceptance GUI branch | GalService/UsbHostSetup; HIGH, gated by power/device/policy |
| T5 | Policy-supported conversion sends52/53 | switchToAccessory/processDevice; HIGH code path, occurrence conditional |
| T6 | Original USB identity disappears | Expected AOA detach; runtime timing not yet observed by M4 |
| T7 | Google accessory re-enumerates | Expected18D1/data PIDs; fresh permission/serial policy applies |
| T8 | Honda startGal creates ConnectionManager; UsbHostTransport open/claim interface0 | HIGH static path for ALWAYS/allowed serial; ASK may wait/NEVER reject |
| T9 | Protocol transport/session starts | Static integration path, actual timing/session outcome unmeasured |

T3 is an observer event and may occur before/after other rows; stock does not wait for our sample. T4 query can precede AA foreground UI. T5 may depend on per-phone GUI/policy choices. Accessory startGal creates transport before reading shouldAAAutoStart, so auto-start=false cannot be treated as transport suppression. Existing ALWAYS/ASK/NEVER policy and operating state can change the observed branch; leave them untouched. A one-second observer can see only accessory mode and still PASS visibility. No forceClaim, stock force-stop/disable or preference change is required/proposed for M4. Permission and exclusivity remain separate later questions.
