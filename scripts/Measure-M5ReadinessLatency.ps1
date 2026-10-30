#Requires -Version 7
param(
 [Parameter(Mandatory=$true)][string]$AdbPath,
 [Parameter(Mandatory=$true)][string]$Serial,
 [Parameter(Mandatory=$true)][string]$OutputDirectory,
 [ValidateRange(4,40)][int]$SamplesPerCadence=12,
 [ValidateSet('serial-sleep400','serial-nosleep')][string[]]$Cadences=@('serial-sleep400','serial-nosleep'),
 [switch]$IncludePackageDumpAll
)
# READ ONLY ON DEVICE. Measures readiness-collector latency with the collector's exact serial command set, order and
# per-command persistence. Never adds packages, starts apps, arms, or changes settings. Artifact type
# m5-latency-measurement: not a readiness result and never consumed by the runner. Stops at the first sign that the
# car is not at an unlocked Honda Home (lock-task not INACTIVE, foreground not Honda Home).
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
. "$root/tools/m5/M5ArmReadiness.ps1"
if($Serial-ne'00000000'){throw 'Wrong target serial; no ADB invoked'}
if(-not(Test-Path -LiteralPath $AdbPath -PathType Leaf)){throw 'Explicit ADB executable not found; no ADB invoked'}
if(Test-Path -LiteralPath $OutputDirectory){throw 'Fresh output directory required; no ADB invoked'}
# Framework pins come from the collector's single active pin declaration; anything else refuses before any ADB.
$pinPattern="@\('framework',@\('([0-9A-F]{64})','([0-9A-F]{64})'\)\),@\('services',@\('([0-9A-F]{64})','([0-9A-F]{64})'\)\)"
$collectorText=Get-Content "$root/scripts/Test-M5ArmReadiness.ps1" -Raw
$pinLines=@($collectorText-split'\r?\n'|Where-Object{$_-match$pinPattern})
if($collectorText.Contains('<#')-or$pinLines.Count-ne1-or$pinLines[0]-notmatch('^\s*foreach\(\$item in @\('+$pinPattern)){throw 'Collector pin declaration missing, duplicated or not the active foreach line; no ADB invoked'}
$m=[regex]::Match($pinLines[0],$pinPattern);$pins=@{framework=@($m.Groups[1].Value,$m.Groups[2].Value);services=@($m.Groups[3].Value,$m.Groups[4].Value)}
New-Item -ItemType Directory -Path $OutputDirectory|Out-Null;$OutputDirectory=(Resolve-Path -LiteralPath $OutputDirectory).Path
$commandLog="$OutputDirectory/latency-commands.jsonl";$sampleLog="$OutputDirectory/latency-samples.jsonl";$sleepLog="$OutputDirectory/latency-sleeps.jsonl"
$records=[Collections.Generic.List[object]]::new();$samples=[Collections.Generic.List[object]]::new();$sleeps=[Collections.Generic.List[object]]::new()
$script:frameworkVerified=$false;$failure='';$abort='';$finished=$false;$script:live=[Collections.Generic.List[object]]::new()
$sampleFields=@(@('lockBefore',@('shell','service','call','activity','217')),@('activities',@('shell','dumpsys','activity','activities')),@('window',@('shell','dumpsys','window')),@('services',@('shell','dumpsys','activity','services')),@('package',@('shell','dumpsys','package','com.rdx.fullscreen.m5permission')),@('packages',@('shell','pm','list','packages','-u')),@('processes',@('shell','ps')),@('display',@('shell','dumpsys','display')),@('lockAfter',@('shell','service','call','activity','217')))
$errorText='(?im)(permission denied|dump timeout|unknown argument|^\s*error\b|\bexception\b|:\s*not found\s*$|\bno such file|can''t find service)'
function Test-Allowed([string[]]$Arguments){
 $key=$Arguments -join '|'
 $allowed=$key-match '^shell\|getprop\|ro\.(build\.(fingerprint|version\.(sdk|release))|product\.cpu\.abi)$'-or$key-in@(
  'shell|dumpsys|activity|activities','shell|dumpsys|activity|services','shell|dumpsys|window','shell|dumpsys|display',
  'shell|dumpsys|package|com.rdx.fullscreen.m5permission','shell|pm|list|packages|-u','shell|ps')
 if($key-eq'shell|dumpsys|package|packages'){$allowed=[bool]$IncludePackageDumpAll}
 if($key-eq'shell|service|call|activity|217'){$allowed=$script:frameworkVerified}
 if($Arguments.Count-eq3-and$Arguments[0]-eq'pull'){$local=[IO.Path]::GetFullPath($Arguments[2]);$allowed=$local.StartsWith($OutputDirectory+[IO.Path]::DirectorySeparatorChar)-and$Arguments[1]-in@('/system/framework/framework.jar','/system/framework/services.jar')}
 if(-not$allowed){throw "Internal read-only measurement allowlist refusal: $key"}
}
function Read([string[]]$Arguments,[string]$Phase,[string]$Field='',[int]$Sample=-1){
 Test-Allowed $Arguments
 $si=[Diagnostics.ProcessStartInfo]::new();$si.FileName=$AdbPath;$si.UseShellExecute=$false;$si.CreateNoWindow=$true;$si.RedirectStandardOutput=$true;$si.RedirectStandardError=$true
 foreach($a in @('-s',$Serial)+$Arguments){$si.ArgumentList.Add($a)}
 $p=[Diagnostics.Process]::new();$p.StartInfo=$si;$start=[Environment]::TickCount64;$utc=[DateTime]::UtcNow.ToString('o');[void]$p.Start();$script:live.Add($p)
 try{
  $out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$timeout=-not$p.WaitForExit(15000);if($timeout){$p.Kill();$p.WaitForExit()}
  $stdout=$out.GetAwaiter().GetResult();$stderr=$err.GetAwaiter().GetResult();$code=$p.ExitCode;$exitUtc=$p.ExitTime.ToUniversalTime().ToString('o');$procMs=($p.ExitTime-$p.StartTime).TotalMilliseconds
 }finally{try{if(-not$p.HasExited){$p.Kill();[void]$p.WaitForExit(5000)}}catch{};$p.Dispose();[void]$script:live.Remove($p)}
 $n=$records.Count
 [IO.File]::WriteAllText("$OutputDirectory/$n.stdout.txt",$stdout);[IO.File]::WriteAllText("$OutputDirectory/$n.stderr.txt",$stderr)
 $r=[pscustomobject]@{index=$n;phase=$Phase;sample=$Sample;field=$Field;utc=$utc;startMs=$start;endMs=[Environment]::TickCount64;exitUtc=$exitUtc;processMs=$procMs;arguments=$Arguments;exit=$code;timeout=$timeout;stdoutChars=$stdout.Length;stdoutErrorText=($stdout-match$errorText);stdout="$n.stdout.txt";stderr="$n.stderr.txt"}
 $records.Add($r);Add-Content $commandLog ($r|ConvertTo-Json -Compress -Depth 4)
 if($timeout-or$code-ne0-or$stderr-match'(?i)error|denied|unauthorized|offline'-or$r.stdoutErrorText){throw "Read-only query failed or returned error text: $($Arguments-join' ')"};return $stdout
}
function Sample-Serial([string]$Phase,[int]$Index){
 $s=[ordered]@{phase=$Phase;sample=$Index;startMs=[Environment]::TickCount64};$v=@{}
 foreach($f in $sampleFields){$v[$f[0]]=Read $f[1] $Phase $f[0] $Index}
 $s.endMs=[Environment]::TickCount64
 $s.lockBefore=Get-M5LockTaskState $v.lockBefore;$s.lockAfter=Get-M5LockTaskState $v.lockAfter;$s.foreground=Get-M5Foreground $v.activities $v.window
 $o=[pscustomobject]$s;$samples.Add($o);Add-Content $sampleLog ($o|ConvertTo-Json -Compress)
 if($s.lockBefore-ne'INACTIVE'-or$s.lockAfter-ne'INACTIVE'){$script:abort="Lock-task not INACTIVE in $Phase sample $Index; measurement stopped"}
 elseif(-not$s.foreground){$script:abort="Foreground not Honda Home in $Phase sample $Index; measurement stopped"}
}
try{
 try{
  $identity=Get-M5IdentitySafe $Serial (Read @('shell','getprop','ro.build.fingerprint') 'identity') (Read @('shell','getprop','ro.build.version.sdk') 'identity') (Read @('shell','getprop','ro.build.version.release') 'identity') (Read @('shell','getprop','ro.product.cpu.abi') 'identity')
  if(-not$identity){throw 'RDX identity/API/ABI mismatch'}
  foreach($item in 'framework','services'){[void](Read @('pull',"/system/framework/$item.jar","$OutputDirectory/$item.jar") 'pins');if((Get-FileHash "$OutputDirectory/$item.jar").Hash-notin$pins[$item]){throw 'Framework binary not a reviewed getter/implementation pair; refuse numeric Binder transaction'}}
  $script:frameworkVerified=$true
  # Cadences alternate in blocks of 4 samples so order effects (cold start, drift) do not land on one cadence.
  $done=@{};foreach($c in $Cadences){$done[$c]=0}
  while(-not$script:abort-and@($Cadences|Where-Object{$done[$_]-lt$SamplesPerCadence}).Count){
   foreach($c in $Cadences){
    for($b=0;$b-lt4-and$done[$c]-lt$SamplesPerCadence-and-not$script:abort;$b++){
     Sample-Serial $c $done[$c];$done[$c]++
     if($c-eq'serial-sleep400'-and$done[$c]-lt$SamplesPerCadence-and-not$script:abort){$t=[Diagnostics.Stopwatch]::StartNew();Start-Sleep -Milliseconds 400;$z=[pscustomobject]@{requested=400;actualMs=$t.Elapsed.TotalMilliseconds};$sleeps.Add($z);Add-Content $sleepLog ($z|ConvertTo-Json -Compress)}
    }
    if($script:abort){break}
   }
  }
  if(-not$script:abort-and$IncludePackageDumpAll){for($i=0;$i-lt5;$i++){[void](Read @('shell','dumpsys','package','packages') 'package-dump-all' 'packagesAll' $i)}}
  $finished=$true
 }catch{$failure=$_.Exception.Message;$finished=$true}
}finally{
 foreach($p in @($script:live)){try{if(-not$p.HasExited){$p.Kill()}}catch{};try{$p.Dispose()}catch{}}
 function Stats($v){$v=@($v|Sort-Object);if(-not$v.Count){return $null};[ordered]@{n=$v.Count;min=$v[0];p50=$v[[int][Math]::Floor(($v.Count-1)*0.5)];max=$v[-1]}}
 $byPhase=[ordered]@{};foreach($g in ($samples|Group-Object phase)){$list=@($g.Group|Sort-Object startMs);$gaps=@(for($i=1;$i-lt$list.Count;$i++){if($list[$i].sample-eq$list[$i-1].sample+1-and$list[$i].startMs-$list[$i-1].endMs-lt1000){$list[$i].startMs-$list[$i-1].startMs}})
  $byPhase[$g.Name]=[ordered]@{sampleDurationMs=Stats @($list|ForEach-Object{$_.endMs-$_.startMs});startGapWithinBlockMs=Stats $gaps}}
 $byCommand=[ordered]@{};foreach($g in ($records|Group-Object {"$($_.phase)|$($_.arguments-join' ')"})){$byCommand[$g.Name]=[ordered]@{hostMs=Stats @($g.Group|ForEach-Object{$_.endMs-$_.startMs});processMs=Stats @($g.Group|ForEach-Object{$_.processMs});stdoutChars=Stats @($g.Group|ForEach-Object{$_.stdoutChars});errorTextHits=@($g.Group|Where-Object stdoutErrorText).Count}}
 $result=if(-not$finished){'INTERRUPTED'}elseif($failure){'INCOMPLETE'}elseif($abort){'STOPPED_ENVIRONMENT'}else{'COMPLETE'}
 [ordered]@{artifactType='m5-latency-measurement';schema=1;result=$result;failure=$failure;abort=$abort;serial=$Serial;deviceMutation='NONE (intended commands are read-only)';scope='LATENCY MEASUREMENT ONLY: not readiness, not consumed by the runner; M5 absent so the M5 package dump is shorter than in a real ARM';samplesPerCadence=$SamplesPerCadence;cadences=$Cadences;includePackageDumpAll=[bool]$IncludePackageDumpAll;sleepActualMs=Stats @($sleeps|ForEach-Object{$_.actualMs});byPhase=$byPhase;byCommand=$byCommand}|ConvertTo-Json -Depth 6|Set-Content "$OutputDirectory/latency-summary.json"
 Write-Output "LATENCY MEASUREMENT $result$(if($failure){": $failure"}elseif($abort){": $abort"})"
}
if($failure-or$abort){exit 1}
