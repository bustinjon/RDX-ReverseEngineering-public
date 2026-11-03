# Maps-only Diagnostics comparison result

1. **Files inspected:** comparison-latest.json and retry-20261031-222126/baseline-install.json; user's current test observation.
2. **Files changed:** Added retry-20261031-222126/manual-shortcut-user-result.json and this report. No production/device changes.
3. **Commands run:** Get-Content of the two installation metadata files; apply_patch to save the user observation.
4. **Tests run and results:** Manual shortcut PASS_USER_REPORTED: "Were good I was able to access the menu". No additional device test performed by this agent.
5. **Findings:** Manual Diagnostics entry succeeds after installing the Maps-focus-only candidate with helper stopped at installer completion. This does not establish helper-startup or Maps runtime behavior.
6. **Primary evidence for each finding:** User observation saved verbatim in manual-shortcut-user-result.json; baseline-install.json pins installed SHA-256 21037DC393FCD162499589254D745DD0904A326BD7E5A33D69CF3FC69BFA4084 and records helperAbsent=true, helperArmed=false and accessibilityUnchanged=true at completion.
7. **Assumptions:** User tested the installed candidate without an intervening installation. Helper state was not queried again after the reported manual test.
8. **Unresolved uncertainties:** Original Diagnostics failure cause UNKNOWN; helper activation and route retention untested; post-test foreground/cleanup state UNKNOWN. Reinstall/transient-state confounding remains.
9. **Exact diff summary:** Two new result documents only. Historical installation records remain unchanged, including their original PENDING field; the later observation is saved separately.
10. **Preservation checks performed:** No source, APK, guard, setting, key material or Git operation touched. No fresh artifact rehash or device check was necessary to save this observation.
