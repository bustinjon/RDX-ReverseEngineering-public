param(
 [Parameter(Mandatory)][string]$Session,
 [Parameter(Mandatory)][ValidateSet('BASELINE','INSTALL','LAUNCH','CAPTURE','OVERSCAN_APPLY','OVERSCAN_RESTORE','UNINSTALL','POSTCHECK')][string]$Stage,
 [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9._:-]+$')][string]$Serial,
 [ValidateSet('grid','decoder')][string]$App,
 [ValidateSet('NONE','GRID_TEST','DECODER_TEST','OVERSCAN')][string]$Authorization='NONE',
 [ValidatePattern('^[a-z0-9-]{1,40}$')][string]$Label='capture',
 [string]$AdbPath
)
# Evening exploration stages (2026-10-27, v2 after CODEX-EVENING-ATTACK.md). Fixed command set only; every adb call is
# checked against $allowed before it starts. State-changing commands: install/uninstall of the two audited test APKs,
# starting their one Activity, and `wm overscan 0,0,-581,0` / `wm overscan reset`. No taps, keys, settings, properties,
# force-stops, log clearing or reboots. OVERSCAN_RESTORE, UNINSTALL and POSTCHECK still run if session.json is unreadable.
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if(-not$AdbPath){$AdbPath=Join-Path $root 'adb/adb.exe'}
$apps=@{
 grid=@{pkg='com.rdx.fullscreen.gridtest';activity='com.rdx.fullscreen.gridtest/.GridActivity';tag='RDX.GRID';auth='GRID_TEST'
  apk='analysis/parallel-aa-receiver/grid-test/build/20261023-103955-076/rdx-grid-test-0.1.0-development.apk';sha='24843A11B417B20F37D33C9FB269007A9F69158E39D27882E67CEAFBF33B7214'}
 decoder=@{pkg='com.rdx.fullscreen.decodertest';activity='com.rdx.fullscreen.decodertest/.DecoderTestActivity';tag='RDX.DECODER';auth='DECODER_TEST'
  apk='analysis/parallel-aa-receiver/decoder-test/build/20261023-112223-673/rdx-decoder-test-0.2.0-with-clips-development.apk';sha='ADD395FC46626DD3C43F527E10B1D8C49092DB43C8088CAEABB4A553BE90A374'}
}
$hondaPkg='com.honda.androidauto.projection.sink';$watchPkgs=@('com.rdx.fullscreen.gridtest','com.rdx.fullscreen.decodertest','com.rdx.fullscreen.m5permission')
# Fallback reference when the journal is unreadable: stock values captured 2026-10-26 (m5-retry-live-20261026-174603/before).
$stockRects=[ordered]@{mOverscanScreen='(0,0) 1339x720';mRestrictedOverscanScreen='(0,0) 1339x720';mUnrestrictedScreen='(0,0) 1920x720';mRestrictedScreen='(0,0) 1920x720'
 mStableFullscreen='(0,0)-(1339,720)';mStable='(0,0)-(1339,720)';mSystem='(0,0)-(1920,720)';mCur='(0,0)-(1339,720)';mContent='(0,0)-(1339,720)';mVoiceContent='(0,0)-(1339,720)';mDock='(0,0)-(1339,720)'}
$stockHonda='F9E976F44853C9DB7C8FF5A8610C10CAF1E0B4D1E5BE0886F4F52505C5348146'
$Session=[IO.Path]::GetFullPath($Session);$stateFile=Join-Path $Session 'session.json'
if($Session-match'\s'){throw "Session path must not contain spaces: $Session"}
function JournalComplete($S){$b=$S.baseline;if(-not$b-or-not$b.identity.bootId-or-not$b.identity.fingerprint-or-not$b.honda.sha256-or-not$b.geometry.rects){return $false}
 foreach($k in 'mOverscanScreen','mRestrictedOverscanScreen','mUnrestrictedScreen','mRestrictedScreen','mStableFullscreen','mStable','mSystem','mCur','mContent','mVoiceContent','mDock'){if(-not$b.geometry.rects.$k){return $false}};return $true}
