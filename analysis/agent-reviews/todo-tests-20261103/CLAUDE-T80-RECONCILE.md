# T80: Claude's reconciliation of the Codex review (CODEX-T80.md)

Codex verdict: READY FOR CAR TEST (parked), no BLOCKER. Each SHOULD-FIX was checked against the code.

| Codex item | Verified | Action |
|---|---|---|
| T80-6 dwell spans lifts / needs a later event / lags one event | Yes (ScrollStrip.leave kept rest fields; track only on events; overlay passed the previous cursor) | Fixed: leave() clears the rest; settle() counts a rest at the next move, lift or strip entry; leaving the main area ends a rest; the overlay passes the current position. 4 new tests |
| T80-7 no fallback if stream 10 is refused | Yes (AudioSink threw and the guidance worker ended) | Fixed: AUDIO_TRACK_STREAM_FALLBACK, retry on STREAM_MUSIC |
| T70-4 art decode unbounded | Yes | Fixed: bounds decode, inSampleSize to <= 512 px |
| T70-9 `focused` crosses threads | Yes | Fixed: volatile |
| T70-8 test.json vs VISIT (GRANT, After-PowerOff order) | Yes | Fixed: test.json steps now match VISIT.md (GRANT stays offered but skippable) |
| T70-5 / T80-8 lasting USB default not documented | Yes | Fixed: VISIT.md note (only uninstall or Clear defaults removes it) |
| T80-4 unknown phone state reported as PLAYING | Yes | Kept on purpose: the operator asked for Hackura to be selected when AA opens. Watch for FM/BT being taken over at the car |

Rebuilt: T80 58336C0471104D9ADE4E7A9974D9A9D5CEDD23BADFD59849706439D5C105C619, PASS 127 bundle checks plus all feature suites, baseline restored.
