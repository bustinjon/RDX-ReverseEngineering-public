$ErrorActionPreference='Stop'
$r='./analysis/parallel-aa-receiver/live-test-02'
function Read([string]$name){[IO.File]::ReadAllText((Resolve-Path "$r/$name.stdout.txt"))}
function Hash([string]$p){(Get-FileHash -LiteralPath $p).Hash}
function Props([string]$name){$m=@{};foreach($l in ((Read $name)-split"`n")){if($l-match'^\[([^]]+)\]: \[(.*)\]'){$m[$Matches[1]]=$Matches[2]}};return $m}
$cmds=@(Get-ChildItem "$r/*.command.json"|ForEach-Object {Get-Content $_.FullName -Raw|ConvertFrom-Json}|Sort-Object utc)
$changes=@(foreach($c in $cmds){
    $a=@($c.arguments)
    if($a[0]-eq'devices'){continue}
    if($a[0]-ne'-s' -or $a[1]-ne'00000000'){throw 'Unexpected device'}
    $tail=$a[2..($a.Count-1)]-join' '
    if($tail -in 'shell input tap 1230 50','shell input tap 1150 104','shell am start -W -n com.rdx.fullscreen.projection/.ReceiverActivity','uninstall com.rdx.fullscreen.projection','install ./analysis/parallel-aa-receiver/live-test-02/prototype/build/rdx-parallel-aa-0.1.1-live02-synthetic.apk'){$c;continue}
    if($a[2]-eq'shell' -and $a[3]-in'dumpsys','getprop','ps','cat','ls'){continue}
    if($a[2]-eq'shell' -and $a[3]-eq'pm' -and $a[4]-eq'path'){continue}
    if($a[2]-eq'pull' -or ($a[2]-eq'logcat' -and $a[3]-eq'-d') -or $tail-eq'exec-out screencap -p'){continue}
    throw "Unclassified command $tail"
})
$app=Read 'running-custom-log';$exited=Read 'after-app-exit-log'
foreach($required in 'uid=10050 pid=30513','Surface available=1339x720 valid=true','M1 synthetic Canvas posted','M1 synthetic texture update observed','WINDOW surfaceAvailable decor=1339x720'){
    if(-not$app.Contains($required)){throw "Missing runtime evidence $required"}
}
foreach($required in 'Exit button: finish only our Activity','Activity onDestroy','Surface destroyed'){if(-not$exited.Contains($required)){throw 'Missing clean exit evidence'}}
if((Read 'launch')-notmatch'Status: ok' -or (Read 'running-processes')-notmatch'u:r:untrusted_app:s0\s+u0_a50\s+30513'){throw 'Launch/domain not demonstrated'}
if((Read 'post-custom-path').Trim() -or (Read 'post-custom-package').Trim() -or (Read 'post-processes')-match'com\.rdx\.fullscreen\.projection'){throw 'Custom remains'}
if((Read 'uninstall').Trim()-ne'Success'){throw 'Removal failed'}
if((Read 'pre-stock-package')-cne(Read 'after-exit-stock-package') -or (Read 'pre-stock-package')-cne(Read 'post-stock-package')){throw 'Stock PM state differs'}
$stockHash=Hash "$r/stock-before.apk"
if($stockHash-ne(Hash "$r/stock-after.apk") -or $stockHash-ne(Hash './apks/AndroidAuto-current-2026-10-22.apk')){throw 'Stock APK changed'}
$build=Get-Content "$r/prototype/build/build-report.json" -Raw|ConvertFrom-Json
if($build.sha256-ne(Hash "$r/installed-base.apk")){throw 'Installed artifact differs'}
$pre=Props 'pre-properties';$base=Props 'after-exit-properties';$post=Props 'post-properties'
$propertyChanges=@(foreach($key in @($base.Keys|Sort-Object)){if($base[$key]-ne$post[$key]){[pscustomobject]@{key=$key;postDiagnosticBaseline=$base[$key];afterTest=$post[$key]}}})
$exitPropertyChanges=@(foreach($key in @($pre.Keys|Sort-Object)){if($pre[$key]-ne$base[$key]){[pscustomobject]@{key=$key;beforeExit=$pre[$key];afterExit=$base[$key]}}})
$bootBefore=[regex]::Match((Read 'pre-boot'),'[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}').Value
$bootAfter=[regex]::Match((Read 'post-boot'),'[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}').Value
if(-not$bootBefore -or $bootBefore-ne$bootAfter){throw 'Boot identity differs'}
$geometry=@(foreach($name in 'after-exit-window','post-window'){
    [pscustomobject]@{source=$name;overscanScreen=[regex]::Match((Read $name),'mOverscanScreen=[^\r\n]+').Value;unrestrictedScreen=[regex]::Match((Read $name),'mUnrestrictedScreen=[^\r\n]+').Value;stable=[regex]::Match((Read $name),'mStable=[^\r\n]+').Value;dimensions=[regex]::Match((Read $name),'init=[^\r\n]+').Value}
})
foreach($field in 'overscanScreen','unrestrictedScreen','stable','dimensions'){if($geometry[0].$field-cne$geometry[1].$field){throw 'Display geometry differs'}}
$log=Read 'post-logcat'
$extract=@($log-split"`n"|Where-Object {$_-match'RDX\.ParallelAA|com\.rdx\.fullscreen\.projection|dealer.Main.*finish|stopLockTaskMode|leaveDiagMode|storeShouldAAAutoStartPref|Another app started|avc:|OpenGLRenderer.*Failed to choose'})
$extract|Set-Content "$r/relevant-log-extract.txt"
$observations=[ordered]@{
    scope='Live test02 complete; no phone/native/GAL/USB transport/decoder/overscan';startUtc=$cmds[0].utc;endUtc=$cmds[-1].endUtc
    commands=$cmds.Count;stateChangingCommands=@($changes|Select-Object name,arguments,exitCode)
    diagnostics=@{initialTask=2;root='com.honda.auto.diagnostics/.dealer.MainActivity';foreground='com.honda.auto.diagnostics/.developer.USBModeSwitchActivity';normalExit='Four UI RETURN taps, each verified against Activity/View hierarchy';exitExecuted=$true;runtimeStopLockTaskLogged=$true;diagModeTransitions='2->dealer1, then dealer1->0 via normal destruction';afterExit='com.honda.tjba.launcher/.ui.HomeActivity';ADBsurvived=$true;devAdbBefore=$pre['dev.adb'];devAdbAfterExit=$base['dev.adb'];devAdbAfterTest=$post['dev.adb'];USBConfig=$post['sys.usb.config'];noDeveloperToggleOrUSBModeSelection=$true}
    artifact=@{version='0.1.1-live02-synthetic';versionCode=2;UID=10050;PID=30513;domain='u:r:untrusted_app:s0';codePath='/data/app/com.rdx.fullscreen.projection-1';nativeLibraryDir='/data/app/com.rdx.fullscreen.projection-1/lib/arm';ABI='armeabi-v7a';permissions=@();sharedUID=$null;APK_SHA256=$build.sha256;signerSHA256='c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831';nativeIncludedNeverLoaded=$true;credentialsIncluded=$false;originalPrototypeUnchanged=$true}
    milestones=@{M0='PASS again';M1='PASS: launch, Canvas post, texture update and screenshot';M2='PASS: own Surface/decor/resources1339x720';M3='DEFERRED: library load constructors not proved inert; no load-only control added or executed';M4plus='NOT AUTHORIZED / NOT RUN'}
    metrics=@{surface='1339x720';decor='1339x720';visibleFrame='[0,0][1339,720]';resourceMetrics='1339x720';displayGetMetrics='1339x720';displayGetRealMetrics='1339x720';displayGetRealSize='1920x720';physicalDisplay='1920x720';densityDpi=160;density=1.0;scaledDensity=1.0;xdpi=200.0;ydpi=200.0;orientation='landscape (2), rotation0';refreshHz=57.000004;getRealMetricsQualification='Saved vendor Display.java intentionally calls getAppMetrics; realSize uses logicalWidth/logicalHeight. Preserve this observed distinction.'}
    M3Safety=@{JNIOnLoad='No exported symbol found';DTInit='No DT_INIT in saved dynamic table';initArrayVA='0x1C6EF8';initArrayBytes=12;entries=@('R_ARM_ABS32 OPENSSL_cpuid_setup','R_ARM_RELATIVE Thumb0xBB359, code0xBB358','R_ARM_RELATIVE Thumb0xBBCE9, code0xBBCE8');gate='Unnamed constructors and transitive dependency startup not fully traced';decision='No probe, no native execution'}
    cleanup=@{cleanActivityExit=$true;onDestroy=$true;surfaceDestroyed=$true;uninstallSuccess=$true;packageAbsent=$true;processAbsent=$true;codeDataAndTemporaryAPKAbsent=$true;noForceStopNeeded=$true;bootUnchanged=$true;geometry=$geometry;settingsAndPropertyWritesByAgent=@();postDiagnosticPropertyDifferences=$propertyChanges;normalExitPropertyDifferences=$exitPropertyChanges}
    stock=@{packageDumpIdentical=$true;APK_SHA256=$stockHash;signerSHA256='2156c50e3c08347f28adccb49ae839394053a45767f153bd8f036ae33d5f8568';version='22/5.1.1-14';UID=1000;PID=2440;path='/system/app/AndroidAuto';codeUnchanged=$true;privateDataUnchanged='NOT CLAIMED';observedOEMCallback='At20:56:08.238 stock GalService received ordinary lifecycle APP_LAUNCHED and called StartPreferences.setShouldAAAutoStartPref(false), key gal_should_auto_start in gal_start_preferences using commit. A prior false setter is logged at20:54:29.398 before our install. Physical XML/value before/after not compared; may be same-value commit. No agent/helper write or rollback attempted.'}
    diagnosticsAndWarnings=@{appCrash='None found';appPermissionOrAVCDenial='None observed for30513/untrusted_app';shellAVC='shell->adbd unix_stream_socket ioctl0x5401 denied during command execution';procMaps='Read-only shell cat denied; no privilege workaround';GL='EGL_SWAP_BEHAVIOR_PRESERVED config retry warning; rendering succeeded';OEM='Non-authorized third-party/metadata/resource warnings from observers did not block launch';JNI='Not exercised; no successful linker result claimed'}
    next='Offline constructor safety and lifecycle side-effect review, then separately scoped local GAL initialization/USB permission/ownership stages; none executed'
    modelRecommendation='GPT-6 Astra Medium for next cross-layer native/ownership analysis; Sol High remains suitable for routine bounded collection/build. Judgment, not benchmark/equivalence claim.'
}
$observations|ConvertTo-Json -Depth 10|Set-Content "$r/summary.json"
$cmds|ConvertTo-Json -Depth 6|Set-Content "$r/commands.json"
$hashes=@(Get-ChildItem -LiteralPath $r -File|Where-Object Name -ne 'evidence-hashes.json'|ForEach-Object {[pscustomobject]@{name=$_.Name;bytes=$_.Length;sha256=Hash $_.FullName}})
$hashes|ConvertTo-Json -Depth 4|Set-Content "$r/evidence-hashes.json"
[pscustomobject]@{commandCount=$cmds.Count;stateChangingCommands=$changes.Count;M1='PASS';M2='PASS';M3='DEFERRED';UID=10050;domain='untrusted_app';uninstalled=$true;stockCodePreserved=$true;stockPrivateDataEquality='Not claimed: observed OEM setter';geometryUnchanged=$true;evidenceFiles=$hashes.Count}|ConvertTo-Json
