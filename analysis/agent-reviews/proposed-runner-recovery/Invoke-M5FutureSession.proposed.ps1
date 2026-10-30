param([Parameter(Mandatory=$true)][ValidateSet('PREPARE','INSTALL','ARM','RETRIEVE','VERIFY','PRESERVE','UNINSTALL','POSTCHECK')][string]$Stage,[Parameter(Mandatory=$true)][string]$SessionDirectory,[string]$Serial,[ValidateSet('','M5_PERMISSION_ONLY')][string]$LiveAuthorization='')
$ErrorActionPreference='Stop';$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. "$PSScriptRoot/M5ArmReadiness.ps1"
$preflight=(& "$PSScriptRoot/Test-M5FrozenPreflight.ps1"|ConvertFrom-Json);$package=$preflight.package;$factory='com.honda.androidauto.projection.sink';$adb=$preflight.adb
if($Stage-eq'PREPARE'){
 if(Test-Path -LiteralPath $SessionDirectory){throw 'Fresh future session directory required'};New-Item -ItemType Directory -Path $SessionDirectory|Out-Null
 [ordered]@{phase='PREPARED';runId=('m5_'+[guid]::NewGuid().ToString('N'));apkSHA256=$preflight.sha256;serial=$null;phoneSwap='manual';next='INSTALL only after separately authorized car session';liveExecuted=$false}|ConvertTo-Json|Set-Content "$SessionDirectory/session.json"
 Write-Output 'OFFLINE PREPARED. No ADB used. Have phone unlocked, cable ready, USB mode navigation ready BEFORE ARM.';exit
}
if($LiveAuthorization-ne'M5_PERMISSION_ONLY'-or$Serial-ne'00000000'){throw 'REFUSED: explicit future M5-only authorization and recorded head-unit serial00000000 required; NO ADB invoked'}
$SessionDirectory=(Resolve-Path -LiteralPath $SessionDirectory).Path;$state=Get-Content "$SessionDirectory/session.json" -Raw|ConvertFrom-Json
if($state.apkSHA256-ne$preflight.sha256){throw 'Session artifact mismatch'}
function Save { $state|ConvertTo-Json -Depth 6|Set-Content "$SessionDirectory/session.json" }
# ConvertFrom-Json (pwsh 7) returns deadlineUTC as a UTC DateTime; DateTime.Parse of its text would read it as LOCAL time
# (about +4 h here). Use the value directly.
function Utc($d){if($d-is[DateTime]){return $d.ToUniversalTime()};return [DateTimeOffset]::Parse([string]$d,[Globalization.CultureInfo]::InvariantCulture).UtcDateTime}
function Test-PsListing([string]$Text){$first=@($Text-split'\r?\n'|Where-Object{$_.Trim()})|Select-Object -First 1;return $first-match'^USER\s+PID\s+PPID\b.*\bNAME\s*$'-and$Text-notmatch'(?i)error|denied|not found|unknown'}
function DeadlineUtc {$d=$state.deadlineUTC;if($d-is[DateTime]){return $d.ToUniversalTime()};return [DateTimeOffset]::Parse([string]$d,[Globalization.CultureInfo]::InvariantCulture).UtcDateTime }
function Adb([string[]]$Arguments,[switch]$AllowFailure){
 $stem=Join-Path $SessionDirectory ((Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-m5-adb-'+[guid]::NewGuid().ToString('N').Substring(0,8))
 $si=[Diagnostics.ProcessStartInfo]::new();$si.FileName=$adb;$si.UseShellExecute=$false;$si.CreateNoWindow=$true;$si.RedirectStandardOutput=$true;$si.RedirectStandardError=$true
 foreach($a in (@('-s',$Serial)+$Arguments)){$si.ArgumentList.Add($a)}
 $p=[Diagnostics.Process]::new();$p.StartInfo=$si;$utc=[DateTime]::UtcNow.ToString('o')
 if($Arguments-contains'REQUEST_ONCE_AFTER_M4_PASS'-and-not(Test-M5ReadinessFresh $guard $state.runId $Serial ([Environment]::TickCount64))){throw 'ARM REFUSED at process-start boundary: readiness expired; no ADB arm issued'}
 [void]$p.Start();$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$timeout=-not$p.WaitForExit(30000)
 if($timeout){$p.Kill();$p.WaitForExit()};$stdout=$out.GetAwaiter().GetResult();$stderr=$err.GetAwaiter().GetResult();$code=$p.ExitCode;$p.Dispose()
 [IO.File]::WriteAllText($stem+'.stdout.txt',$stdout);[IO.File]::WriteAllText($stem+'.stderr.txt',$stderr)
 $record=[ordered]@{utc=$utc;endUtc=[DateTime]::UtcNow.ToString('o');serial=$Serial;arguments=$Arguments;exit=$code;timedOut=$timeout;stdout=$stem+'.stdout.txt';stderr=$stem+'.stderr.txt'}
 $record|ConvertTo-Json -Depth 5|Set-Content ($stem+'.command.json');Add-Content "$SessionDirectory/commands.jsonl" ($record|ConvertTo-Json -Compress)
 if(($code-ne0-or$timeout)-and-not$AllowFailure){throw "M5 command failed (exit=$code timeout=$timeout): $($Arguments-join' '); raw outputs saved"};return $stdout
}
if($Stage-eq'ARM'-and($state.phase-ne'INSTALLED'-or-not(Test-Path "$SessionDirectory/fresh-install-proof.json"))){throw 'ARM REFUSED before ADB: fresh never-launched install proof required'}
if($Stage-ne'ARM'){
$fingerprint=Adb -Arguments @('shell','getprop','ro.build.fingerprint');$api=(Adb -Arguments @('shell','getprop','ro.build.version.sdk')).Trim()
if($api-ne'22'-or$fingerprint.Trim()-ne'Acura/gen1CBD_HS/gen1CBD_HS:5.1.1/LMY48P/14:user/release-keys'){throw 'Unexpected car identity/firmware: stop without installation or arming'}
if($state.serial-and$state.serial-ne$Serial){throw 'Session serial changed'};$state.serial=$Serial;Save
}
function Snapshot([string]$Name){
 # A failed earlier attempt is kept aside (never deleted) so the stage can be repeated.
 $dir=Join-Path $SessionDirectory $Name;if(Test-Path -LiteralPath $dir){Move-Item -LiteralPath $dir -Destination ($dir+'-incomplete-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))};New-Item -ItemType Directory -Path $dir|Out-Null
 foreach($item in @(@('date','shell','date'),@('uptime','shell','cat','/proc/uptime'),@('usb','shell','dumpsys','usb'),@('display','shell','dumpsys','display'),@('window','shell','dumpsys','window'),@('honda-package','shell','dumpsys','package',$factory))){(Adb -Arguments $item[1..($item.Length-1)])|Set-Content "$dir/$($item[0]).txt"}
 if(-not(Test-M5Geometry (Get-Content "$dir/window.txt" -Raw) (Get-Content "$dir/display.txt" -Raw))){throw 'Display snapshot does not match saved geometry/density; stop without mutation'}
 'real1920x720 density160 rotation0 ON; overscan/stable1339x720 restricted/system1920x720'|Set-Content "$dir/display-geometry.txt"
 $path=(Adb -Arguments @('shell','pm','path',$factory)).Trim();if($path-notmatch'^package:(/system/(app|priv-app)/[A-Za-z0-9_./-]+\.apk)$'){throw 'Factory path changed/split; manual read-only review required'};$remote=$Matches[1];$path|Set-Content "$dir/honda-path.txt";[void](Adb -Arguments @('pull',$remote,"$dir/factory-aa.apk"));Get-FileHash "$dir/factory-aa.apk"|ConvertTo-Json|Set-Content "$dir/honda-hash.json"
 $java='C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin/java.exe';& $java -jar 'C:/Program Files (x86)/Android/android-sdk/build-tools/32.0.0/lib/apksigner.jar' verify --min-sdk-version 22 --max-sdk-version 22 --print-certs "$dir/factory-aa.apk" *> "$dir/honda-signer.txt";if($LASTEXITCODE-ne0){throw 'Local pulled factory signer verification failed'}
 (Adb -Arguments @('logcat','-d','-v','threadtime'))|Set-Content "$dir/logcat.txt"
}
switch($Stage){
 'INSTALL'{
  if($state.phase-ne'PREPARED'){throw 'INSTALL requires PREPARED'}
  $inventory=Adb -Arguments @('shell','pm','list','packages','-u');$inventory|Set-Content "$SessionDirectory/packages-before-install.txt"
  if($inventory-notmatch'(?m)^package:com\.honda\.androidauto\.projection\.sink\s*$'-or@($inventory-split'[\r\n]+'|Where-Object {$_-and$_-notmatch'^package:[a-zA-Z0-9_.]+\s*$'}).Count){throw 'Package inventory unrecognized; no install permitted'}
  if($inventory-match('(?m)^package:'+[regex]::Escape($package)+'\s*$')){throw 'M5 installed or retained state visible; preserve and review before fresh install'}
  $bootId=(Adb -Arguments @('shell','cat','/proc/sys/kernel/random/boot_id')).Trim();if($bootId-notmatch'^[0-9a-fA-F-]{36}$'){throw 'Boot provenance unknown'}
  Snapshot 'before';$factoryHash=Get-Content "$SessionDirectory/before/honda-hash.json" -Raw|ConvertFrom-Json
  if($factoryHash.Hash-ne'F9E976F44853C9DB7C8FF5A8610C10CAF1E0B4D1E5BE0886F4F52505C5348146'){throw 'Factory AA differs; stop before install'}
  # Intent is saved before the install command, so a timeout or transport failure still allows PRESERVE and UNINSTALL.
  $state.phase='INSTALL_REVIEW_REQUIRED';$state.liveExecuted=$true;Save
  $reply=Adb -Arguments @('install',$preflight.apk);$reply|Set-Content "$SessionDirectory/m5-install-success.txt"
  if(@($reply-split'[\r\n]+'|Where-Object{$_.Trim()-eq'Success'}).Count-eq0){throw 'Install success not proven; no ARM permitted'}
  $installedDump=Adb -Arguments @('shell','dumpsys','package',$package);$installedDump|Set-Content "$SessionDirectory/m5-installed-package.txt"
  $facts=Get-M5PackageFacts $installedDump;if(-not$facts.fresh){throw 'Fresh ordinary never-launched installation not proven; no ARM permitted'}
  [ordered]@{schema=1;runId=$state.runId;serial=$Serial;apkSHA256=$preflight.sha256;uid=$facts.uid;firstInstallTime=$facts.firstInstallTime;lastUpdateTime=$facts.lastUpdateTime;bootId=$bootId;absentBeforeInstall=$true;packageDumpSHA256=(Get-FileHash "$SessionDirectory/m5-installed-package.txt").Hash;inventorySHA256=(Get-FileHash "$SessionDirectory/packages-before-install.txt").Hash;installReplySHA256=(Get-FileHash "$SessionDirectory/m5-install-success.txt").Hash}|ConvertTo-Json|Set-Content "$SessionDirectory/fresh-install-proof.json"
  $state.phase='INSTALLED';Save
  Write-Output 'Frozen M5 installed, never launched. Exit Diagnostics manually through RETURN to Honda Home. Do not launch LIST_RESULTS. Prepare phone/cable before separately authorized ARM; its read-only guard must pass.'
 }
 'ARM'{if($state.phase-ne'INSTALLED'){throw 'Only one ARM allowed after fresh install'}
  $guardDir=Join-Path $SessionDirectory ('readiness-'+[guid]::NewGuid().ToString('N'))
  & "$root/scripts/Test-M5ArmReadiness.ps1" -AdbPath $adb -Serial $Serial -SessionDirectory $SessionDirectory -OutputDirectory $guardDir
  $guard=Get-Content "$guardDir/readiness.json" -Raw|ConvertFrom-Json
  if(-not(Test-M5ReadinessFresh $guard $state.runId $Serial ([Environment]::TickCount64))){throw 'ARM REFUSED: current internal readiness failed or stale; no bypass'}
  $state|Add-Member -Force NoteProperty readinessDirectory $guardDir
  $state|Add-Member -Force NoteProperty armedAt ([DateTime]::UtcNow.ToString('o'));$state|Add-Member -Force NoteProperty deadlineUTC ([DateTime]::UtcNow.AddSeconds(300).ToString('o'));$state.phase='ARM_ATTEMPTED';Save
  try{
  if([Environment]::TickCount64-$guard.lastSampleStartMs-gt2000){throw 'ARM REFUSED: readiness expired while saving intent; preserve session, do not auto-retry'}
  (Adb -Arguments @('shell','am','startservice','-n',$preflight.service,'-a','REQUEST_ONCE_AFTER_M4_PASS','--ez','m4_pass_confirmed','true','--ez','wait_for_target','true','--ei','vendor_id','6353','--ei','product_id','11521','--es','run_id',$state.runId))|Set-Content "$SessionDirectory/arm-response.txt"
  }catch{$err=$_
   # Both 'ARM REFUSED' throws happen before Process.Start of the arm command, so nothing reached the app: same state as a
   # line-64 refusal. Record it and return to INSTALLED (a new ARM reruns the full readiness check). Anything else keeps
   # ARM_ATTEMPTED (issuance uncertain).
   if($err.Exception.Message-like'ARM REFUSED*'-and-not(Test-Path -LiteralPath "$SessionDirectory/arm-response.txt")){
    $prior=@();if($null-ne$state.PSObject.Properties['notIssuedArms']){$prior=@($state.notIssuedArms)}
    $state|Add-Member -Force NoteProperty notIssuedArms ($prior+[pscustomobject]@{readinessDirectory=$state.readinessDirectory;armedAt=$state.armedAt;refusedAt=[DateTime]::UtcNow.ToString('o');reason=$err.Exception.Message})
    foreach($n in 'readinessDirectory','armedAt','deadlineUTC'){$state.PSObject.Properties.Remove($n)};$state.phase='INSTALLED';Save
    throw ($err.Exception.Message+' | ARM NOT ISSUED: phase restored to INSTALLED; app untouched. Another ARM reruns the full readiness check.')}
   throw $err
  }
  # The service runs asynchronously after am returns: poll (read only, never resend) for this run's ARMED marker.
  for($try=1;;$try++){$logs=Adb -Arguments @('logcat','-d','-v','threadtime','-s','RDX.M5:I','*:S');if($logs-match([regex]::Escape('run='+$state.runId)+'.*event=ARMED')-or$try-ge10){break};Start-Sleep -Milliseconds 500}
  $logs|Set-Content "$SessionDirectory/armed-logcat.txt";if($logs-notmatch([regex]::Escape('run='+$state.runId)+'.*event=ARMED')){throw 'ARM not confirmed. Do not swap; inspect evidence. No automatic retry.'};$domains=Adb -Arguments @('shell','ps','-Z');$domains|Set-Content "$SessionDirectory/armed-selinux-processes.txt";$ours=@($domains-split'\r?\n'|Where-Object {$_-match'com\.rdx\.fullscreen\.m5permission\s*$'});if(-not$ours.Count-or($ours-join"`n")-notmatch'u:r:untrusted_app:s0'){throw 'Untrusted app process not verified; do not swap; preserve/retrieve bounded result'};$state.phase='PHONE_SWAP_WAIT_RECONNECT';Save
  Write-Output "Deadline $($state.deadlineUTC). SWAP TO PHONE NOW — WATCH THE RDX SCREEN FOR A USB PERMISSION DIALOG";Write-Output 'No more ADB commands from this script. Manually ALLOW only this app if prompted; do not select a default handler. Reconnect laptop after60–90seconds. If still waiting, allow300-second bound to finish before RETRIEVE.'}
 'RETRIEVE'{if($state.phase-notin@('PHONE_SWAP_WAIT_RECONNECT','ARM_ATTEMPTED')){throw 'RETRIEVE requires an arm attempt; never rerun permission automatically'}
  (Adb -Arguments @('logcat','-d','-v','threadtime'))|Set-Content (Join-Path $SessionDirectory ('reconnect-before-dump-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'.txt'));
  $logs=Adb -Arguments @('logcat','-d','-v','threadtime','-s','RDX.M5:I','*:S');$logs|Set-Content "$SessionDirectory/m5-before-dump.txt"
  if([DateTime]::UtcNow-lt(DeadlineUtc).AddSeconds(3)-and$logs-notmatch([regex]::Escape('run='+$state.runId)+'.*(state=(GRANTED|DENIED|DETACHED|TIMED_OUT|ERROR|CALLBACK_INCONSISTENT)|SERVICE_END)')){throw 'M5 may still be active. Keep laptop connected; wait for bounded deadline, then repeat RETRIEVE only.'}
  # Failures from here on are recorded: PRESERVE requires repeated, recorded retrieval failures after a DUMP request.
  try{
  $before=@([regex]::Matches(($logs|Out-String),'DUMP_BEGIN token=([a-f0-9-]{36}) run='+[regex]::Escape($state.runId)+'\b')|ForEach-Object{$_.Groups[1].Value})
  [void](Adb -Arguments @('shell','am','startservice','-n',$preflight.service,'-a','DUMP_RESULTS','--es','run_id',$state.runId))
  # The dump is written asynchronously: poll the small app-tag log (read only) until a NEW dump for this run has its END line.
  $dumpDone=$false;for($try=1;$try-le10;$try++){$tag=(Adb -Arguments @('logcat','-d','-v','threadtime','-s','RDX.M5:I','*:S'))|Out-String;$b=@([regex]::Matches($tag,'DUMP_BEGIN token=([a-f0-9-]{36}) run='+[regex]::Escape($state.runId)+'\b')|ForEach-Object{$_.Groups[1].Value}|Where-Object{$_-notin$before});if($b.Count-and$tag-match('DUMP_END token='+[regex]::Escape($b[-1]))){$dumpDone=$true;break};Start-Sleep -Milliseconds 1000}
  if(-not$dumpDone){throw 'No new complete dump for this run yet (app may still be active). Keep laptop connected; wait 30 s, then repeat RETRIEVE only.'}
  $logs=Adb -Arguments @('logcat','-d','-v','threadtime');$logs|Set-Content "$SessionDirectory/reconnect-logcat.txt"
  Get-M5PermissionUiEvidence $logs $state.runId|ConvertTo-Json -Depth 5|Set-Content "$SessionDirectory/permission-ui-evidence.json"
  $converted=(& "$root/scripts/Convert-RdxM5Dump.ps1" -LogFile "$SessionDirectory/reconnect-logcat.txt" -RunId $state.runId -OutputDirectory "$SessionDirectory/reconstructed"|ConvertFrom-Json);$state|Add-Member -Force NoteProperty journal $converted.file
  }catch{$err=$_;$prior=@();if($null-ne$state.PSObject.Properties['retrieveFailures']){$prior=@($state.retrieveFailures)}
   $state|Add-Member -Force NoteProperty retrieveFailures ($prior+[pscustomobject]@{at=[DateTime]::UtcNow.ToString('o');afterDumpRequest=$true;reason=$err.Exception.Message});Save;throw $err}
  Get-ChildItem $SessionDirectory -Recurse -File|Get-FileHash|ConvertTo-Json|Set-Content "$SessionDirectory/evidence-before-uninstall.json";$state.phase='RETRIEVED';Save;Write-Output 'Durable journal reconstructed with length/token/SHA256 verification. No raw callback nonce was stored by frozen APK.'}
 'VERIFY'{if($state.phase-ne'RETRIEVED'){throw 'Retrieve exact durable evidence first'};& "$PSScriptRoot/Get-M5JournalVerdict.ps1" -Journal $state.journal -Output "$SessionDirectory/m5-verdict.json"
  $ui=Get-Content "$SessionDirectory/permission-ui-evidence.json" -Raw|ConvertFrom-Json
  # Only blame the permission UI when the evidence is scoped to this run's ARMED..SERVICE_END window.
  if($ui.blocked-and-not$ui.runScoped){$v=Get-Content "$SessionDirectory/m5-verdict.json" -Raw|ConvertFrom-Json;$v|Add-Member -Force NoteProperty permissionUiAttribution 'UNKNOWN: this run''s ARMED marker was not in the saved log; a blocked-UI line may belong to an older run';$v|ConvertTo-Json -Depth 6|Set-Content "$SessionDirectory/m5-verdict.json"}
  if($ui.blocked-and$ui.runScoped){$v=Get-Content "$SessionDirectory/m5-verdict.json" -Raw|ConvertFrom-Json;$v.verdict='M5 INCONCLUSIVE: permission Activity blocked; environment/UI-state failure';$v|Add-Member -Force NoteProperty permissionUiEvidence 'permission-ui-evidence.json';$v|ConvertTo-Json -Depth 6|Set-Content "$SessionDirectory/m5-verdict.json";Write-Output $v.verdict}
  $state.phase='VERIFIED';Save;Write-Output 'LIVE EXPERIMENT COMPLETE. No M6 action permitted. Continue cleanup only.'}
 'PRESERVE'{
  # Explicit operator escape for dead ends RETRIEVE cannot finish (no journal, ambiguous install). Saves and hashes what
  # exists; does not issue or retry any permission request. Cleanup is unlocked only with positive evidence (below).
  if($state.phase-notin@('INSTALL_REVIEW_REQUIRED','ARM_ATTEMPTED','PHONE_SWAP_WAIT_RECONNECT')){throw 'PRESERVE is only for an ambiguous install or an arm whose evidence RETRIEVE cannot complete'}
  $armPhase=$state.phase-ne'INSTALL_REVIEW_REQUIRED'
  if($armPhase-and[DateTime]::UtcNow-lt(DeadlineUtc).AddSeconds(3)){throw 'M5 may still be active. Wait for the bounded deadline; try RETRIEVE first.'}
  if($armPhase){$f=@();if($null-ne$state.PSObject.Properties['retrieveFailures']){$f=@($state.retrieveFailures|Where-Object{$_.afterDumpRequest})}
   if($f.Count-lt2-or((Utc $f[-1].at)-(Utc $f[0].at)).TotalSeconds-lt30){throw 'PRESERVE requires at least two recorded RETRIEVE failures after a dump request, 30 s or more apart. Run RETRIEVE first.'}}
  $stamp=Get-Date -Format 'yyyyMMdd-HHmmss-fff'
  (Adb -Arguments @('logcat','-d','-v','threadtime'))|Set-Content (Join-Path $SessionDirectory "preserve-logcat-$stamp.txt");$tag=(Adb -Arguments @('logcat','-d','-v','threadtime','-s','RDX.M5:I','*:S'))|Out-String;$tag|Set-Content (Join-Path $SessionDirectory "preserve-m5-$stamp.txt")
  $ps=(Adb -Arguments @('shell','ps'))|Out-String;$ps|Set-Content (Join-Path $SessionDirectory "preserve-ps-$stamp.txt")
  Get-ChildItem $SessionDirectory -Recurse -File|Get-FileHash|ConvertTo-Json|Set-Content "$SessionDirectory/evidence-before-uninstall.json"
  # An arm phase is released only when the request is provably over: this run's terminal marker, or no M5 process in a recognized listing.
  if($armPhase){$ended=$tag-match([regex]::Escape('run='+$state.runId)+'.*(state=(GRANTED|DENIED|DETACHED|TIMED_OUT|ERROR|CALLBACK_INCONSISTENT)|SERVICE_END)');$gone=(Test-PsListing $ps)-and$ps-notmatch'\bcom\.rdx\.fullscreen\.m5permission\s*(\r?\n|$)'
   if(-not($ended-or$gone)){throw "Evidence saved (preserve-*-$stamp), but M5 termination is UNKNOWN (no terminal marker, process present or listing unrecognized). Cleanup NOT unlocked; stop for review."}}
  $state|Add-Member -Force NoteProperty preservedFromPhase $state.phase;$state.phase='EVIDENCE_PRESERVED';Save;Write-Output 'Evidence preserved and hashed WITHOUT a verified journal. Verdict: INCONCLUSIVE. UNINSTALL is now permitted.'}
 'UNINSTALL'{if($state.phase-notin@('INSTALLED','RETRIEVED','VERIFIED','EVIDENCE_PRESERVED')){throw 'Retrieve (or PRESERVE) and hash evidence before uninstall; never discard failed evidence automatically'}
  # Removal commands may legitimately fail on a repeat (already stopped/absent); the read-only checks below decide.
  [void](Adb -Arguments @('shell','am','stopservice','-n',$preflight.service) -AllowFailure);[void](Adb -Arguments @('uninstall',$package) -AllowFailure)
  # Absence counts only from recognized listings: every pm line is package:<name>, and ps starts with its normal header.
  $list=(Adb -Arguments @('shell','pm','list','packages',$package))|Out-String;$listOk=@($list-split'\r?\n'|Where-Object{$_.Trim()-and$_.Trim()-notmatch'^package:[A-Za-z0-9_.]+$'}).Count-eq0
  $remaining=$list-match('(?m)^package:'+[regex]::Escape($package)+'\s*$');$ps=(Adb -Arguments @('shell','ps'))|Out-String
  if(-not$listOk-or-not(Test-PsListing $ps)){throw 'Package/process listing unrecognized; cleanup not verified. Repeat UNINSTALL.'}
  if($remaining-or$ps-match'\bcom\.rdx\.fullscreen\.m5permission\s*(\r?\n|$)'){throw 'M5 package/process cleanup not verified'};[ordered]@{packageAbsent=$true;processAbsent=$true;codeData='Normal successful uninstall guarantee; no privileged private-directory equality claim'}|ConvertTo-Json|Set-Content "$SessionDirectory/cleanup.json";$state.phase='UNINSTALLED';Save}
 'POSTCHECK'{if($state.phase-ne'UNINSTALLED'){throw 'Postcheck follows M5-only uninstall'};Snapshot 'after';$before=Get-Content "$SessionDirectory/before/honda-hash.json" -Raw|ConvertFrom-Json;$after=Get-Content "$SessionDirectory/after/honda-hash.json" -Raw|ConvertFrom-Json;$hashSame=$before.Hash-eq$after.Hash;$geometrySame=(Get-Content "$SessionDirectory/before/display-geometry.txt" -Raw)-eq(Get-Content "$SessionDirectory/after/display-geometry.txt" -Raw);$signerSame=(Get-Content "$SessionDirectory/before/honda-signer.txt" -Raw)-eq(Get-Content "$SessionDirectory/after/honda-signer.txt" -Raw)
  [ordered]@{factoryAPKHashSame=$hashSame;factorySignerSame=$signerSame;displayGeometrySame=$geometrySame;displayWindowDumps='Both parsed against saved geometry/density, raw dumps retained';privateDataEquality='NOT CLAIMED';next='STOP. M6 requires M5 PASS plus separate authorization'}|ConvertTo-Json|Set-Content "$SessionDirectory/postcheck.json";$state.phase=if($hashSame-and$signerSame-and$geometrySame){'FINISHED'}else{'POSTCHECK_MISMATCH'};Save;if(-not$hashSame-or-not$signerSame-or-not$geometrySame){throw 'Preservation mismatch: retain evidence and investigate; do not restore/mutate private state'};Write-Output 'M5 cleanup/postcheck complete. STOP; no next milestone executed.'}
}
