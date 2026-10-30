# M6 state guarantees and event policy

19 states;17 normal progression edges including the IDENTITY_PENDING self-edge for six strings (16 changing-state edges). Error/close/replay routes are additional. The session's `observed-state-edges.csv` counts exercised durable/public outcomes separately; it is not advertised as exhaustive reachability proof.

|State|Permitted progress/event|Guarantees|Does not guarantee|
|---|---|---|---|
|NEW|Explicit begin/proof or restore;close|Inert object, no USB/journal I/O from construction|M5 gate or authorization|
|GATE_CHECK|Valid proof→WAIT_TARGET;missing→ERROR|Journal initialization/gate under inspection|M5 PASS until verified;USB grant|
|WAIT_TARGET|Unique configured normal attach→TARGET_SEEN;timeout/ambiguity→ERROR|Gate accepted, no open/controls|Phone present or permission|
|TARGET_SEEN|Own grant→PERMISSION_VERIFIED;otherwise one request→PERMISSION_PENDING|Exact normal VID/PID/id/path/generation pinned;metadata recorded|Physical continuity/permission/exclusive ownership|
|PERMISSION_PENDING|Validated nonce/device/callback + fresh grant→verified;deny/timeout/loss→ERROR|At most one request, durable intent|Dialog visibility, grant or M5 grant transfer|
|PERMISSION_VERIFIED|OPEN_PENDING|Own UID hasPermission was true for current attachment|It will remain true;device open|
|OPEN_PENDING|One open→PROTOCOL_PENDING;failure→ERROR|Permission/generation rechecked|Open acceptance/claim or bulk ownership|
|PROTOCOL_PENDING|One query→PROTOCOL_CONFIRMED;error/unsupported→ERROR|One bounded endpoint-zero query at most|Protocol supported until exact reply parsed|
|PROTOCOL_CONFIRMED|IDENTITY_PENDING|Unsigned LE16 exact two-byte version1/2 accepted|Android Auto compatibility|
|IDENTITY_PENDING|One52 per index0–5;then IDENTITY_SENT|Prior indices returned expected length;no retry|Phone application processing or exclusive causation|
|IDENTITY_SENT|START_PENDING|All six fixed local strings accepted by transfer API|Phone mode switched|
|START_PENDING|Persist START_INTENT,one53;return→START_SENT;uncertainty→START_OUTCOME_UNKNOWN|No second START path;intent precedes call|Request reached device when outcome unclear|
|START_SENT|Close handle→WAIT_DETACH|Expected zero-length return durably recorded|Phone processed START or our exclusive causation|
|WAIT_DETACH|Original absent in-window→WAIT_REENUM;timeout→ERROR|Connection closed;no further transfers|Any detach is caused by us|
|WAIT_REENUM|Unique known fresh accessory in-window→COMPLETE_STOP_REQUIRED;other/timeout→ERROR|No reopen, bounded observation|Physical same-phone identity beyond temporal metadata|
|COMPLETE_STOP_REQUIRED|Evidence/retrieval only;all callbacks/events inert|Bounded sequence and accessory association observed;no M7 continuation|AA/GAL/TLS/decoder/phone acceptance/bulk ownership|
|START_OUTCOME_UNKNOWN|Evidence/manual review only|Terminal INCONCLUSIVE;never automatically resend START|Whether START reached device|
|ERROR|Evidence/close only;no revival|No more actions;safe termination attempted|Functional platform rejection unless evidence specifically proves it|
|CLOSED|Evidence only;new controller/run requires explicit review|No resumed action;prior journal preserved|A fresh PASS based only on replay|

Any active state may close to CLOSED. Boundary/corrupt evidence fails closed; uncertain pre-return START selects START_OUTCOME_UNKNOWN. Restore is explicit and read-only with respect to USB: empty/corrupt/stale/interrupted/terminal journals do not launch a fresh sequence. A same-run Android Service directory is refused; START_NOT_STICKY/no boot handler prevents automatic restart. These are host/model/static guarantees, not a vehicle power-loss durability certification.

Final APK additionally blocks all live progression before gate processing. This table describes the host-tested core and a hypothetical separately reviewed future activation release. It is not permission to run M6.