$recovery=$false
if($Stage-eq'BASELINE'){if(Test-Path -LiteralPath $Session){throw "Session directory already exists: $Session"};New-Item -ItemType Directory -Path $Session|Out-Null
 $state=[pscustomobject][ordered]@{serial=$Serial;created=[DateTime]::UtcNow.ToString('o');baseline=$null;installed=[pscustomobject]@{grid='ABSENT';decoder='ABSENT'};overscan='ZERO';lastTagLine=[pscustomobject]@{grid=$null;decoder=$null};history=@()}}
else{
 if(-not(Test-Path -LiteralPath $Session)){throw 'No session directory; run BASELINE first'}
 try{$state=Get-Content -LiteralPath $stateFile -Raw|ConvertFrom-Json;if(-not$state.installed-or-not$state.lastTagLine-or-not$state.overscan-or(-not$state.recoveredJournal-and-not(JournalComplete $state))){throw 'incomplete'}
  if($state.recoveredJournal){$recovery=$true;if($Stage-notin'OVERSCAN_RESTORE','UNINSTALL','POSTCHECK'){throw 'recovered journal: only OVERSCAN_RESTORE, UNINSTALL and POSTCHECK can run'}}}
 catch{
  if($Stage-notin'OVERSCAN_RESTORE','UNINSTALL','POSTCHECK'){throw "session.json unreadable or incomplete ($($_.Exception.Message)); only OVERSCAN_RESTORE, UNINSTALL and POSTCHECK can run"}
  if(Test-Path -LiteralPath $stateFile){Copy-Item -LiteralPath $stateFile -Destination "$stateFile.unreadable-$(Get-Date -Format HHmmss-fff)"}
  $recovery=$true;$state=[pscustomobject][ordered]@{serial=$Serial;created=[DateTime]::UtcNow.ToString('o');recoveredJournal=$true;baseline=$null
   installed=[pscustomobject]@{grid='UNKNOWN';decoder='UNKNOWN'};overscan='UNKNOWN';lastTagLine=[pscustomobject]@{grid=$null;decoder=$null};history=@()}}
 if($state.serial-cne$Serial){throw 'Serial differs from the session serial'}}
function Save{$tmp="$stateFile.tmp";$state|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $tmp;[IO.File]::Move($tmp,$stateFile,$true)}
function Need([string]$Token){if($Authorization-cne$Token){throw "Stage $Stage needs -Authorization $Token (said by the user at the car)"}}
function NotWhileOverscanUnverified{if($state.overscan-notin'ZERO','APPLIED'){throw "Overscan state is $($state.overscan); run OVERSCAN_RESTORE first. Nothing else runs until it is verified."}}
if($Stage-in'INSTALL','LAUNCH','UNINSTALL'-and-not$App){throw "Stage $Stage needs -App"}
$stamp=(Get-Date -Format 'HHmmss-fff');$dir=Join-Path $Session "$stamp-$($Stage.ToLower())$(if($App){"-$App"})$(if($Stage-in'CAPTURE','LAUNCH'){"-$Label"})"
New-Item -ItemType Directory -Path $dir|Out-Null

$allowed=@('^get-state$','^logcat -d -v threadtime$','^exec-out screencap -p$','^shell cat /proc/sys/kernel/random/boot_id$','^shell getprop ro\.build\.fingerprint$',
 '^shell ps$','^shell dumpsys (display|window|window windows|SurfaceFlinger|media\.player|activity activities)$','^shell pm path [a-z0-9.]+$','^shell dumpsys package [a-z0-9.]+$',
 '^shell ls -l /data/system/display_settings\.xml$','^pull /system/[A-Za-z0-9_./-]+\.apk \S+$','^install \S+\.apk$','^uninstall com\.rdx\.fullscreen\.(gridtest|decodertest)$',
 '^shell am start -W -n com\.rdx\.fullscreen\.(gridtest/\.GridActivity|decodertest/\.DecoderTestActivity)$','^shell wm overscan (0,0,-581,0|reset)$')
