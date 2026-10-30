# Temporary privileged execution: offline audit

Latest exact-platform assessment: [root versus non-root](ROOT-VS-NONROOT-AA-TEST.md), [recovery gate](RECOVERY-FIRST-PLAN.md) and [first-test designs](FIRST-LIVE-TEST-CANDIDATES.md). A partial structural policy inspection now finds system_app→default_prop allow-shaped records; effective authorization, shell setter reachability and helper execution remain unresolved. This does not establish a wrapper route or supersede the no-live-test decision. A newer receiver is optional.

2026-10-22. Updated after an authorized read-only collection of the seven existing service packages and public update root. No network, head-unit code execution, updater invocation, property writes, helper installation, debugging attach or process restart. Collection used package/path dumps, file listings/pulls and connectivity/build reads only. Target code and candidates remain unchanged. [Persistent deployment audit](DEPLOYMENT-PATHS.md).

## Current service audit: previously missing implementations examined

[Collection, signatures and detailed current-stack trace](current-update-stack/README.md). Seven complete active directories were collected; all packages verify with the same Windriver signer as AA, UID1000/shared-user android.uid.system. All seven APKs decompiled successfully. Their seven DEX method tables contain **no references to the audited dynamic DEX loader constructors/loadDex/startInstrumentation**; their manifests declare **no instrumentation**. Full [DEX audit](current-update-stack/dex-audit.json) and source-query evidence are retained. This is stronger scoped negative evidence, not a universal claim that privileged temporary execution is impossible.

| Requested capability | Current implementation finding |
| --- | --- |
| OEM-signed instrumentation harness | No instrumentation declaration/AA-targeting runner in any collected package. Shared signer alone does not create a runner or accept self-signed test code. |
| Safe wrapper/helper | No discovered AA helper or arbitrary wrap.* property-setting bridge. The existing Zygote property hook remains conditional on unresolved permissions, helper location, early injection and cleanup. |
| Existing privileged test runner | Diagnostics exposes vehicle/ECU/hardware diagnostic sessions and Bluetooth loopback tests; these do not execute arbitrary AA Java logic. |
| Signed code-loader | No caller-selected DEX/JAR loader identified. Fixed installed native libraries and RedBend reflection for its own UI/service classes do not replace a loaded HMI class. |
| Temporary app replacement/test mode | No scoped RAM-only replacement discovered. Factory/RedBend app copying is persistent; factory state transitions and rollback can alter configuration/partitions/reboot. |
| Alternate developer/test APK trust | All seven use production Windriver signing. No separate test APK certificate selector/allowlist found. Separate developer-image verification remains a different, risky image path with unresolved key/eligibility. |

**Validation mode is now resolved beyond an interface name:** current DiagnosticsService.enableValidationMode/disableValidationMode call FirewallController.setMoccaFirewallDisable/Enable, sending fixed ACS events to the MOST/MOCCA firewall. It does not enable JDWP, change debuggable or load Java. Permission checks are present on those DiagnosticsService methods. No validation function was called. Do not repeat prior validation/debug-target experiments as loader tests.

EngineeringAccessService now confirms the earlier interface interpretation: it forwards to DiagnosticsSessionControl for seed requests, activate/deactivate/refcount/refresh and response callbacks to supported diagnostic nodes. Transport similarly handles ECU inventory/programming/retrieve/apply flows, not generic AA execution. FactoryFlashing parses configuration and rewrites persistent database/app/hardware state. OTA is update UI/orchestration. HondaMiscellaneous controls MOST/error/camera/LCD behavior, not an AA plugin loader.

RedBend's freshly pulled APK differs from the earlier APK: AndroidManifest.xml and three signing entries changed. Its DEX and all other payload entries match; decoded manifest declarations are unchanged except platformBuildVersionName (`5.1.1-168` to `5.1.1-14`). Thus conclusions about non-exported ClientService, internal native-callable exec helper and protected incoming event bridge remain supported by current code/declarations. [Exact provenance](current-update-stack/redbend-provenance.json). Earlier draft whole-APK identity claims were incorrect. The newly collected public OTA root identifies delivery trust, not a signing key or temporary code-execution authority. Some bound-service manifest permissions are not repeated in every globally published Binder method; this does not establish a narrow execution route, and no direct Binder calls were tested.

