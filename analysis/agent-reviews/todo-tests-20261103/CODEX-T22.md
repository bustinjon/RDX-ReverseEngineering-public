1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`; requested T22/baseline `AaOverlayService.java`, T22 `HomeToggle.java`; baseline `InputEvents.java`; local decompiled framework/policy files cited below. Aliases: **A** = T22 service, **H** = adjacent HomeToggle, **P** = `decompiled/Policy/sources/com/android/internal/policy/impl/PhoneWindowManager.java`; **F** = `decompiled/Framework/sources/android/view/`; **S** = `decompiled/Services/sources/com/android/server/wm/`.

2. **Files changed:** none.

3. **Commands run:** `Get-Content`, `Get-ChildItem`, `rg`, `Compare-Object`, `Select-Object`. Python diff attempt failed because `python.exe` was inaccessible; comparison completed using PowerShell.

4. **Tests run and results:** none; static source review only.

5. **Findings:**

- **BLOCKER — Home escape is blocked by the focused window type.** A:348 creates `TYPE_SYSTEM_ERROR`; A:358 requests focus. Honda policy maps type 2010 to “consume Home,” returning before `launchHomeFromHotKey()` can broadcast `homekey`. The receiver therefore cannot provide the intended first-Home escape under this policy. Evidence: P:2173–2187, P:2573–2584, P:2589–2591. Overlay package is absent from the Home allowlist at P:385.
- **SHOULD-FIX — failure paths leave inconsistent recovery state.** Receiver-registration failure leaves the already-added fullscreen window installed (A:357–367). Restore removes the button and resets toggle state before `updateViewLayout` succeeds (A:594–600). Button-removal failure is swallowed and its reference discarded (A:628–629).
- **OK — alpha/flag changes do not directly destroy the TextureView surface in the inspected implementation.** `updateViewLayout` updates parameters without detaching; alpha becomes compositor surface alpha. Visibility remains unchanged. Evidence: A:585–587; F/WindowManagerGlobal.java:225–239; F/ViewRootImpl.java:814–818,1050–1054; S/WindowManagerService.java:2316–2335; S/WindowStateAnimator.java:991–994. TextureView destruction is associated with detach/hardware-resource destruction: F/TextureView.java:149–159,228–230.
- **OK — pad-select and media ownership are cleared on minimize.** A:583–584 cancels select and resets media ownership; baseline `InputEvents.java`:115–117 emits select-UP on CANCEL, and :65 clears owners. Previously queued media-UP remains scheduled (A:199–201); minimize does not clear callbacks.
- **OK — normal exit paths clean up receiver/button.** STOP, replacement START/VIDEO, test timeout, and destruction reach `removeOverlay`; it unregisters the receiver and removes the button. Evidence: A:147–168,375–376,632–639,669–671. Exception caveats are listed above.
- **OK — rear-camera ordering is higher in local Honda policy.** Rear camera is type 2041, layer 38; AA’s type 2010 is layer 24. Evidence: F/WindowManager.java:209,219; P:1672–1673,1730–1731.
- **OK — toggle timing matches intent.** H:18–25 restores on a second Home within 1200 ms and consumes the pair; H:30 resets timing after button restoration.

6. **Primary evidence:** source locations accompany each finding; baseline comparison used `Compare-Object`.

7. **Assumptions:** local decompiled Honda policy/framework represents the target firmware.

8. **Unresolved uncertainties:** actual target broadcast delivery, decoder continuity, and camera presentation are **UNKNOWN** without runtime evidence.

9. **Exact diff summary:** not applicable; no edits.

10. **Preservation checks performed:** read-only commands only; no device, build, Git, network, credential, or frozen-artifact actions.

**NOT READY**