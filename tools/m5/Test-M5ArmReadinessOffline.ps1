param([Parameter(Mandatory=$true)][string]$OutputDirectory)
$ErrorActionPreference='Stop';$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. "$PSScriptRoot/M5ArmReadiness.ps1"
if(Test-Path -LiteralPath $OutputDirectory){throw 'Fresh offline test directory required'}
New-Item -ItemType Directory -Path "$OutputDirectory/fixtures" -Force|Out-Null
$OutputDirectory=(Resolve-Path $OutputDirectory).Path;$fixtures="$OutputDirectory/fixtures"
$saved=@{
 'diagnostics-activities.txt'='analysis/parallel-aa-receiver/warning-phonefree-20261025-190517/20261025-190548-460-activities.stdout.txt'
 'diagnostics-window.txt'='analysis/parallel-aa-receiver/warning-phonefree-20261025-190517/20261025-190548-240-window.stdout.txt'
 'home-activities.txt'='analysis/parallel-aa-receiver/live-test-02/after-exit-activities.stdout.txt'
 'home-window.txt'='analysis/parallel-aa-receiver/live-test-02/after-exit-window.stdout.txt'
 'display.txt'='analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/before/display.txt'
 'fresh-package.txt'='analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/m5-installed-package.txt'
}
foreach($name in $saved.Keys){Copy-Item -LiteralPath "$root/$($saved[$name])" -Destination "$fixtures/$name"}
$raw=Get-Content "$root/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128/reconnect-logcat.txt" -Raw
$extract=@($raw-split'[\r\n]+'|Where-Object {$_-match'^10-25 19:31:(30\.(671|682)|32\.577).*?(ActivityManager|dealer.Main)'})-join"`n"
$extract|Set-Content "$fixtures/rejected-ui-log.txt"
[ordered]@{savedInputs=$saved;logSource='m5-live-retry-20261025-185128/reconnect-logcat.txt';logFilter='10-25 19:31:30.671,30.682,32.577 ActivityManager/dealer.Main';synthetic='All Parcel replies, clocks, identity combinations and readiness sequences are synthetic; no saved runtime getter reply exists.'}|ConvertTo-Json -Depth 4|Set-Content "$fixtures/provenance.json"
$passive="Result: Parcel(00000000 00000000   '........')";$active="Result: Parcel(00000000 00000001   '........')"
$base=[ordered]@{startMs=0L;endMs=100L;lockBefore=$passive;lockAfter=$passive;activities=Get-Content "$fixtures/home-activities.txt" -Raw;window=Get-Content "$fixtures/home-window.txt" -Raw;display=Get-Content "$fixtures/display.txt" -Raw;package=Get-Content "$fixtures/fresh-package.txt" -Raw;services='ACTIVITY MANAGER SERVICES';processes='USER PID NAME';packages="package:com.rdx.fullscreen.m5permission`npackage:com.honda.androidauto.projection.sink"}
$facts=Get-M5PackageFacts $base.package;$proof=[pscustomobject]@{uid=$facts.uid;firstInstallTime=$facts.firstInstallTime;lastUpdateTime=$facts.lastUpdateTime}
$cases=[Collections.Generic.List[object]]::new();$script:checks=0
function Check([bool]$Condition,[string]$Name){$script:checks++;if(-not$Condition){throw "OFFLINE TEST FAILED: $Name"};$cases.Add([pscustomobject]@{name=$Name;PASS=$true})}
function Samples([long]$Duration=5000){
 $list=[Collections.Generic.List[object]]::new()
 $ticks=@(for($i=0L;$i-le$Duration;$i+=500){$i});if($ticks[-1]-ne$Duration){$ticks+=$Duration}
 foreach($i in $ticks){$copy=[ordered]@{};foreach($k in $base.Keys){$copy[$k]=$base[$k]};$copy.startMs=$i;$copy.endMs=$i+100;$list.Add([pscustomobject]$copy)}
 return ,$list.ToArray()
}
Check ((Get-M5LockTaskState $active)-eq'ACTIVE') 'synthetic active Parcel'
Check ((Get-M5LockTaskState $passive)-eq'INACTIVE') 'synthetic inactive Parcel'
Check ((Get-M5LockTaskState "Result: Parcel(`n0x00000000: 00000000 00000000 '........'`n)")-eq'INACTIVE') 'multiline reply'
foreach($bad in @('','Result: Parcel(NULL)','Permission denied',"Result: Parcel(00000000 00000002 '........')","Result: Parcel(00000001 00000000 '........')","Result: Parcel(00000000 00000000 00000000 '............')",($passive+' trailing'))){Check ((Get-M5LockTaskState $bad)-eq'UNKNOWN') ('ambiguous Parcel '+$bad)}
Check $facts.fresh 'saved fresh package flags/version/ordinary UID'
Check (-not(Get-M5PackageFacts ($base.package-replace'enabled=0','enabled=2')).fresh) 'disabled M5 package (enabled=2) is not fresh'
Check ((Get-M5Foreground $base.activities $base.window)-eq($script:M5Home+' task=1')) 'saved Honda Home foreground; not proof of inactive lock'
Check (-not(Get-M5Foreground (Get-Content "$fixtures/diagnostics-activities.txt" -Raw) (Get-Content "$fixtures/diagnostics-window.txt" -Raw))) 'saved Diagnostics foreground refused independently'
Check (Test-M5Geometry $base.window $base.display) 'saved stable geometry and density'
foreach($duration in @(500,1900,2000,3000,5000)){$seq=Samples $duration;$a=Get-M5WindowAssessment $seq $proof ($seq[-1].endMs) 5;Check ($a.ready-eq($duration-ge5000)) "fake-time $duration ms"}
$seq=Samples;Check ((Get-M5WindowAssessment $seq $proof 5100).ready) 'synthetic stable CHECK A/B allowed'
$seq[5].lockAfter=$active;Check (-not(Get-M5WindowAssessment $seq $proof 5100).ready) 'inactive then active refused'
$seq=Samples;$seq[0].lockBefore=$active;$seq[7].lockAfter='unknown';Check (-not(Get-M5WindowAssessment $seq $proof 5100).ready) 'active inactive unknown refused'
foreach($scenario in @('transition','diagnostics-ambiguous','already-armed','project-service','project-process','m6-installed','geometry','capture-slow','gap','clock-regressed','foreground-task-change','stale','missing-service-dump','missing-process-dump','error-package-list','package-disabled-enabled2','package-disabled-component','process-error-text','service-error-text')){
 $seq=Samples
 switch($scenario){
  transition{$seq[6].lockAfter=$active}
  diagnostics-ambiguous{$seq[6].activities=Get-Content "$fixtures/diagnostics-activities.txt" -Raw;$seq[6].lockAfter=''}
  already-armed{$seq[6].package=$base.package-replace'notLaunched=true','notLaunched=false'}
  project-service{$seq[6].services='ServiceRecord{123 u0 com.rdx.fullscreen.m5permission/.PermissionService}'}
  project-process{$seq[6].processes='u0_a49 8902 com.rdx.fullscreen.m5permission'}
  m6-installed{$seq[6].packages+="`npackage:com.rdx.fullscreen.m6aoa"}
  geometry{$seq[6].window=$base.window-replace'mStable=\(0,0\)-\(1339,720\)','mStable=(0,0)-(1920,720)'}
  capture-slow{$seq[6].endMs=$seq[6].startMs+2001}
  gap{$seq=@($seq[0],$seq[-1])}
  clock-regressed{$seq[6].startMs=-1}
  foreground-task-change{$seq[6].activities=$base.activities-replace' t1\}',' t2}'}
  missing-service-dump{$seq[6].services=''}
  missing-process-dump{$seq[6].processes=''}
  error-package-list{$seq[6].packages+="`nError: unknown argument"}
  package-disabled-enabled2{$seq[6].package=$base.package-replace'enabled=0','enabled=2'}
  package-disabled-component{$seq[6].package=$base.package+"`n      disabledComponents:`n        com.rdx.fullscreen.m5permission.PermissionService"}
  process-error-text{$seq[6].processes="USER PID NAME`nPermission denied"}
  service-error-text{$seq[6].services="ACTIVITY MANAGER SERVICES`nDUMP TIMEOUT"}
 }
 $now=5100L;if($scenario-eq'stale'){$now=7001}
 Check (-not(Get-M5WindowAssessment $seq $proof $now).ready) "scenario $scenario"
}
$fp='Acura/gen1CBD_HS/gen1CBD_HS:5.1.1/LMY48P/14:user/release-keys'
Check (Get-M5IdentitySafe '00000000' $fp '22' '5.1.1' 'armeabi-v7a') 'expected identity'
Check (-not(Get-M5IdentitySafe 'other' $fp '22' '5.1.1' 'armeabi-v7a')) 'wrong target'
Check (-not(Get-M5IdentitySafe '00000000' $fp '23' '5.1.1' 'armeabi-v7a')) 'API mismatch'
$r=[pscustomobject]@{schema=1;result='READY_TO_ARM';runId='synthetic';serial='00000000';apkSHA256=$script:M5FrozenHash;stabilizationSeconds=5;sampleCount=11;createdMs=5100L;lastSampleStartMs=5000L}
Check (Test-M5ReadinessFresh $r 'synthetic' '00000000' 5100) 'immediately before arm freshness'
Check (-not(Test-M5ReadinessFresh $r 'synthetic' '00000000' 7001)) 'stale result hard refusal'
$r.apkSHA256='BAD';Check (-not(Test-M5ReadinessFresh $r 'synthetic' '00000000' 5100)) 'artifact mismatch refusal';$r.apkSHA256=$script:M5FrozenHash
Check (-not(Test-M5ReadinessFresh $r 'other' '00000000' 5100)) 'wrong run result refused'
$ui=Get-M5PermissionUiEvidence $extract;Check ($ui.blocked-and$ui.permissionActivityAttempted) 'saved actual launch/rejection recognized'
$model=[ordered]@{prior=@('LOCK_TASK_ACTIVE','REQUEST_PERMISSION','UI_ATTEMPT','UI_REJECTED','LOCK_TASK_EXITS_1895_MS_LATER','NO_CALLBACK','REENUMERATION','DETACHED');desired=@('LOCK_TASK_ACTIVE','MANUAL_NORMAL_RETURN','INACTIVE','OBSERVED_STABLE_5000_MS','GUARD_READY','ARM','PHONE_APPEARS','REQUEST_PERMISSION','UI_LAUNCH_ELIGIBLE_NOT_GUARANTEED');scope='HOST CAUSAL MODEL ONLY; no permission request executed'}
$model|ConvertTo-Json -Depth 5|Set-Content "$OutputDirectory/failure-race-model.json"
$historical='ActivityManager: Attempted Lock Task Mode violation r=ActivityRecord{old com.android.systemui/.usb.UsbPermissionActivity}'
$log=$historical+"`nRDX.M5 run=future event=ARMED`nActivityManager START cmp=com.android.systemui/.usb.UsbPermissionActivity`nRDX.M5 run=future event=SERVICE_END"
$ui=Get-M5PermissionUiEvidence $log 'future';Check ($ui.runScoped-and-not$ui.blocked) 'old rejection excluded from new run scope'
# Independent oracle: safe iff no injected violation and sufficient duration/freshness.
# Named saved-fixture cases above use full dumps. Generated combinations use the
# same relevant lines, so repeated unrelated window inventory adds no test value.
$base.activities=@($base.activities-split'[\r\n]+'|Where-Object {$_-match'mResumedActivity:|mFocusedActivity:'})-join"`n"
$base.window=@($base.window-split'[\r\n]+'|Where-Object {$_-match'mCurrentFocus=|mOverscanScreen=|mRestrictedScreen=|mStable=|mSystem='})-join"`n"
$base.display=@($base.display-split'[\r\n]+'|Where-Object {$_-match'mBaseDisplayInfo='})-join"`n"
$base|ConvertTo-Json -Depth 4|Set-Content "$fixtures/synthetic-compact-inputs.json"
$seed=20261025;$random=[Random]::new($seed);$good=0;$bad=0
for($i=0;$i-lt1000;$i++){
 $seq=Samples;$mode=$random.Next(0,12);$at=$random.Next(0,$seq.Count);$now=5100L
 switch($mode){
  1{$seq[$at].lockBefore=$active}
  2{$seq[$at].lockAfter='unknown'}
  3{$seq[$at].activities=Get-Content "$fixtures/diagnostics-activities.txt" -Raw}
  4{$seq[$at].package=$base.package-replace'stopped=true','stopped=false'}
  5{$seq[$at].processes='u0_a49 com.rdx.fullscreen.usbprobe'}
  6{$seq=Samples ($random.Next(1,10)*500);$now=$seq[-1].endMs}
  7{$now=7001+$random.Next(0,5000)}
  8{$seq[$at].window=$base.window-replace'mCurrentFocus=Window','mOldFocus=Window'}
  9{$seq[$at].packages+="`npackage:com.rdx.fullscreen.projection"}
  10{$seq[$at].display=$base.display-replace'density 160','density 161'}
  11{$seq[$at].endMs=$seq[$at].startMs+2001}
 }
 $actual=(Get-M5WindowAssessment $seq $proof $now).ready;$expected=$mode-eq0
 if($actual-ne$expected){throw "Random oracle failed seed=$seed case=$i mode=$mode"};if($expected){$good++}else{$bad++}
}
# Real checker exercised only through refusals that precede ANY ADB process.
$fakeSession="$OutputDirectory/missing-proof";New-Item -ItemType Directory $fakeSession|Out-Null
[ordered]@{phase='INSTALLED';serial='00000000';apkSHA256=$script:M5FrozenHash;runId='synthetic_no_live_test'}|ConvertTo-Json|Set-Content "$fakeSession/session.json"
foreach($serial in @('WRONG','00000000')){
 $out="$OutputDirectory/early-$serial";$text=& "$root/scripts/Test-M5ArmReadiness.ps1" -AdbPath "$OutputDirectory/does-not-exist.exe" -Serial $serial -SessionDirectory $fakeSession -OutputDirectory $out
 $j=Get-Content "$out/readiness.json" -Raw|ConvertFrom-Json
 Check ($j.result-eq'NOT_READY_TO_ARM'-and-not(Test-Path "$out/0.stdout.txt")) "real checker pre-ADB refusal $serial"
}
$refused=$false
try{& "$PSScriptRoot/Invoke-M5FutureSession.ps1" -Stage ARM -SessionDirectory $fakeSession -Serial '00000000' -LiveAuthorization M5_PERMISSION_ONLY|Out-Null}catch{$refused=$_.Exception.Message-like'ARM REFUSED before ADB:*'}
Check ($refused-and-not(Test-Path "$fakeSession/commands.jsonl")) 'real runner missing-proof refusal before ADB; local frozen preflight only'
[ordered]@{schema=1;runId='synthetic_no_live_test';serial='00000000';apkSHA256='BAD';absentBeforeInstall=$true}|ConvertTo-Json|Set-Content "$fakeSession/fresh-install-proof.json"
$out="$OutputDirectory/early-bad-artifact";& "$root/scripts/Test-M5ArmReadiness.ps1" -AdbPath "$OutputDirectory/does-not-exist.exe" -Serial '00000000' -SessionDirectory $fakeSession -OutputDirectory $out|Out-Null
$j=Get-Content "$out/readiness.json" -Raw|ConvertFrom-Json
Check ($j.result-eq'NOT_READY_TO_ARM'-and-not(Test-Path "$out/0.stdout.txt")) 'real checker bad-artifact proof refused before ADB'
# Parser/AST audit, no process invocation. Collector API surface is closed.
$audit=@()
foreach($file in @('scripts/Test-M5ArmReadiness.ps1','tools/m5/M5ArmReadiness.ps1','tools/m5/Invoke-M5FutureSession.ps1')){
 $tokens=$null;$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile("$root/$file",[ref]$tokens,[ref]$errors);Check ($errors.Count-eq0) "PowerShell AST $file"
 $parameters=@();if($ast.ParamBlock){$parameters=@($ast.ParamBlock.Parameters.Name.VariablePath.UserPath)}
 $audit+=[pscustomobject]@{path=$file;syntaxErrors=$errors.Count;parameters=$parameters}
}
$checker=Get-Content "$root/scripts/Test-M5ArmReadiness.ps1" -Raw
Check ($checker-notmatch'(?i)pm\s+(clear|disable)|force-stop|settings\s+put|[\x27\x22]wm[\x27\x22]|\breboot\b|[\x27\x22]input[\x27\x22]|controlTransfer|bulkTransfer|Remove-Item|uninstall|am[\x27\x22],\s*[\x27\x22]lock-task') 'readiness forbidden device operations absent'
Check ($checker.Contains("'shell|service|call|activity|217'")-and$checker.Contains('$script:frameworkVerified')) 'fixed getter gated by binary pins'
$runner=Get-Content "$root/tools/m5/Invoke-M5FutureSession.ps1" -Raw
$armText=$runner.Substring($runner.IndexOf(" 'ARM'{"))
Check ($armText.IndexOf('Test-M5ArmReadiness.ps1')-lt$armText.IndexOf("'REQUEST_ONCE_AFTER_M4_PASS'")) 'runner invokes readiness before arming in ARM stage'
Check ($runner-notmatch'(?i)\$(Force|IgnoreLockTask|SkipReadiness|DebugBypass)\b') 'no bypass parameter (Add-Member -Force is not a bypass)'
$audit|ConvertTo-Json -Depth 5|Set-Content "$OutputDirectory/static-audit.json"
$cases.ToArray()|ConvertTo-Json -Depth 4|Set-Content "$OutputDirectory/deterministic-cases.json"
[ordered]@{PASS=$true;deterministic=$checks;randomized=1000;seed=$seed;randomSafe=$good;randomRefused=$bad;savedInputFixtures=7;syntheticScenarioNames=@($cases|Where-Object {$_.name-match'^(scenario|fake-time|synthetic|ambiguous|multiline)'}|ForEach-Object name);actualADBInvocations=0;runtimeGetterTested=$false;scope='SAVED DUMPS + SYNTHETIC PARCEL/STATE/TIME; not vehicle qualification'}|ConvertTo-Json -Depth 6|Set-Content "$OutputDirectory/summary.json"
Get-Content "$OutputDirectory/summary.json" -Raw