function Adb([string]$Name,[string[]]$A,[int]$Timeout=20000,[switch]$Binary){
 $rest=$A-join' ';if(-not($allowed|Where-Object{$rest-cmatch$_})){throw "Command not on the evening allowlist: $rest"}
 $full=@('-s',$Serial)+$A;$si=[Diagnostics.ProcessStartInfo]::new();$si.FileName=$AdbPath;$si.UseShellExecute=$false;$si.CreateNoWindow=$true;$si.RedirectStandardOutput=$true;$si.RedirectStandardError=$true
 foreach($x in $full){$si.ArgumentList.Add($x)};$p=[Diagnostics.Process]::new();$p.StartInfo=$si;$utc=[DateTime]::UtcNow.ToString('o')
 [void]$p.Start();$e=$p.StandardError.ReadToEndAsync();$png=Join-Path $dir "$Name.png"
 if($Binary){$fs=[IO.File]::Create($png);$copy=$p.StandardOutput.BaseStream.CopyToAsync($fs)}else{$o=$p.StandardOutput.ReadToEndAsync()}
 $timedOut=-not$p.WaitForExit($Timeout);if($timedOut){try{$p.Kill()}catch{};$p.WaitForExit()}
 if($Binary){try{$copy.Wait(5000)|Out-Null}catch{};$fs.Dispose();$len=(Get-Item $png).Length;$out="<binary $len bytes>"}else{$out=$o.GetAwaiter().GetResult();[IO.File]::WriteAllText((Join-Path $dir "$Name.stdout.txt"),$out)}
 $err=$e.GetAwaiter().GetResult();[IO.File]::WriteAllText((Join-Path $dir "$Name.stderr.txt"),$err);$code=$p.ExitCode;$p.Dispose()
 $rec=[ordered]@{name=$Name;stage=$Stage;utc=$utc;endUtc=[DateTime]::UtcNow.ToString('o');arguments=$full;exitCode=$code;timedOut=$timedOut}
 Add-Content -LiteralPath (Join-Path $Session 'commands.jsonl') -Value ($rec|ConvertTo-Json -Compress -Depth 4)
 $ok=$code-eq0-and-not$timedOut-and$err-notmatch'(?i)error|not found|offline|unauthorized'
 if($Binary){$b=[IO.File]::ReadAllBytes($png);$sig=[byte[]](137,80,78,71,13,10,26,10)
  $ok=$ok-and$b.Length-ge24-and-not(Compare-Object $sig ([byte[]]$b[0..7]) -SyncWindow 0)-and[Text.Encoding]::ASCII.GetString($b,12,4)-ceq'IHDR'-and(($b[16..19]+$b[20..23])|Measure-Object -Sum).Sum-gt0}
 return [pscustomobject]@{out=$out;err=$err;code=$code;timedOut=$timedOut;ok=$ok}
}
function Test-PsListing([string]$Text){$first=@($Text-split'\r?\n'|Where-Object{$_.Trim()})|Select-Object -First 1;return $first-match'^USER\s+PID\s+PPID\b.*\bNAME\s*$'-and$Text-notmatch'(?i)error|denied|not found|unknown'}
function AppPids([string]$Pkg){$r=Adb 'ps' @('shell','ps');if(-not$r.ok-or-not(Test-PsListing $r.out)){throw 'Process listing unrecognized; STOP'}
 return @($r.out-split'\r?\n'|Where-Object{$_-match"\s$([regex]::Escape($Pkg))(:\S+)?\s*$"}|ForEach-Object{($_.Trim()-split'\s+')[1]})}
function PkgState([string]$Pkg){$r=Adb "path-$Pkg" @('shell','pm','path',$Pkg);if(-not$r.ok){return 'UNKNOWN'}
 $lines=@($r.out-split'\r?\n'|Where-Object{$_.Trim()})
 if($lines.Count-eq0){$s=Adb 'state-confirm' @('get-state') 8000;if($s.ok-and$s.out.Trim()-eq'device'){return 'ABSENT'};return 'UNKNOWN'}
 if(@($lines|Where-Object{$_-notmatch'^package:/\S+\.apk\s*$'}).Count){return 'UNKNOWN'};return 'PRESENT'}
