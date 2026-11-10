# T180 bundle: car results (2026-11-08 evening, operator report + logs)

Build B5909FF31B5E81CE6EB58562ACE90811EEBC4AB2C38475934EFFBD1205A1B5AB. Start's automatic stop of the leftover copy worked (no UNTRACKED refusal). Collect: SAFE TO DISCONNECT, daily features KEPT (operator-20261109-004946/daily-features-kept.json). Evidence: runs/helper_20261109T003917… (capture.log now holds the RDX.WIRELESS and SET_BTH lines).

| Item | Result | Evidence |
|---|---|---|
| Quiet Wi-Fi (19:42-19:44) | NO CONNECTION | P4_STATION_PAUSED 4/4; group GO on 2437 MHz; credentials over USB; P3_READY_SENT alreadyPaired=true; after unplugging no RFCOMM accept, no TCP; P4_STATION_RESTORED 4/4. |
| Quiet + 5 GHz (19:44-19:48, two runs) | NO CONNECTION | P4_5GHZ_REQUEST accepted; P2P-GROUP-STARTED freq=5180 (5 GHz works); same: no RFCOMM accept; reset ok. |
| Phone SDP query | NEVER ANSWERED | 7x P5_PHONE_SDP_REQUEST ok=true (linkUp mostly true); zero P5_PHONE_SDP_RESULT. Either Honda's stack doesn't deliver ACTION_UUID to apps or the query never runs. |
| Music after Gemini | PASS | 19:45:15 and 19:45:40 "AUDIO_FOCUS_RESTORE sent to the phone why=assistant-ended afterMs~0.7 s". Operator: works. |
| Honda HFP events | seen | SET_BTH_BluetoothHFPProfile CONNECTION_STATE_CHANGED at 19:42:40/50/51 (Bluetooth on) and 19:47:34, 19:48:00/01 (no state values in the log line). |

Conclusion: every head-unit-side precondition we control works (group, 2.4 and 5 GHz, credentials, pairing reply, listeners). The phone never opens the AA RFCOMM service. Next: research how Android-head-unit apps (open-headunit native mode, ZLink-type apps) actually trigger it.
