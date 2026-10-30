# Static provider shadow model — 2026-10-25

**STATIC PROVIDER MODEL, NOT API22 RUNTIME.** The saved Conscrypt Java/DEX evidence and20 previously extracted methods were reused; no Honda JNI, target Conscrypt native code or system libssl was loaded.

The prior22-check/10000-sequence provider model remains unchanged. New `Api22ShadowStateTests` adds8 deterministic checks and810078 invariant assertions across25000 short state/event sequences, seed154560618838757413 (`0x2251C105E261025`). It targets previously under-covered source/destination offsets, explicit latent residue, close staging, frame ownership, terminal behavior and reset epochs. It does not manufacture additional protocol interpretations.

|Path|Saved-provider finding|Model/differential result|
|---|---|---|
|unwrap input|Duplicate source passed to BIO; native-consumed delta copied back|Exact caller accounting remains mandatory; no full-consumption assumption|
|unwrap output|Read loop may drain internal plaintext; status chosen from consumed count|Positive plaintext with BUFFER_UNDERFLOW remains representable and must be retained|
|wrap minimum|Destination below16709 returns overflow before normal handling|Allocate/grow bounded session scratch; do not retry unchanged small buffer|
|wrap sources|Array loop iterates all sources despite offset/length|16870 generated source-selection differences versus specified slice contract; potential API22 risk, not a measured exploit|
|unwrap destinations|getNextAvailableByteBuffer loops offset..length rather than offset..offset+length|10033 generated destination differences; current production single-buffer overload avoids these array cases|
|handshake sink|position is drain cursor, available is size minus cursor|Internally generated output is not delivered bytesProduced; NEED_WRAP drains it; earlier unavoidable-count-mismatch suspicion not established|
|FINISHED|Getter may move HANDSHAKE_COMPLETED to READY once output empty|Preserve result FINISHED, avoid consuming completion out-of-band; not proof of inevitable failure|
|closeOutbound|DEX confirms shutdown/free, closed-state assignment and later shutdown; wrap short-circuits closed|Inaccessible close-output concern retained. No runtime crash/failure inferred from native zero-pointer handling|
|closeInbound|Visible Java path updates state without explicit truncation check|Caller EOF always aborts; quiet closeInbound is not authenticated close_notify|
|peer close|isInboundDone consults native shutdown bit; unwrap status need not be CLOSED|Existing wrapper mapping gap remains a risk pending runtime; no unsafe workaround introduced|

Two different hypothetical internal residue states can expose identical zero-output/empty-caller-input observations. This is an architectural counterexample to inferring completion from those observations alone, **not evidence that Conscrypt actually reaches both states**. Complete TLS record inspection plus exact consumption and empty drains is necessary; provider-specific completion qualification remains unresolved.

The model bounds synthetic residue to64 units and12 events per sequence solely for state exploration; these are TEST-ONLY values, not Honda/TLS limits. A new frame cannot inherit delayed plaintext from a previous context. Terminal states do not revive except an explicit fresh epoch. Synthetic shutdown output is marked inaccessible where modeling the saved concern, never falsely counted as delivered.

Desktop SSLEngine remains an independently executed mechanics baseline. Differences in task counts, source slicing, buffer/status behavior and close staging are classified EXPECTED PROVIDER DIFFERENCE, POTENTIAL API22 RISK or MODEL LIMITATION. Generated sequence counts are not Android runtime cases. No AndroidOpenSSL profile was enabled.

The new standalone APK contains raw completion/close probes and the actual production pump/adapter subset. It checkpoints each completed case and runs risky close tests last, so a future provider close failure need not erase earlier observations. TLS close-byte mechanics remain separate from unresolved AA routing for spontaneous TLS control/close output.