**No live modified-APK test is proposed:** no concrete AA rollback has been documented. A factory enum named ROLLBACK switches update/partition state and reboots; an app-install failure can delete `/persistdata/app` recursively. Neither is a substitute for reverting an isolated AA process. Ranked temporary candidates remain conditional research options below; none is ready.

## Result

**No demonstrated shell-accessible way to execute our modified HMI logic inside AA's UID1000 process was found.** Two conditional mechanisms deserve focused prerequisite work: OEM-compatible signed instrumentation and the old framework's per-process `wrap.*` startup hook. Neither is ready for a live test. A protected directory on `/data`, a ClassLoader class, or a public service name is not itself an execution capability.

The most useful first test, if an authorized entry point is eventually established, would alter **only the AA process's in-memory configuration construction before GAL registration**, retain the original package/window settings, observe negotiation, and revert on process termination. Running the patched APK as shell in a separate app_process would not reproduce the privileged app environment. Running code in a different UID1000 process also does not change an already loaded HMIPresenter in AA.

## Scope and method

- Audited method-reference tables and relevant path strings across **102 unique pre-existing DEX files**, including nested archives: [summary](deployment-evidence/dex-loader-summary.json), [all results](deployment-evidence/dex-loader-audit.json). 32 contain runtime/loader references; three contain matching writable-path strings (including unrelated log/socket strings). A reference is not proof that a method is invoked or externally reachable.
- Read matching framework/services, AA, Diagnostics, Settings, Honda manager, app-fixup and Red Bend sources. Newly decompiled Honda `honda-lib.jar`, stock `monkey.jar`, and core StrictJarFile. Full source query output is retained under deployment-evidence, not just console excerpts.
- Inspected compiled SELinux context files, package inventory, framework symlink listing and native updater inventories. **The binary SELinux allow-rule database was not fully decoded**, and protected directory modes/ACLs are not established by context labels alone.
- This is an audit of available software, not every installed UID1000 app. The originally missing seven updater/diagnostics/miscellaneous implementations have now been collected and audited above. Effective private catalog/state, native recovery details and wrapper prerequisites remain gaps. Guava URLClassLoader, support-v4 LoaderManager and resource loaders are distinguished from arbitrary DEX plugin entry points.

## 1. Instrumentation

`ActivityManagerService.startInstrumentation()` (`decompiled/Services/sources/com/android/server/am/ActivityManagerService.java`) resolves an **installed instrumentation declaration**, resolves its target, compares target/helper package signatures and rejects mismatches before starting. The code accepts signature comparison result0 (match) or -1 (both unsigned); the signed AA target does not qualify for the both-unsigned case. There is no target-debuggable exception in this checked method.

If accepted it force-stops the target, creates the app process with instrumentation metadata and binds it. `ActivityThread.handleBindApplication()` loads the declared instrumentation class and calls onCreate; `LoadedApk.getClassLoader()` includes instrumentation and instrumented APK paths. `finishInstrumentationLocked()` force-stops the target again. Thus instrumentation is a process-lifetime code-injection mechanism **after** trust/declaration checks; it is not a read-only attach operation.

Findings:

- No ready, declared, OEM-compatible AA instrumentation runner or existing arbitrary-test-class loader was identified in the available manifests/package captures.
- `android.test.runner.jar` and `uiautomator.jar` contain test discovery/dex enumeration. Their existence does not install an instrumentation declaration targeting AA or bypass AMS signature checking.
- A newly self-signed helper cannot instrument signed AA merely because ADB starts it. Removing the helper later would not make its installation non-persistent during the test.
- An OEM-signed helper with a narrow, documented runner could be useful, but requires obtaining it and auditing its actual accepted arguments. No private signing key or qualifying helper is available.
- An instrumentation classpath can put helper code before target code, but parent-first resolution, preloaded classes, native JNI registration and singleton timing still matter. It does not automatically rewrite a loaded method. A deliberate pre-registration configuration hook is needed, not just adding a duplicate class to a later child loader.

**Status:** good conditional rollback model for in-memory changes; unavailable trust/entry prerequisites. Restart interrupts projection and requires future approval even if no APK is replaced.

## 2. Per-process wrapper: concrete old-framework hook

This build contains `ZygoteConnection.applyInvokeWithSystemProperty(Arguments)` at `decompiled/Framework/sources/com/android/internal/os/ZygoteConnection.java:455`:

[Code block omitted from public report; see authored source where available.]

For the normal AA process name, the exact derived property is **`wrap.com.honda.androidauto.proj`**. This is a statically derived key, not a property that was queried or set in this pass.

In `runOnce`, explicit peer invoke-with security checking occurs **before** applyInvokeWithSystemProperty. The checked method does not gate the property lookup on the target debuggable flag or ro.debuggable. Do not import newer Android wrapper assumptions into this old implementation. Explicit invoke-with supplied by a non-root Zygote peer is rejected; property-derived invocation is a separate branch.

`handleChildProc()` calls `WrapperInit.execApplication()` if the resulting wrapper exists. WrapperInit prefixes a command before `/system/bin/app_process ... com.android.internal.os.WrapperInit`, and the wrapper-started runtime reconnects through wrapperInit. This provides an actual process-start extensibility point, rather than an arbitrary Binder exec API.

Unresolved prerequisites and limits:

- Captured property_contexts has no `wrap.` prefix; the key falls under **default_prop**. Ability of shell/system_app to set it depends on property-service authorization and SELinux allow rules. That ability was **not** proved or tested. No generic privileged property-writing API for this key was identified in audited Settings/Diagnostics paths.
- This is not a `persist.*` key; conventional lifetime is in-memory property state until reboot, but clearing it is still required before a clean target restart. It would reapply on each process launch while set. **It does not inherently revert on AA process restart.** OEM init behavior/effective policy require evidence.
- Any wrapper executable/helper must be readable/executable under the child UID/domain and SELinux transition rules. `/data/local/tmp` is shell_data_file, not automatically executable/readable by system_app for this purpose. Need actual policy and permissions, not a path guess.
- A wrapper must preserve Binder application startup, JNI/library lookup, resources and classloader behavior while introducing a precise early hook. No wrapper or HMI injection implementation was built in this pass; setting a property alone is not that implementation.
- Properties are global by truncated key. Confirm the actual process name and avoid truncation collision before any plan. A bad wrapper can prevent AA startup. No system_server wrapper should be considered.

**Status:** most concrete newly identified temporary-execution research lead; no proven permission, complete implementation or tested rollback. Not an approved live test. Do not set the key, create a wrapper, restart AA or change ro.debuggable to explore it.

## 3. JDWP/debug setup

The prior bounded observation advertised no JDWP PIDs while AA PID2442 was alive before/after. Existing debug_app state/log port8100 is not a working debugger: matching framework Debug.changeDebugPort is empty, and AMS normally derives the Zygote debugger flag from manifest debuggable. No new device observation was made here.

Changing debug_app/restarting again has no new justification. No JVMTI hot-redefine capability was established for this Android5 ART runtime. A debugger/agent class in the SDK or libart symbol alone would not establish an attach permission or target runtime flag. No ptrace/JDWP injection attempted.

**Status:** unavailable on current evidence; process-memory rollback would be attractive only if a real authorized attach path existed.

## 4. Application class loaders and app_process

`ApplicationLoaders` constructs PathClassLoader from installed APK paths, native library paths and a parent. `LoadedApk.getClassLoader()` uses app/split paths, installed shared-library dependencies and, when authorized, instrumentation paths. It is not controlled by an arbitrary Activity extra containing a JAR path. `createPackageContext(...INCLUDE_CODE...)` does not change caller UID, and no discovered public AA endpoint uses it to load caller-selected executable code.

Parent-first ClassLoader behavior also means a child loader's class with the same HMIPresenter name is a separate type or resolves to the existing parent class; it does not replace an already loaded HMI singleton. Need a real in-process hook or a deliberately controlled classpath **before** class definition/GAL initialization.

Standalone app_process/classpath execution runs under the invoking identity unless some already authorized privileged launcher changes it. The shell does not acquire UID1000 from the copied manifest, source package, Context, or included framework classes. `ZygoteConnection.applyUidSecurityPolicy()` rejects arbitrary UID/GID specification by non-root/non-system peers; SELinux checks also apply. System-service identity is not obtained by choosing `--nice-name`.

**Status:** useful local/runtime building blocks, no privilege or injection entry point by themselves. No app_process command was run on the head unit.

## 5. Honda runtime fixup/plugin hooks