function Geometry([string]$Prefix){$d=Adb "$Prefix-display" @('shell','dumpsys','display');$w=Adb "$Prefix-window" @('shell','dumpsys','window')
 if(-not$d.ok-or-not$w.ok){throw 'Display/window dump failed; STOP'}
 # Overscan is read only from the two complete DisplayInfo objects of the built-in display (local:0).
 $infos=@([regex]::Matches($d.out,'m(Base|Override)DisplayInfo=DisplayInfo\{"[^"]*", uniqueId "local:0"[^\r\n]*\}(?=[ \t\r]*(\n|$))')|ForEach-Object{$_.Value})
 if(@($infos|Where-Object{$_-like'mBase*'}).Count-ne1-or@($infos|Where-Object{$_-like'mOverride*'}).Count-ne1){throw 'Built-in DisplayInfo (base+override) not found; STOP'}
 $os=@($infos|ForEach-Object{[regex]::Matches($_,', overscan \((-?\d+),(-?\d+),(-?\d+),(-?\d+)\)')|ForEach-Object{$_.Value}}|Select-Object -Unique)
 $rects=[ordered]@{};foreach($k in $stockRects.Keys){$m=[regex]::Match($w.out,"(?m)^\s*$k=(\S+ \S+|\S+)\s*$");if(-not$m.Success){throw "$k not found in window dump; STOP"};$rects[$k]=$m.Groups[1].Value}
 return [pscustomobject][ordered]@{overscan=$os;overscanScreen="mOverscanScreen=$($rects.mOverscanScreen)";rects=[pscustomobject]$rects}}
function SameRects($A,$B){foreach($k in $stockRects.Keys){if($A.$k-cne$B.$k){return $false}};return $true}
function RefRects{if($state.baseline){return $state.baseline.geometry.rects};return [pscustomobject]$stockRects}
function TagLines([string]$Text,[string]$Tag){@($Text-split'\r?\n'|Where-Object{$_-match"\s$([regex]::Escape($Tag))\s*:"})}
function NewSince([string[]]$Lines,[string]$Last){if(-not$Last){return [pscustomobject]@{lines=$Lines;boundaryLost=$false}}
 $i=[Array]::LastIndexOf($Lines,$Last);if($i-lt0){return [pscustomobject]@{lines=$Lines;boundaryLost=$true}};return [pscustomobject]@{lines=@($Lines|Select-Object -Skip ($i+1));boundaryLost=$false}}
function Snapshot([string]$Prefix,$A){$sc=Adb "$Prefix-screen" @('exec-out','screencap','-p') 20000 -Binary;$null=Adb "$Prefix-windows" @('shell','dumpsys','window','windows')
 $pids=if($A){@(AppPids $A.pkg)}else{@()};$l=Adb "$Prefix-logcat" @('logcat','-d','-v','threadtime') 40000;if(-not$l.ok){throw 'logcat read failed; STOP'};$g=Geometry $Prefix
 $res=[ordered]@{geometry=$g;screenshotOk=$sc.ok;appPids=$pids}
 if($A){$all=@(TagLines $l.out $A.tag);[IO.File]::WriteAllLines((Join-Path $dir "$Prefix-$($A.tag).txt"),[string[]]$all)
  # The log is never cleared: only lines after the last line already reported, from the app's current process, are new.
  $n=NewSince $all $state.lastTagLine.($App);$new=@(@($n.lines)|Where-Object{$f=$_.Trim()-split'\s+';$f.Count-gt2-and$pids-contains$f[2]})
  $res.boundaryLost=$n.boundaryLost;$res.newLines=$new;$res.lastLogLine=$(if($all.Count){$all[-1]}else{$null})}
 return [pscustomobject]$res}
function HondaHash([string]$Prefix){$p=Adb "$Prefix-honda-path" @('shell','pm','path',$hondaPkg);$path=([regex]::Match($p.out,'package:(/system/\S+\.apk)')).Groups[1].Value
 if(-not$p.ok-or-not$path){throw 'Honda AA path unrecognized; STOP'};$dest=Join-Path $dir 'factory-aa.apk';$r=Adb "$Prefix-honda-pull" @('pull',$path,$dest) 60000
 if($r.code-ne0-or-not(Test-Path -LiteralPath $dest)){throw 'Honda AA pull failed; STOP'};$h=(Get-FileHash -LiteralPath $dest).Hash;Remove-Item -LiteralPath $dest;return [pscustomobject]@{path=$path;sha256=$h}}
