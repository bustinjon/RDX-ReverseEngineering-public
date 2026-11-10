# T260 result (car, 2026-11-09 ~20:18-20:26, operator report)

Collect: SAFE TO DISCONNECT, KEEP. Capture (runs/helper_20261110T011809…) ends at the 20:19:24 power-off (unmount media), so the later drive is not logged.

| Check | Result | Evidence |
|---|---|---|
| Wireless start after Start | Retry | 20:19:14 P4_GROUP_CREATE_FAILED reason=2 (busy), then P4_DAILY_RETRY in 30 s. |
| Freeze on Home 20:21:35 and later | Not logged | After the power-off. |
| Call played on the phone | Not logged | 20:19:20 SET_BTH HFP state change and HondaStatusBar CALL_CANCEL just before the power-off. Likely the car's hands-free link was down, so AA routed the call to the phone (UNCONFIRMED). |

T270 adds automatic log saves (stall, HFP loss, call) that survive power-offs, plus a 1.5-s audio cushion.
