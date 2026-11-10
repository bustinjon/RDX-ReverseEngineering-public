# T21 results

## Run 1 — 2026-11-04, build B888B05A… (drain fix only)
- Operator: prompts broken while music plays; fine with music paused; Gemini's voice audible (mic still refused, expected); music resumes after.
- Logs: each guidance session played one 4096-byte chunk, then the phone stopped and restarted about 1 s later. Each start ducked media (AUDIO_FOCUS id=4 change=-3), and AaSessionService forwarded that to the phone as protocol LOSS_TRANSIENT_CAN_DUCK, so the phone stopped its own prompt. Restore (change=1) was forwarded as GAIN and the prompt restarted. Loop.
- The drain fix itself works: AUDIO_SUMMARY id=5 drops fell, and Gemini audio played.

## Run 2 — pending, build 5C5455F8… (drain + internal duck not forwarded to the phone)
- Operator: navigation voice works. Collected, cleanup verified.
- Logs (run helper_20261104T211235_b09da7c8d703491c9899781a94621845): AUDIO_SUMMARY id=5 received=184 playedBytes=354304 dropped=11 (run 1: 181/205 dropped); AUDIO_FOCUS_INTERNAL_DUCK/RESTORE not forwarded x4; 22 guidance drains.
- **PASS. Promoted to the baseline on 2026-11-04** (tools/Promote-Baseline.ps1). T10, T11 and T13 were rebuilt on top of it.
