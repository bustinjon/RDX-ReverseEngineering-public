# Next live decision tree

Start: **M5 INCONCLUSIVE — LOCK-TASK UI BLOCK**. The standard permission API path was reached; permission availability remains unresolved. Offline guard prepared: [plan](M5-RETRY-LOCKTASK-GUARD-PLAN.md), [reconstruction](M5-LOCKTASK-LIVE-FAILURE-RECONSTRUCTION.md). Next live remains **M5 RETRY ONLY**, requiring car + phone and separate explicit authorization. Exit Diagnostics normally, verify inactive lock-task/Home through the fresh five-second guard, then ARM only if its immediate check passes. Unknown or mismatched framework evidence means no ARM. No M5 APK change or automatic retry.

- M5 PASS → retrieve/cleanup/postcheck and **STOP**. Review the [offline-frozen M6](M6-AOA-FROZEN.md), signed evidence and [package permission strategy](M5-M6-USB-PERMISSION-STRATEGY.md); only then consider a separately authorized activation release and M6-only test. No broad redesign or automatic activation is implied.
- M5 INCONCLUSIVE → preserve exact timing/target/callback evidence; repair only the demonstrated test issue before proposing a retry. Do not infer permission denial from no target/no callback.
- M5 FAIL → require demonstrated restriction with adequate evidence; investigate the permission/privilege boundary before another runtime proposal.
- Future M6 PASS → **STOP**; prepare first M7 handshake/discovery only after provider/ownership/credentials gates are met.
- Future M6 FAIL/INCONCLUSIVE → investigate ownership/re-enumeration/stock contention; no automatic reconnect/reset loop or factory disabling.
- Future M7 data acceptance → still not decoder, rendering, display, fullscreen or touch success.

No branch automatically authorizes or executes the next milestone. M4 remains PASS and is not reopened without new contrary evidence. The MaliciousDetector acquisition is a separately authorized read-only collection, not an automatic branch of M5.

