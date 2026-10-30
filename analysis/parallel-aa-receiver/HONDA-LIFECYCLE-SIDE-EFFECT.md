# Honda lifecycle side effect — consolidated offline continuation 2026-10-23

Historical Live Test02 remains M0/M1/M2 PASS; no claim Honda private preferences were unchanged. At20:56:08.234 customPID30513 Activity resumed; stockAA PID2440 called its false setter at20:56:08.238. An earlier false setter at20:54:29.398 predates our resume. The new call may repeat an already-false value; old/new equality was not measured or restored.

Framework Application.onCreate -> Honda ApplicationFixup -> AcuraLifecycleCallbacks registration -> onActivityResumed -> com.honda.tjba.launcher.APP_LAUNCHED (package_name/activity_name) -> GalService.mApplicationStartupReceiver. Stock excludes its own AA/launcher names and sets StartPreferences.shouldAAAutoStart=false for other apps. `gal_start_preferences`, key `gal_should_auto_start`, MODE_PRIVATE, commit(): persistent setter semantics. It is not evidence of malicious harness code.

The getter changes UI auto-start/resume/minimized behavior, not the underlying USB permission/transport-disable switch. Corresponding true setters exist in normal LUM/foreground/disconnection paths; no manual preference restoration is authorized. It is normal Honda foreground-selection behavior with a meaningful private write, not necessarily an ephemeral value or a value transition.

Headless M4 has no Activity and no MediaBrowserService filter. Application-level fixup still registers callbacks/queries audio-app classification, but the examined Application onCreate alone does not send APP_LAUNCHED. High static confidence that M4 avoids this identified Activity-resume path; not a guarantee of zero OEM observer effects. Media-classified apps can receive additional audio/call callbacks; our harnesses omit that integration. Searches of available decompiled Java found only stockAA's receiver of this action, not an exhaustive binary coverage proof.

Grid/decoder Activities can trigger the same setter. M5's permission dialog may resume SystemUI even with a headless harness. Future logs correlate package-specific PID/time with AcuraLifecycleCallbacks, APP_LAUNCHED, GalPrefs, ActivityManager and detector logs; inspect preferences only if legitimately readable. Package hash/signature equality must never be described as private-data equality.

Separate new observation: package installation is detected by com.honda.maliciousdetector, independent of this Activity path. A headless Service does not prevent that warning history. See HONDA-UNAUTHORIZED-APP-WARNING.md; no suppression/bypass is proposed.
