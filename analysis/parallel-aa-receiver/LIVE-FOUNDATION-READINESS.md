# Future live foundation gates — 2026-10-25

**Planning checklist, NOT a live authorization or “API22 qualified” declaration.** Desktop foundation is frozen; API22 runtime remains unavailable. M4PASS; originalM5 timing-INCONCLUSIVE; frozenM5retry READY. Next LIVE **M5 RETRY ONLY**.

|Gate|Prerequisites|Allowed future scope|Stop|
|---|---|---|---|
|M5 retry|Separate user authorization; exact frozen APK; operator/phone/cable/UI ready; normal untrusted app|One normal UsbManager permission request; durable callback/hasPermission evidence|Retrieve, hash, uninstall, preservation postcheck; stop regardless of verdict|
|M6|Signed reviewed M5PASS, review [frozen M6](M6-AOA-FROZEN.md)/own-UID permission/stock race, separately reviewed activation release and explicit M6 authorization|Own normal permission request if needed,one bounded AOA query/six strings/START and re-enumeration observation|Retrieve/cleanup and STOP;no post-switch open/protocol|
|M7 handshake/discovery|M5PASS+M6PASS; ordinary USB ownership understood; backend/provider completion qualified; credential/trust strategy reviewed; bounded fail/reset; explicit authorization|First real transport/TLS/discovery test only|No implicit media/decoder escalation|
|Real media|Prior M7 evidence and separate approval; actual packet/AU/timestamp/accounting semantics observed|Bounded capture/abstract intake|No display claim|
|TI decoder|Separate authorization; decoder artifact audited; explicit configure/start and selected codec|Bounded actual hardware decoder test, no software fallback|Stop/cleanup before fullscreen claim|
|Fullscreen/touch|Phone acceptance and decoded raster/crop evidence; real input logs|Explicit experimental profile/mapping test|No assumed180/180 crop or touch offset|

M6 is **DISABLED UNTIL M5 PASS** and still needs separate authorization afterward. No script chains these milestones. Factory Honda package/data remains untouched; patched candidates are research artifacts only. Readiness does not mean phone acceptance or target rendering has been proven.

M5PASS proves the permission mechanism for that app/device instance. Its grant is **not transferred** to a future M6/M7 package/UID, is not assumed to survive detach/re-enumeration/uninstall, and does not authorize a different normal-phone identity. Future M6 must establish a fresh ordinary grant for its exact UID and initial device before any open/control operation. M6 AOA success would still not prove exclusive bulk-interface ownership against stock AA.
