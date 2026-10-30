$ErrorActionPreference='Stop'
$root='./analysis/parallel-aa-receiver/live-test-01'
function Read-Evidence([string]$name){[IO.File]::ReadAllText((Resolve-Path -LiteralPath "$root/$name.stdout.txt"))}
function Hash([string]$path){(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
function Get-Properties([string]$name){
    $map=@{}
    foreach($line in ((Read-Evidence $name)-split"`n")){
        if($line-match'^\[([^]]+)\]: \[(.*)\]'){$map[$Matches[1]]=$Matches[2]}
    }
    return $map
}
$commands=@(Get-ChildItem "$root/*.command.json"|ForEach-Object {Get-Content $_.FullName -Raw|ConvertFrom-Json}|Sort-Object utc)
$mutations=[Collections.Generic.List[object]]::new()
foreach($record in $commands){
    $a=@($record.arguments)
    if($a[0]-eq'devices'){continue}
    if($a[0]-ne'-s' -or $a[1]-ne'00000000'){throw 'Unexpected device target'}
    if($a[2]-eq'install'){
        if($a.Count-ne4 -or $a[3]-ne'./analysis/parallel-aa-receiver/build/rdx-parallel-aa-0.1.0-development.apk'){throw 'Unexpected install'}
        $mutations.Add($record);continue
    }
    if($a[2]-eq'uninstall'){
        if($a.Count-ne4 -or $a[3]-ne'com.rdx.fullscreen.projection'){throw 'Unexpected uninstall'}
        $mutations.Add($record);continue
    }
    if($a[2]-eq'logcat' -and $a[3]-eq'-d'){continue}
    if($a[2]-eq'pull'){continue}
    if($a[2]-eq'shell'){
        if($a[3]-in'dumpsys','getprop','ps','cat','ls'){continue}
        if($a[3]-eq'pm' -and $a[4]-eq'path'){continue}
        if($a[3]-eq'settings' -and $a[4]-eq'list'){continue}
        if(($a[3..($a.Count-1)]-join' ')-in'am start -W -n com.rdx.fullscreen.projection/.ReceiverActivity','am force-stop com.rdx.fullscreen.projection'){$mutations.Add($record);continue}
    }
    throw "Unclassified command: $($a-join' ')"
}
$before=Get-Properties 'pre-properties';$after=Get-Properties 'post-properties'
$changes=@(foreach($key in @($before.Keys|Sort-Object)){if($before[$key]-ne$after[$key]){[pscustomobject]@{property=$key;before=$before[$key];after=$after[$key]}}})
$stockHash=Hash "$root/stock-before.apk"
if($stockHash-ne(Hash "$root/stock-after.apk") -or $stockHash-ne(Hash './apks/AndroidAuto-current-2026-10-22.apk')){throw 'Stock APK differs'}
if((Read-Evidence 'pre-stock-package')-cne(Read-Evidence 'post-stock-package')){throw 'Stock package dump changed'}
if((Read-Evidence 'pre-window')-cne(Read-Evidence 'post-window')){throw 'Window dump changed'}
if((Read-Evidence 'post-custom-path').Trim() -or (Read-Evidence 'post-custom-package').Trim()){throw 'Custom package remains registered'}
if((Read-Evidence 'post-processes')-match'com\.rdx\.fullscreen\.projection'){throw 'Custom process remains'}
if((Read-Evidence 'uninstall').Trim()-ne'Success'){throw 'Uninstall not successful'}
$bootBefore=[regex]::Match((Read-Evidence 'pre-uptime'),'[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}').Value
$bootAfter=[regex]::Match((Read-Evidence 'post-uptime'),'[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}').Value
if(-not$bootBefore -or $bootBefore-ne$bootAfter){throw 'Boot identity changed/unavailable'}
$build=Get-Content './analysis/parallel-aa-receiver/build/build-report.json' -Raw|ConvertFrom-Json
if((Hash "$root/installed-base.apk")-ne$build.outputSHA256){throw 'Installed APK differs from approved artifact'}
$postLog=Read-Evidence 'post-logcat'
$important=@($postLog-split"`n"|Where-Object {$_-match'com\.rdx\.fullscreen\.projection|Attempted Lock Task Mode violation|Non-authorized third party package installed'})
$important|Set-Content "$root/relevant-log-extract.txt"
$result=[ordered]@{
    scope='First live test, synthetic-only launch attempt; no phone/GAL/native initialization/decoder/overscan'
    startUtc=$commands[0].utc;endUtc=$commands[-1].endUtc;commandCount=$commands.Count
    stateChangingCommands=@($mutations|Select-Object name,arguments,exitCode)
    target='2021 Acura RDX D.1.6.4/API22/armeabi-v7a'
    prototype=@{package='com.rdx.fullscreen.projection';UID=10049;processSELinuxDomain='NOT OBSERVED: launch denied before process start';codePath='/data/app/com.rdx.fullscreen.projection-1';nativeLibraryDir='/data/app/com.rdx.fullscreen.projection-1/lib/arm';requestedPermissions=@();versionName='0.1.0-experimental-offline';versionCode=1;APK_SHA256=$build.outputSHA256;signerSHA256=$build.developmentSignerSHA256}
    milestones=@{M0='PASS: ordinary install and separate UID';M1='BLOCKED: ActivityManager Lock Task Mode violation';M2='NOT REACHED: baseline app display1339x720, custom Surface absent';M3='NOT TESTED: existing native control also initializes GAL';M4plus='NOT AUTHORIZED / NOT RUN'}
    firstBoundary=@{amResult=5;amShellExitCode=0;log='Attempted Lock Task Mode violation';currentTask=2;rootComponent='com.honda.auto.diagnostics/.dealer.MainActivity';foreground='com.honda.auto.diagnostics/.developer.USBModeSwitchActivity';appProcessStarted=$false;noRootConclusion='Normal diagnostic exit statically calls stopLockTask; not invoked by this test'}
    display=@{physical='1920x720';baselineApp='1339x720';densityDpi=160;physicalXDpi=200.0;physicalYDpi=200.0;refreshRate=57.000004;rotation=0;customSurface='NOT CREATED';prePostWindowDumpIdentical=$true;overscanChangedByTest=$false;baselineOverscanScreen='(0,0) 1339x720'}
    cleanup=@{uninstallSuccess=$true;packageAbsent=$true;processAbsent=$true;pathsReportedAbsent=@('/data/app/com.rdx.fullscreen.projection-1','/data/data/com.rdx.fullscreen.projection','/data/local/tmp/rdx-parallel-aa-0.1.0-development.apk');appExit='No running Activity to exit; own-package force-stop then uninstall';bootIDUnchanged=$true;bootID=$bootBefore}
    stock=@{APK_SHA256=$stockHash;prePostAndPreservedAPKIdentical=$true;packageDumpIdentical=$true;codePath='/system/app/AndroidAuto';UID=1000;versionCode=22;versionName='5.1.1-14';signerSHA256='2156c50e3c08347f28adccb49ae839394053a45767f153bd8f036ae33d5f8568';processPIDBeforeAfter=2440;privateData='Not inspected/written by test; byte-for-byte private data immutability not asserted'}
    properties=@{directWritesByTest=@();observedDifferences=$changes;note='Ambient settings-version counter and temperature changed; do not claim whole-system property equality'}
    settings=@{directWritesByTest=@();baselineEnumeration='settings list unsupported; printed usage only';note='No full settings comparison available; no setting/property mutator was invoked'}
    observedAppDenials='Lock Task Mode launch rejection. No app process, no custom permission/JNI/SELinux exercise. No AVC or Permission Denial line in captured logcat.'
    OEMObservers='Installation/removal triggered normal package monitors, launcher bookkeeping and read-only GET_VANILLA_STATE in OEM services; no updater operation invoked by agent'
    limitations=@('No functional factory phone projection retest, phone remained disconnected','No custom process domain, Surface, app DisplayMetrics or native-load evidence','No forensic proof of all system/persistdata/private-data bytes; command audit has no writes there','OS PackageManager/launcher records and logs are not byte-for-byte restored by uninstall')
    next='Offline lock-task/diagnostic normal-exit review, then separately authorized repeat Surface test from normal UI; no USB/GAL yet'
}
$result|ConvertTo-Json -Depth 9|Set-Content "$root/summary.json"
$commands|ConvertTo-Json -Depth 6|Set-Content "$root/commands.json"
$hashes=@(Get-ChildItem -LiteralPath $root -File|Where-Object {$_.Name-ne'evidence-hashes.json'}|ForEach-Object {[pscustomobject]@{name=$_.Name;bytes=$_.Length;sha256=Hash $_.FullName}})
$hashes|ConvertTo-Json -Depth 4|Set-Content "$root/evidence-hashes.json"
[pscustomobject]@{commands=$commands.Count;mutatingCommands=$mutations.Count;M0='PASS';M1='LOCK TASK BLOCKED';uninstall='SUCCESS';stockAndWindowUnchanged=$true;propertyChanges=$changes;rawEvidenceFiles=$hashes.Count}|ConvertTo-Json -Depth 5
