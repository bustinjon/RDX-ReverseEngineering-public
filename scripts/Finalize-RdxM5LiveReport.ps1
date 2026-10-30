param([Parameter(Mandatory=$true)][string]$SessionDirectory)
$ErrorActionPreference='Stop';$root=Split-Path $PSScriptRoot -Parent;$base=Join-Path $root 'analysis/parallel-aa-receiver';$s=(Resolve-Path -LiteralPath $SessionDirectory).Path
if(-not$s.StartsWith($base+[IO.Path]::DirectorySeparatorChar)-or(Split-Path $s -Leaf)-notmatch'^m5-live-retry-\d{8}-\d{6}$'){throw 'Wrong session directory'}
function Rel([string]$Path){$p=[IO.Path]::GetFullPath($Path);if(-not$p.StartsWith($root+[IO.Path]::DirectorySeparatorChar)){throw 'Path outside workspace'};return $p.Substring($root.Length+1).Replace('\','/')}
function Row([string]$Path){$f=Get-Item -LiteralPath $Path;return [pscustomobject]@{path=(Rel $Path);size=$f.Length;sha256=(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}}
function ReadCapture([string]$Name){$pattern='^\d{8}-\d{6}-\d{3}-'+[regex]::Escape($Name)+'\.stdout\.txt$';$f=@(Get-ChildItem $s -File|Where-Object Name -match $pattern);if($f.Count-ne1){throw "Expected one $Name capture"};return [string](Get-Content $f[0].FullName -Raw)}
$state=Get-Content "$s/session.json" -Raw|ConvertFrom-Json
if($state.phase-ne'FINISHED'){throw 'Live cleanup/postcheck not complete'}
$verdict=Get-Content "$s/m5-verdict.json" -Raw|ConvertFrom-Json
if($verdict.verdict-notlike'M5 INCONCLUSIVE*'-or$verdict.requestsInvoking-ne1-or$verdict.requestsReturned-ne1-or$verdict.acceptedCallbacks-ne0-or$verdict.rejectedCallbacks-ne0){throw 'Unexpected journal outcome; review before labeling'}
$journal=Get-Item -LiteralPath $state.journal;$dump=Get-Content ($journal.FullName+'.json') -Raw|ConvertFrom-Json
$hash=(Get-FileHash $journal.FullName).Hash
if($hash-ne'138F02161E79536D3C7D6F0D671D9253F8573D89881A2B1BD27B2A937D1E67AF'-or$hash-ine$dump.sha256-or$journal.Length-ne$dump.bytes-or-not$dump.PASS){throw 'Journal dump identity mismatch'}
$events=Get-Content "$s/journal-events.json" -Raw|ConvertFrom-Json
function Event([string]$Name){$a=@($events|Where-Object event -eq $Name);if($a.Count-ne1){throw "Expected one journal event $Name"};$a[0].utc=([DateTimeOffset]$a[0].utc).ToUniversalTime().ToString('o');return $a[0]}
$arm=Event 'ARMED';$target=Event 'TARGET_SEEN';$returned=Event 'REQUEST_API_RETURNED';$detach=Event 'DETACHED_AFTER_REQUEST';$end=Event 'SERVICE_END'
$logs=Get-Content "$s/reconnect-logcat.txt" -Raw
if($logs-notmatch'19:31:30\.671[^\r\n]*START[^\r\n]*UsbPermissionActivity'-or$logs-notmatch'19:31:30\.682[^\r\n]*Attempted Lock Task Mode violation[^\r\n]*UsbPermissionActivity'){throw 'Live UI rejection correlation missing'}
if(([string](ReadCapture 'm5-final-path')).Trim()-or([string](ReadCapture 'm5-final-package')).Trim()){throw 'M5 package/path remains'}
if((ReadCapture 'm5-final-packages-u')-match'com\.rdx\.fullscreen'-or(ReadCapture 'm5-final-processes')-match'com\.rdx\.fullscreen'){throw 'Project package/process remains'}
foreach($name in @('m5-final-code-path','m5-final-private-data-path','m5-final-external-path')){if((ReadCapture $name)-notmatch'No such file or directory'){throw "Exact cleanup path not verified: $name"}}
if((ReadCapture 'm5-final-density').Trim()-ne'Physical density: 160'){throw 'Density mismatch'}
if((ReadCapture 'm5-final-boot-id').Trim()-ne'4f995fac-e0d5-42d7-b566-bf9ee04c11f7'){throw 'Unexpected reboot'}
$post=Get-Content "$s/postcheck.json" -Raw|ConvertFrom-Json
if(-not$post.factoryAPKHashSame-or-not$post.factorySignerSame-or-not$post.wmSizeSame){throw 'Factory/display postcheck failed'}
function Geometry([string]$Text){return @($Text-split'[\r\n]+'|Where-Object {$_-match'mOverscanScreen=|mRestrictedScreen=|mStable=|mSystem='}|ForEach-Object {$_.Trim()})}
if(@(Compare-Object (Geometry (Get-Content "$s/before/window.txt" -Raw)) (Geometry (Get-Content "$s/after/window.txt" -Raw))).Count){throw 'Stable window geometry differs'}

$commands=@();$installs=0;$arms=0;$uninstalls=0;$dumps=0
foreach($file in Get-ChildItem $s -File -Filter '*.command.json'){
 $r=Get-Content $file.FullName -Raw|ConvertFrom-Json
 if($r.PSObject.Properties.Name-contains'arguments'){$args=@($r.arguments)}else{throw 'Unrecognized command record'}
 $serial=if($r.PSObject.Properties.Name-contains'serial'){$r.serial}else{if($args.Count-ge2-and$args[0]-eq'-s'){$args[1]}else{$null}}
 if($args.Count-ge2-and$args[0]-eq'-s'){$args=@($args[2..($args.Count-1)])}
 $op=$args-join' ';$kind='READ/OBSERVE'
 if($args[0]-eq'devices'){$kind='READ-ONLY DEVICE DISCOVERY'}elseif($serial-ne'00000000'){throw 'Wrong/unselected serial'}
 if($args[0]-eq'install'){if($args.Count-ne2-or$args[1]-notlike'*rdx-m5-permission-0.2.0-m5-single-port-300s-development.apk'){throw 'Unexpected install'};$installs++;$kind='AUTHORIZED FROZEN M5 INSTALL'}
 elseif($args[0]-eq'uninstall'){if($args.Count-ne2-or$args[1]-ne'com.rdx.fullscreen.m5permission'){throw 'Unexpected uninstall'};$uninstalls++;$kind='NORMAL M5 UNINSTALL AFTER RETRIEVAL'}
 elseif($op-match'^shell am startservice'){
  if($op-notmatch'-n com\.rdx\.fullscreen\.m5permission/\.PermissionService -a (REQUEST_ONCE_AFTER_M4_PASS|LIST_RESULTS|DUMP_RESULTS)\b'){throw 'Unexpected service/action'}
  if($Matches[1]-eq'REQUEST_ONCE_AFTER_M4_PASS'){$arms++;$kind='ONE AUTHORIZED M5 ARM'}elseif($Matches[1]-eq'DUMP_RESULTS'){$dumps++;$kind='NON-ARMING EVIDENCE DUMP'}else{$kind='NON-ARMING RESULTS LIST'}
 }elseif($op-match'^shell am stopservice'){
  if($op-ne'shell am stopservice -n com.rdx.fullscreen.m5permission/.PermissionService'){throw 'Unexpected service stop'};$kind='M5 CLEANUP STOP; ALREADY TERMINAL'
 }elseif($op-match'(^| )(clear|disable-user|force-stop|reboot|remount|root|input|setprop|settings|rm)( |$)' -or$op-match'^shell pm (install|uninstall|grant|revoke)') {throw 'Forbidden action in command record'}
 $commands+=[pscustomobject]@{record=$file.Name;serial=$serial;operation=$op;classification=$kind;exit=if($r.PSObject.Properties.Name-contains'exitCode'){$r.exitCode}else{$r.exit};timedOut=$r.timedOut;utc=if($r.PSObject.Properties.Name-contains'startUtc'){$r.startUtc}else{$r.utc};raw=$r}
}
if($installs-ne1-or$arms-ne1-or$uninstalls-ne1-or$dumps-ne1){throw "Unexpected mutation counts install=$installs arm=$arms uninstall=$uninstalls dump=$dumps"}
$commands|Sort-Object utc|ForEach-Object {$_|ConvertTo-Json -Depth 8 -Compress}|Set-Content "$s/ALL-COMMANDS.jsonl"
$commands|Select-Object record,serial,operation,classification,exit,timedOut,utc|ConvertTo-Json -Depth 5|Set-Content "$s/live-command-audit.json"

$summary=[ordered]@{schema=1;verdict='M5 INCONCLUSIVE';stop='STOPPED FOR REVIEW. M6 REMAINS DISABLED.';serial='00000000';runId=$state.runId;APK_SHA256=$state.apkSHA256;UID=10049;domain='u:r:untrusted_app:s0';hostArmUtc=$state.armedAt;appArmUtc=$arm.utc;targetUtc=$target.utc;armToTargetMs=($target.monoMs-$arm.monoMs);target='18D1:2D01 /dev/bus/usb/003/003';systemPhoneSequence=@('22D9:2769','18D1:2D01','22D9:2765','18D1:2D01');SDKRequests=1;SDKReturns=1;acceptedCallbacks=0;rejectedCallbacks=0;nonceValidation='NOT EXERCISED: no callback';callbackDeviceValidation='NOT EXERCISED: no callback';grantResult='UNKNOWN; not a recorded denial';initialHasPermission=$false;permissionTrueVerified=$false;dialog='User saw none; actual SystemUI launch rejected by Diagnostics lock task';userAllow='NONE';lockTaskRejectionLogcat='19:31:30.682';lockTaskExitedLaterLogcat='19:31:32.577';terminal='DETACHED';detachUtc=$detach.utc;targetToDetachMs=($detach.monoMs-$target.monoMs);requestReturnToDetachMs=($detach.monoMs-$returned.monoMs);serviceEndUtc=$end.utc;armToServiceEndMs=($end.monoMs-$arm.monoMs);timeout='Not reached; terminal detach ended run early';journalBytes=$journal.Length;journalSHA256=$hash;journalReconstruction='Token/chunks/length/SHA PASS before uninstall';uninstalled=$true;packageProcessCodeDataExternalAbsent=$true;factoryAPKSignerUnchanged=$true;displaySizeDensityStableGeometryUnchanged=$true;bootUnchanged=$true;detectorCleanup='NONE';M6='DISABLED';M7='NOT AUTHORIZED/NOT EXECUTED';next='STOP. Offline review of pre-arm Diagnostics/lock-task gate; no live retry authorized';preArmAssessment='Incomplete: known Diagnostics lock-task constraint was not checked before arm';forbiddenCustomActions='No device open/claim/release/control/bulk/AOA/GAL/phoneTLS/MediaCodec/default-handler/settings/root/factory/detector operations';stockAA='Normal factory AA ran independently, per user/system logs';commandRecords=$commands.Count;mutationCounts=@{install=1;arm=1;dump=1;uninstall=1};evidencePath=(Rel $s)}
$summary|ConvertTo-Json -Depth 8|Set-Content "$s/final-validation.json"

$project=Get-Content "$base/PROJECT-STATE.json" -Raw|ConvertFrom-Json
$project.scope='M5 live permission-only retry CONCLUDED; INCONCLUSIVE; uninstalled; STOPPED FOR REVIEW; no M6/M7/detector cleanup'
$project.milestones.M5retry='INCONCLUSIVE: one returned request; SystemUI blocked by Diagnostics lock task; no callback; selected device re-enumerated; uninstalled'
$project|Add-Member -Force NoteProperty lastM5LiveResult $summary
$project|Add-Member -Force NoteProperty armGate 'NO FURTHER LIVE AUTHORIZATION; review lock-task pre-arm procedure before considering separately authorized M5-only retry'
$project|Add-Member -Force NoteProperty phoneFreeReadinessSuperseded 'The earlier READY FOR M5 ARM assessment omitted the known Diagnostics lock-task UI gate; see M5-RETRY-LIVE-RESULTS.md'
if($project.M6enabled-or$project.nextLive-ne'M5 RETRY ONLY'){throw 'Milestone gate unexpectedly changed'}
$project|ConvertTo-Json -Depth 17|Set-Content "$base/PROJECT-STATE.json"
$note=@'

## 2026-10-25 M5 frozen live retry — INCONCLUSIVE, uninstalled, STOPPED

User explicitly authorized one M5-only retry after confirming physical swap readiness. Frozen APK A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40 unchanged; ordinary UID10049/untrusted_app/PID8902. HostARM23:31:12.881Z; appARM23:31:13.878Z; target18D1:2D01 at23:31:30.631Z,16.753s afterarm. One request intent23:31:30.658Z, SDKreturned23:31:30.683Z. Actual ActivityManager log at19:31:30.671 starts SystemUI UsbPermissionActivity;19:31:30.682 rejects it as Attempted Lock Task Mode violation. Diagnostics stopLockTaskMode follows19:31:32.577, too late for that launch. User saw regular stock AA and no prompt; no ALLOW/default selection. No callback accepted/rejected, no verified grant. Target enumeration disappeared23:31:50.602Z; appterminalDETACHED and SERVICE_END50.644, no replay/reselection/retry. System sequence22D9:2769→18D1:2D01→22D9:2765→18D1:2D01. User kept phone connected; re-enumeration is not claimed as physical unplug. No ADB during phone interval.

This corrects the previous timing issue but is NOT M5PASS/FAIL: ordinary permission request reached framework, UI was blocked by Diagnostics lock task, callback/grant unproved. The earlier phone-free READY assessment omitted a known Diagnostics constraint and was incomplete; it should not justify another arm without review. Future consideration is an offline pre-arm gate/UI choreography review, then separate M5-only authorization; no automatic repeat, force-lock-task exit, timer/APK rebuild, M6 or M7.

Raw reconnect logs captured before DUMP_RESULTS. Durable private journal reconstructed3926bytes with token/chunk/length/SHA verification, SHA138F02161E79536D3C7D6F0D671D9253F8573D89881A2B1BD27B2A937D1E67AF.241 retained files hashed/verified before normal M5uninstall(no-k). Package/process/pm-path/dump absent; exact code/private/external dirsNoSuchFile. All7project packages absent. FactoryAA APKF9E976F44853C9DB7C8FF5A8610C10CAF1E0B4D1E5BE0886F4F52505C5348146/signer unchanged; physical1920x720/density160/stablegeometry and bootUUID4f995fac-e0d5-42d7-b566-bf9ee04c11f7 unchanged. No private Honda data equality claimed. Frozen M5/M6/receiver/historical APKs/original M4/M5 reports preserved. No detector cleanup/modification, customUSBopen/claim/control/bulk/AOA/GAL/phoneTLS/MediaCodec/display/settings/root or factory package/data action. Factory AA operated independently. No further vehicle commands after preservation check.

New report M5-RETRY-LIVE-RESULTS.md, raw evidence m5-live-retry-20261025-185128, final-validation/file/hash/command manifests. Original M5-LIVE-TEST-RESULTS.md remains historical timing-INCONCLUSIVE, untouched. M5 INCONCLUSIVE — STOPPED FOR REVIEW. M6 REMAINS DISABLED; M7NOTAUTHORIZED. No live continuation authorized.
'@
if((Get-Content "$root/NOTES.md" -Raw)-notmatch'## 2026-10-25 M5 frozen live retry') {Add-Content "$root/NOTES.md" $note}
$index=Get-Content "$base/INDEX.md" -Raw
if($index-notmatch'M5-RETRY-LIVE-RESULTS.md'){$index=$index.Replace('## Current status',"## Current status`r`n`r`n[Latest M5 retry: INCONCLUSIVE, uninstalled, STOPPED FOR REVIEW](M5-RETRY-LIVE-RESULTS.md). SystemUI permission dialog was blocked by Diagnostics lock task. The earlier phone-free READY assessment is superseded; no further arm is authorized. M6 remains disabled.");Set-Content "$base/INDEX.md" $index}

$critical=@{};$allowed=@('NOTES.md','analysis/parallel-aa-receiver/PROJECT-STATE.json','analysis/parallel-aa-receiver/INDEX.md')
foreach($f in Get-Content "$s/project-integrity-before-M5-closeout.json" -Raw|ConvertFrom-Json){$p=Join-Path $root $f.path;$now=Row $p;if($now.sha256-ne$f.sha256-and$f.path-notin$allowed){throw "Protected historical change: $($f.path)"};$critical[$now.path]=$now}
$extra=@("$base/M5-RETRY-LIVE-RESULTS.md","$root/scripts/Finalize-RdxM5LiveReport.ps1","$s/final-validation.json",$journal.FullName,($journal.FullName+'.json'))
foreach($p in $extra){$r=Row $p;$critical[$r.path]=$r}
$critical.Values|Sort-Object path|ConvertTo-Json -Depth 6|Set-Content "$base/PROJECT-INTEGRITY.json"
& "$root/tools/Test-RdxOfflineIntegrity.ps1"|Set-Content "$s/final-project-integrity-check.txt"
@'
# M5 live-retry evidence inventory

FILE-INVENTORY.csv and SHA256-MANIFEST.json list retained session files and current report/status/tool references. SEAL.json pins those manifests; all three exclude themselves to avoid circular hashes. PRE-UNINSTALL-* manifests document the earlier verified preservation point before normal uninstall. Mutable session/command files subsequently advanced normally; raw journal/log captures were retained.

The session includes initial setup/phone-free captures, the single authorized ARM, phone-period evidence reconstructed after reconnect, normal M5 uninstall and preservation checks. No second run, detector cleanup or M6/M7 action occurred. Raw logs may contain phone identifiers; use the separately redacted excerpt for sharing, not the raw bundle.
'@|Set-Content "$s/FILE-INVENTORY.md"
$links=@();foreach($doc in @("$base/M5-RETRY-LIVE-RESULTS.md","$base/INDEX.md")){foreach($m in [regex]::Matches((Get-Content $doc -Raw),'(?<!!)\[[^\]]*\]\((?<p>[^)\s]+)\)')){$target=$m.Groups['p'].Value;if($target-match'^[a-zA-Z][a-zA-Z0-9+.-]*:|^#'){continue};$p=Join-Path (Split-Path $doc -Parent) $target;$ok=(Test-Path $p)-or([IO.Path]::GetFullPath($p)-in@("$s\FILE-INVENTORY.csv","$s\SHA256-MANIFEST.json","$s\SEAL.json"));$links+=[pscustomobject]@{document=(Rel $doc);target=$target;exists=$ok}}}
$links|ConvertTo-Json -Depth 4|Set-Content "$s/final-link-audit.json";if(@($links|Where-Object {-not$_.exists}).Count){throw 'Broken result/index link'}
$paths=@(Get-ChildItem $s -Recurse -File|ForEach-Object FullName)+$extra+@("$root/NOTES.md","$base/PROJECT-STATE.json","$base/PROJECT-INTEGRITY.json","$base/INDEX.md")
$exclude=@("$s/FILE-INVENTORY.csv","$s/SHA256-MANIFEST.json","$s/SEAL.json")|ForEach-Object {[IO.Path]::GetFullPath($_)}
$rows=@($paths|Sort-Object -Unique|Where-Object {[IO.Path]::GetFullPath($_)-notin$exclude}|ForEach-Object {Row $_})
$rows|Export-Csv "$s/FILE-INVENTORY.csv" -NoTypeInformation;$rows|ConvertTo-Json -Depth 5|Set-Content "$s/SHA256-MANIFEST.json"
foreach($r in $rows){if((Get-FileHash -LiteralPath (Join-Path $root $r.path)).Hash-ne$r.sha256){throw "Inventory changed $($r.path)"}}
[ordered]@{schema=1;session=(Rel $s);files=$rows.Count;inventorySHA256=(Get-FileHash "$s/FILE-INVENTORY.csv").Hash;hashManifestSHA256=(Get-FileHash "$s/SHA256-MANIFEST.json").Hash;projectIntegritySHA256=(Get-FileHash "$base/PROJECT-INTEGRITY.json").Hash;journalSHA256=$hash;verdict='M5 INCONCLUSIVE';uninstalled=$true;preservation='PASS';M6='DISABLED';M7='NOT AUTHORIZED';next='STOPPED FOR REVIEW; NO FURTHER LIVE TASK'}|ConvertTo-Json -Depth 5|Set-Content "$s/SEAL.json"
Write-Output "M5 CLOSEOUT PASS: INCONCLUSIVE; UI lock-task rejection recorded; one request/zero callbacks; uninstalled; preservation PASS; $($rows.Count) files sealed. NO ADB INVOKED BY THIS SCRIPT. STOP."