function Identity{$s=Adb 'state' @('get-state') 8000;if(-not$s.ok-or$s.out.Trim()-ne'device'){throw 'Selected serial not available; STOP'}
 return [pscustomobject][ordered]@{bootId=(Adb 'boot-id' @('shell','cat','/proc/sys/kernel/random/boot_id')).out.Trim();fingerprint=(Adb 'fingerprint' @('shell','getprop','ro.build.fingerprint')).out.Trim()}}
function Done([string]$Text,$Data,[int]$Exit=0){$state.history=@($state.history)+[pscustomobject][ordered]@{at=[DateTime]::UtcNow.ToString('o');stage=$Stage;app=$App;label=$Label;dir=(Split-Path $dir -Leaf);result=$Text};Save
 if($Data){$Data|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $dir 'result.json')};Write-Output "$Stage $(if($Exit){'WARNING'}else{'OK'}): $Text";if($recovery){Write-Output 'NOTE: session.json was unreadable; compared against the 10-26 stock reference.'};if($Exit){exit $Exit}}

switch($Stage){
'BASELINE'{
 $id=Identity;foreach($k in $watchPkgs){$ps=PkgState $k;if($ps-ne'ABSENT'){throw "Test package $k is $ps before the evening; STOP and preserve"}}
 $g=Geometry 'baseline';if($g.overscan.Count){throw "Overscan is already non-zero ($($g.overscan -join ';')); STOP for review"}
 $null=Adb 'settings-file' @('shell','ls','-l','/data/system/display_settings.xml')
 $h=HondaHash 'baseline';$snap=Snapshot 'baseline' $null
 $state.baseline=[pscustomobject][ordered]@{identity=$id;geometry=$g;honda=$h};Done "boot $($id.bootId), $($g.overscanScreen), Honda AA $($h.sha256.Substring(0,8)), screenshot $($snap.screenshotOk)" $state.baseline}
'INSTALL'{
 $a=$apps[$App];Need $a.auth;NotWhileOverscanUnverified;$other=if($App-eq'grid'){'decoder'}else{'grid'}
 if($state.installed.$other-ne'ABSENT'){throw "Uninstall $other first; one test app at a time"}
 $apk=Join-Path $root $a.apk;if((Get-FileHash -LiteralPath $apk).Hash-ne$a.sha){throw "APK hash mismatch for $App; STOP"}
 $ps=PkgState $a.pkg;if($ps-ne'ABSENT'){if($ps-eq'PRESENT'){$state.installed.$App='INSTALLED';Save};throw "$($a.pkg) is $ps; no reinstall/-r. Use UNINSTALL or stop"}
 $state.installed.$App='REVIEW_REQUIRED';Save
 $r=Adb 'install' @('install',$apk) 120000;$after=PkgState $a.pkg
 $state.installed.$App=if($after-eq'PRESENT'){'INSTALLED'}elseif($after-eq'ABSENT'){'ABSENT'}else{'REVIEW_REQUIRED'};Save
 if($after-ne'PRESENT'){throw "Install not confirmed (exit $($r.code), package $after): $($r.out.Trim()) $($r.err.Trim())"}
 $null=Adb 'package' @('shell','dumpsys','package',$a.pkg);Done "$($a.pkg) installed" $null}
'LAUNCH'{
 $a=$apps[$App];Need $a.auth;NotWhileOverscanUnverified;if($state.installed.$App-ne'INSTALLED'){throw "$App is not installed"}
 # Refuse only when the Activity is on screen; a process kept alive after EXIT is normal Android behaviour.
 $act=Adb 'activities' @('shell','dumpsys','activity','activities');if(-not$act.ok){throw 'Activity dump failed; STOP'}
 if($act.out-match"(?m)^\s*(mResumedActivity|mFocusedActivity):.*$([regex]::Escape($a.activity))"){throw "$App is already on screen; press its EXIT button first"}
 $pre=Adb 'pre-logcat' @('logcat','-d','-v','threadtime') 40000;if(-not$pre.ok){throw 'logcat read failed; STOP'}
 $prior=@(TagLines $pre.out $a.tag);if($prior.Count){$state.lastTagLine.($App)=$prior[-1]}
 $r=Adb 'am-start' @('shell','am','start','-W','-n',$a.activity) 30000
 if($r.out-match'(?i)error|exception|violation'-or$r.out-notmatch'Status: ok'){throw "Launch refused: $($r.out.Trim())"}
 Start-Sleep -Seconds 4;$snap=Snapshot 'launch' $a;if($snap.lastLogLine){$state.lastTagLine.($App)=$snap.lastLogLine};$surface=@($snap.newLines|Where-Object{$_-match'Surface=\d+x\d+'})|Select-Object -Last 1
 $data=[ordered]@{amStart=$r.out.Trim();overscanState=$state.overscan;snapshot=$snap}
 if(-not$snap.appPids.Count){Done "launched but the app is not running 4 s later; check the screen" $data 3}
 if(-not$surface){Done "launched, but no NEW $($a.tag) Surface line from this process yet; run CAPTURE in a few seconds" $data 3}
 if(-not$snap.screenshotOk){Done "launched; $(([regex]::Match($surface,'Surface=\d+x\d+')).Value); but the screenshot failed. Run CAPTURE for a photo" $data 3}
 Done "launched ($Label, overscan $($state.overscan)); $(([regex]::Match($surface,'Surface=\d+x\d+')).Value); screenshot ok" $data}
'CAPTURE'{
 if(-not$App){$App=if($state.installed.decoder-in'INSTALLED','REVIEW_REQUIRED'){'decoder'}elseif($state.installed.grid-in'INSTALLED','REVIEW_REQUIRED'){'grid'}else{$null}}
 $a=if($App){$apps[$App]}else{$null};$snap=Snapshot 'capture' $a
 if($App-eq'decoder'){$null=Adb 'media-player' @('shell','dumpsys','media.player');$null=Adb 'surfaceflinger' @('shell','dumpsys','SurfaceFlinger')}
 if(-not$a){Done "captured '$Label' (no test app installed); screenshot $($snap.screenshotOk)" $snap}
 $stop=@($snap.newLines|Where-Object{$_-match'STOP|ERROR|WATCHDOG'})
 if($App-eq'decoder'){$b=@($snap.newLines|Where-Object{$_-match':\s*BEGIN clip='});$end=$null
  if($b.Count){$after=@($snap.newLines|Select-Object -Skip ([Array]::LastIndexOf([string[]]$snap.newLines,$b[-1])+1));$end=@($after|Where-Object{$_-match':\s*END wallMs='})|Select-Object -Last 1}
  $snap|Add-Member clipBegin ($b|Select-Object -Last 1);$snap|Add-Member clipEnd $end;$snap|Add-Member stopLines $stop
  # The "already reported" marker moves only when this capture reports a finished clip (END) or a STOP.
  if(($end-or$stop.Count)-and$snap.lastLogLine){$state.lastTagLine.($App)=$snap.lastLogLine}
  if($stop.Count){Done "STOP/ERROR in this clip: $($stop[-1])" $snap 3}
  if(-not$end){Done "no NEW complete clip result yet (BEGIN lines: $($b.Count)); wait for the on-screen result, then CAPTURE again" $snap 3}
  Done "clip result: $(($end-split'RDX\.DECODER\s*:\s*',2)[-1])" $snap}
 if($snap.lastLogLine){$state.lastTagLine.($App)=$snap.lastLogLine}
 Done "captured '$Label'; new $($a.tag) lines: $($snap.newLines.Count); last: $(@($snap.newLines)[-1])" $snap}
'OVERSCAN_APPLY'{
 Need 'OVERSCAN';if($state.overscan-ne'ZERO'){throw "Overscan state is $($state.overscan); restore first"}
 $g=Geometry 'pre';if($g.overscan.Count){throw 'Overscan already non-zero on the car; STOP'}
 $state.overscan='APPLY_PENDING';Save;$r=Adb 'wm-overscan' @('shell','wm','overscan','0,0,-581,0');$g2=Geometry 'post';$snap=Snapshot 'post' $null
 if($g2.overscan-contains', overscan (0,0,-581,0)'-and$g2.rects.mOverscanScreen-ceq'(0,0) 1920x720'){$state.overscan='APPLIED';Done "full width: $($g2.overscanScreen); system bounds $($g2.rects.mSystem). Look at Honda Home/top bar now; anything broken -> OVERSCAN_RESTORE" ([pscustomobject]@{geometry=$g2;screenshotOk=$snap.screenshotOk})}
 else{$state.overscan='UNKNOWN';Save;throw "Overscan result not as expected (exit $($r.code)): $($g2|ConvertTo-Json -Compress). Run OVERSCAN_RESTORE now."}}
'OVERSCAN_RESTORE'{
 Need 'OVERSCAN';$pre=Adb 'pre-logcat' @('logcat','-d','-v','threadtime') 40000
 $r=Adb 'wm-overscan-reset' @('shell','wm','overscan','reset');$g=Geometry 'post';$ref=RefRects
 $post=Adb 'post-logcat' @('logcat','-d','-v','threadtime') 40000;$null=Adb 'settings-file' @('shell','ls','-l','/data/system/display_settings.xml')
 $preLines=@($pre.out-split'\r?\n');$newLog=@((NewSince @($post.out-split'\r?\n') (@($preLines|Where-Object{$_.Trim()})|Select-Object -Last 1)).lines)
 $writeFail=@($newLog|Where-Object{$_-match'Failed to write display settings'})
 $runtimeOk=-not$g.overscan.Count-and(SameRects $g.rects $ref)
 if($runtimeOk-and$r.ok-and-not$writeFail.Count-and$pre.ok-and$post.ok){$state.overscan='ZERO';Done "restored: $($g.overscanScreen); all 11 window-policy rectangles match the baseline; no settings-file write error logged" $g}
 elseif($runtimeOk){$state.overscan='RUNTIME_ONLY';Save;throw "Screen restored NOW, but the saved file may still hold the change (reset command ok: $($r.ok); write error logged: $($writeFail.Count); log read ok: $($pre.ok -and $post.ok)). Run OVERSCAN_RESTORE again; if it repeats, STOP and keep the laptop connected."}
 else{$state.overscan='UNKNOWN';Save;throw "RESTORE NOT VERIFIED (exit $($r.code)): $($g|ConvertTo-Json -Compress -Depth 4). Run OVERSCAN_RESTORE again; if it still fails, STOP all other stages."}}
'UNINSTALL'{
 $a=$apps[$App];Need $a.auth;$ps=PkgState $a.pkg
 if($state.installed.$App-eq'ABSENT'-and$ps-eq'ABSENT'){throw "$App is not installed"}
 $r=Adb 'uninstall' @('uninstall',$a.pkg) 60000;$ps=PkgState $a.pkg;$up=(AppPids $a.pkg).Count-gt0
 if($ps-eq'ABSENT'-and-not$up){$state.installed.$App='ABSENT';Done "$($a.pkg) removed" $null}else{$state.installed.$App='REVIEW_REQUIRED';Save;throw "Uninstall not confirmed (exit $($r.code), package $ps, running $up); run UNINSTALL again"}}
'POSTCHECK'{
 $id=Identity;$g=Geometry 'final';$h=HondaHash 'final';$pk=[ordered]@{};foreach($k in $watchPkgs){$pk[$k]=PkgState $k};$b=$state.baseline
 $checks=[ordered]@{packagesAbsent=-not@($pk.Values|Where-Object{$_-ne'ABSENT'}).Count;overscanZero=-not$g.overscan.Count;overscanStateZero=$state.overscan-eq'ZERO'
  windowPolicyMatches=SameRects $g.rects (RefRects);sameBoot=$(if($b){$id.bootId-ceq$b.identity.bootId}else{'NOT_COMPARABLE (journal recovered)'})
  sameFingerprint=$id.fingerprint-ceq$(if($b){$b.identity.fingerprint}else{'Acura/gen1CBD_HS/gen1CBD_HS:5.1.1/LMY48P/14:user/release-keys'});hondaUnchanged=$h.sha256-ceq$(if($b){$b.honda.sha256}else{$stockHonda})}
 $ok=-not@($checks.Values|Where-Object{-not$_}).Count;$data=[ordered]@{checks=$checks;packages=$pk;geometry=$g;honda=$h;identity=$id}
 if($ok){Done "FINISHED: the measured checks match the baseline (packages, overscan, window policy, $(if($b){'boot, '}else{'boot NOT compared, '})fingerprint, Honda AA file). Honda private data is not compared." $data}
 else{Done "POSTCHECK_MISMATCH: $((@($checks.Keys|Where-Object{-not$checks[$_]}))-join', '). Review before leaving the car" $data 2}}
}
