# Explicit session graph — host model only

11 states;18 declared non-error edges, plus9 whole-session invalidation edges. These counts describe local implementation rules, not18 distinct protocol messages. Getters/constructors never advance state. resetForNewSession creates a NEW object; it does not revive the old ERROR/CLOSED object.

State confidence: NEW/TRANSPORT_READY/VERSION_PENDING/VERSION_ESTABLISHED/DISCOVERY_PENDING/SERVICES_ADVERTISED/VIDEO_SERVICE_AVAILABLE/STOPPING/CLOSED/ERROR are **IMPLEMENTATION STRUCTURE**. MEDIA_SETUP_PENDING is **STRONGLY INFERRED** as an observed setup boundary. Formats are classified independently from abstract state names.

|From|Event|To|Confidence|Count|
|---|---|---|---|---|
|NEW|explicit transportReady|TRANSPORT_READY|IMPLEMENTATION STRUCTURE|1|
|TRANSPORT_READY|explicit beginVersion|VERSION_PENDING|IMPLEMENTATION STRUCTURE; raw format confirmed|1|
|VERSION_PENDING|supported base response1.1/status0|VERSION_ESTABLISHED|STRONGLY INFERRED; local supported profile|1|
|VERSION_ESTABLISHED|explicit enterPlaintextSimulation|DISCOVERY_PENDING|IMPLEMENTATION STRUCTURE; real security UNKNOWN|1|
|DISCOVERY_PENDING|valid request + validated local HU catalog|SERVICES_ADVERTISED|STRONGLY INFERRED; direction confirmed in references|1|
|SERVICES_ADVERTISED|matching video channel open|VIDEO_SERVICE_AVAILABLE|STRONGLY INFERRED|1|
|VIDEO_SERVICE_AVAILABLE|observed0x8000 setup|MEDIA_SETUP_PENDING|STRONGLY INFERRED; scalar meaning UNKNOWN|1|
|DISCOVERY_PENDING/SERVICES_ADVERTISED/VIDEO_SERVICE_AVAILABLE/MEDIA_SETUP_PENDING|supported peer shutdown; explicit local shutdown allowed in last3|STOPPING|STRONGLY INFERRED; strict local sequencing policy|4|
|STOPPING|shutdown response or peer-shutdown completion|CLOSED|IMPLEMENTATION STRUCTURE|1|
|NEW/TRANSPORT_READY/VERSION_ESTABLISHED/SERVICES_ADVERTISED/VIDEO_SERVICE_AVAILABLE/MEDIA_SETUP_PENDING|explicit complete EOF|CLOSED|IMPLEMENTATION STRUCTURE|6|
|Any9 nonterminal states|fatal malformed/state/bounds/time/EOF failure|ERROR|IMPLEMENTATION STRUCTURE|9 error edges, excluded from18|
|ERROR/CLOSED|any inbound/tick/old-session start event|unchanged|IMPLEMENTATION STRUCTURE|No resurrection|
|Explicit new-session construction|fresh parser/assembler/registry/queues|NEW object|IMPLEMENTATION STRUCTURE|Not an old-object state edge|

[Code block omitted from public report; see authored source where available.]

The diagram shows the principal path; the table is the complete declared edge policy.22 fixtures,18 saved transcripts,44 state/event matrix cells and seeded tests exercise the supported subset. The four matrix inputs are transport-ready,begin-version,plaintext-simulation-entry and discovery-request across all11 states; this is not a claim of exhaustive testing of every protocol message/state combination.

Failure containment:

- **A:** malformed framing/known schema, invalid local map, illegal known-message state, unsupported version/profile, unknown version extension, EOF while awaiting required control, bounds or clock fault invalidate the session and clear parser/assembler/reservations/registry/output queue.
- **B:** unknown valid envelope/type, post-discovery unknown channel and opaque encrypted bytes are rejected/retained without progression. Unknown semantics are not declared wire-valid merely because the envelope parses.
- **C:** optional unknown discovery service IDs are retained in the original advertisement, never opened, and do not corrupt understood video/input mappings.
- **D:** injected tick expires incomplete-frame, logical-fragment, expected-control or inactivity deadlines; it invalidates the whole session and releases allocations. Empty/slow continuations do not refresh the original fragment deadline.

Production timeout values remain POLICY_UNSPECIFIED. Tests explicitly choose10/20/100/1000 fake milliseconds; no sleeps or system-clock dependencies. Media readiness ordering is UNKNOWN, so the engine does not invent a setup-response expectation timer; only inactivity applies at that stop point.