`com.honda.fixup.RunTimeFixup` constructs a PathClassLoader for the fixed **`/system/framework/com.honda.app-fixup.jar`** and resolves fixed `com.honda.appfixup.*` classes/method signatures supplied by framework wrappers. The local implementation handles application lifecycle/audio/Acura callbacks; AA is exempted from one audio lifecycle fixup. No external path, shell-provided method body or `/data` alternative found.

Zygote custom resource preload reads **`/system/etc/preloaded-custom-resources`**. A matching 489-byte packaged configuration in current framework.jar lists `/system/framework/com.honda.ui.jar:com.honda.ui.ResManager:preloadDrawables`. This packaged entry is not an independently pulled copy of the live `/system/etc` file. The hook can load configured Java at Zygote preload, but changing its protected configuration/JAR affects shared process ancestry and requires persistent changes/restart. It is not a safe AA-only temporary loader.

**Status:** real fixed OEM code hooks; no shell-writable substitute or temporary override found. Do not replace framework JARs or alter preload configuration.

## 6. Honda extension JARs through `/data/honda/lib`

Newly inspected `decompiled/HondaLib/sources/com/honda/auto/libmostcommon/most_init/FCatVerDetectionProxy.java` maps amplifier, terrestrial/satellite tuner, meter and HUD extensions to:

[Code block omitted from public report; see authored source where available.]

Captured `/system/framework` listing confirms generic extension JARs link into these paths. The proxy chooses fixed THRA/THRX, TJBA or TGVA files under `/system/framework` based on VCS/vehicle hardware detection, then its createSymlink helper executes `ln -sf` to provision the `/data` indirection and changes vcs.setup state. The destination is not a generic caller-supplied plugin parameter in this flow.

This is an actual code dependency indirection on a writable partition, but:

- Its SELinux type is **data_honda_lib_file**; shell write access is not established. A writable mount does not mean a writable protected directory/symlink target.
- Actual installed app/boot classpaths and which processes resolve each extension must be established separately. No identified extension is an AA HMI hook or proven member of AA's own classloader.
- Replacing an audio/vehicle extension would persist on disk, affect unrelated privileged consumers, require process reload and potentially interfere with hardware initialization. It is not memory-only or scoped to projection.
- Two local generic ampvcs copies are corrupt/non-ZIP artifacts; this does not establish that the device's actual symlink target is corrupt or identify its permissions. Variant JARs and original symlink listings remain distinct evidence.

**Status:** real infrastructure, unsuitable first-test candidate. No extension, symlink, VCS flag or property was changed.

## 7. Engineering, validation and diagnostics

- EngineeringAccess Binder methods register callbacks, activate/deactivate/refresh diagnostic-control sessions and query session state. The now-collected implementation forwards to DiagnosticsSessionControl vehicle-node operations; no arbitrary DEX/JAR loading or command method identified. This is not a claim that every native subsystem is exhausted.
- EnableValidationDebugActivity invokes DiagnosticsManager validation methods. Current implementation confirms they control the MOST/MOCCA firewall, not JDWP or code loading. Prior permission-denied query does not establish current validation state; do not toggle it again to discover a loader.
- Diagnostics MenuActivity reflects only package-prefixed classes from its menu definition; no discovered caller-selected JAR path. Its native/test calls are fixed-domain functions. Recognized command strings for logcat/dumpsys do not create a generic remote shell API.
- AA `aa.vetest`/VETestReceiver is vehicle-event simulation, not executable code loading or video configuration override. IntentController's simulation controls likewise do not load Java code. No broadcasts sent.
- DiagnosticsService and FactoryFlashingService are now collected. Their code confirms diagnostic-session/hardware operations and persistent factory configuration; no temporary AA loader was found. Their names, UID and any missing native detail do not justify mutating probes.

**Status:** no established temporary HMI route. Factory flashing, Compulsion Loading, VIN/config editing and validation toggles are not substitutes.

## 8. Red Bend test/debug/components and service APIs

BasicService loads only installed `smm_release`/`smm_debug` libraries. `persist.rb.debug` changes library selection, not a caller-selected native filename; it is persistent and not a reason to assume signature checks disappear. `swmDebug.txt` overrides test identity/environment values in Ipl, not arbitrary Java method bodies. No such file was created or used.

Ipl includes native-callable `execCommand(String)` / copyFiles / archive extraction/removal helpers. `execCommand` uses `sh -c` in the updater's process identity; this is a meaningful privileged native-to-Java operation, but **no shell-callable bridge reaching it with arbitrary arguments was established**. Java public/static visibility is not Binder export. Complete native input reachability/eligibility remains a gap; it must not be represented as a ready exec endpoint.

ClientService is non-exported. EventIntentService registers its dynamic event bridge with signatureOrSystem `com.redbend.client.permission.EVENT_INTENT`. ReceiverEvent accepts serialized Honda OTA events behind `auto.permission.SOFTWARE_UPDATE_SERVICE`. Exported DeviceUpdateReceiver maps recognized polling/start/check actions to fixed internal events; it does not expose arbitrary installer/code arguments. Other exported boot/network/UI receivers do not inherently expose the native generic installer. No update events were sent.

`software_update`, `update_transport` and `swupdate` expose privileged state/update operations. The newly collected software_update/update_transport Java implementations confirm update orchestration and ECU programming, with no identified arbitrary in-process AA method invocation. Native updater processes, even UID1000, are separate address spaces; executing shell there would not alone replace loaded AA code. Current native recovery/private state remains incomplete, and there is no safe basis to probe writes.

**Status:** powerful internal machinery, no authenticated temporary AA code route established. Debug/test artifacts are not permission or rollback mechanisms.

## 9. Other local loaders ruled out as direct routes

| Mechanism | Actual local use / constraint |
| --- | --- |
| Stock monkey DexClassLoader | MonkeySourceNetworkViews loads an **installed package's** `<package>.R$id` using sourceDir and `/data/local/tmp` as optimization output. It runs in the monkey process, not AA; this does not elevate shell or replace HMI. |
| FilterFactory.addFilterLibrary | Framework PathClassLoader used by TextGraphReader's graph library command. No audited AA/UID1000 public graph-input endpoint reaches it with arbitrary code. A framework facility is not a standalone Binder loader. |
| WebView provider APK / shared RELRO | WebViewFactory explicitly throws for UID0/1000. Provider class is selected from a framework resource/installed package; RELRO under `/data/misc/shared_relro` is not arbitrary Java injection. |
| Diagnostics Guava URLClassLoader | Finalizer helper/classpath enumeration; resource-derived class location, no discovered exported arbitrary JAR argument. |
| system_server extensibility | Zygote uses SYSTEMSERVERCLASSPATH; SystemServiceManager loads configured existing classes, not an arbitrary Binder-supplied JAR. Protected startup/classpath changes and service failure risk are broad. |
| Normal `/data/app` / `/persistdata/app` package code | Real executable-code paths with PackageManager/trusted-provisioning rules; persistent APK storage, not memory-only injection. See deployment report. |

The pulled `init.rc` and `init.environ.rc` placeholders are **zero bytes**. They are not evidence of the live service/classpath/environment definitions. Framework code shows use of environment variables, but the effective on-device classpath must be acquired separately.

## Ranked temporary candidates and rollback

| Rank | Candidate | What is missing | Risk / rollback |
| --- | --- | --- | --- |
| 1 | Purpose-built OEM-signed instrumentation/helper limited to AA | Compatible installed declaration/signer; early hook; cleanup plan | Moderate if qualified. Memory changes end with process; helper installation/removal and normal app data are separate persistence concerns. |
| 2 | AA-specific wrap.* startup hook | Proven property permission/SELinux policy, allowed helper location, audited startup wrapper/hook and collision check | Moderate/high until established. Package can remain intact; property/helper must be restored before a clean restart. Not automatically process-restart reversible. |
| 3 | Real authorized JDWP/agent attachment | Actual debug-enabled/attachable target; current evidence negative | Good memory rollback in principle, unavailable here. Do not repeat failed debug_app setup. |
| 4 | Honda extension/fixup substitution | Protected write/consumer reachability plus AA hook; broad side effects | High/poor: persistent shared infrastructure, excluded as first test. |
| 5 | Generic updater/diagnostic command invocation | No proven reachable authorized arbitrary execution endpoint | Unqualified, potentially high risk; not a test plan. |

None is executable under present evidence/authorization. Before a future temporary test, require a narrow entry point, known process UID/domain, pre-GAL timing, preserved original APK/native dependencies, an explicit way to stop/remove the hook, and evidence that AA can restart normally without relying on a broken runtime to undo it. No head-unit commands are provided or executed here.
