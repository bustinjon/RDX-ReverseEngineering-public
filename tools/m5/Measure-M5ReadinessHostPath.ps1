#Requires -Version 7
# Offline, disarmed timing harness. Runs the REAL readiness collector (or a text-derived variant of it in a scratch
# mirror) against a FAKE adb executable that replays captured 2026-10-26 car output with measured delays, then mirrors
# the runner's ARM-stage freshness checks up to, never including, the arm command. No real ADB, no device, no runner stage.
param(
 [Parameter(Mandatory=$true)][string]$OutputDirectory,
 [int]$Runs=3,
 [ValidateSet('mean','max')][string[]]$Modes=@('mean','max'),
 [ValidateSet('current','no-sleep','deferred-writes','no-sleep+deferred-writes')][string[]]$Variants=@('current','no-sleep','deferred-writes','no-sleep+deferred-writes')
)
$ErrorActionPreference='Stop';$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. "$PSScriptRoot/M5ArmReadiness.ps1"
if(Test-Path -LiteralPath $OutputDirectory){throw 'Fresh harness output directory required'}
$full=[IO.Path]::GetFullPath($OutputDirectory)
if($full.StartsWith($root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)-or$full-eq$root){throw 'Harness output must be outside the project tree (use a scratch directory)'}
New-Item -ItemType Directory -Path $full|Out-Null;$OutputDirectory=(Resolve-Path -LiteralPath $full).Path
$preflight=(& "$PSScriptRoot/Test-M5FrozenPreflight.ps1"|ConvertFrom-Json)
$session="$root/analysis/parallel-aa-receiver/m5-retry-live-20261026-174603"
$captures=@(Get-ChildItem "$session" -Directory -Filter 'readiness-*'|Sort-Object Name)
$replay="$session/readiness-255a9a215c0a44c299247adb878092c6"
$liveCollector="$root/scripts/Test-M5ArmReadiness.ps1";$liveCore="$PSScriptRoot/M5ArmReadiness.ps1";$runnerPath="$PSScriptRoot/Invoke-M5FutureSession.ps1"

# Refuse if the runner text this harness mirrors has drifted: each group must appear complete and in this order.
$runner=Get-Content $runnerPath -Raw
# Limitation: presence/order/uniqueness only; extra work inserted between snippets is not detected.
function Assert-Ordered([string]$Text,[string[]]$Snippets){$at=-1;foreach($s in $Snippets){$i=$Text.IndexOf($s,$at+1);if($i-lt0-or([regex]::Matches($Text,[regex]::Escape($s))).Count-ne1){throw "Runner drifted from mirrored text (missing, duplicated or reordered); update harness first: $s"};$at=$i}}
Assert-Ordered $runner @(
 'function Save { $state|ConvertTo-Json -Depth 6|Set-Content "$SessionDirectory/session.json" }',
 'function Adb([string[]]$Arguments,[switch]$AllowFailure){',
 "`$stem=Join-Path `$SessionDirectory ((Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-m5-adb-'+[guid]::NewGuid().ToString('N').Substring(0,8))",
 '$si=[Diagnostics.ProcessStartInfo]::new();$si.FileName=$adb;$si.UseShellExecute=$false;$si.CreateNoWindow=$true;$si.RedirectStandardOutput=$true;$si.RedirectStandardError=$true',
 "foreach(`$a in (@('-s',`$Serial)+`$Arguments)){`$si.ArgumentList.Add(`$a)}",
 "`$p=[Diagnostics.Process]::new();`$p.StartInfo=`$si;`$utc=[DateTime]::UtcNow.ToString('o')",
 "if(`$Arguments-contains'REQUEST_ONCE_AFTER_M4_PASS'-and-not(Test-M5ReadinessFresh `$guard `$state.runId `$Serial ([Environment]::TickCount64))){throw 'ARM REFUSED at process-start boundary: readiness expired; no ADB arm issued'}",
 '[void]$p.Start()',
 " 'ARM'{if(`$state.phase-ne'INSTALLED'){throw 'Only one ARM allowed after fresh install'}",
 "`$guardDir=Join-Path `$SessionDirectory ('readiness-'+[guid]::NewGuid().ToString('N'))",
 '& "$root/scripts/Test-M5ArmReadiness.ps1" -AdbPath $adb -Serial $Serial -SessionDirectory $SessionDirectory -OutputDirectory $guardDir',
 '$guard=Get-Content "$guardDir/readiness.json" -Raw|ConvertFrom-Json',
 "if(-not(Test-M5ReadinessFresh `$guard `$state.runId `$Serial ([Environment]::TickCount64))){throw 'ARM REFUSED: current internal readiness failed or stale; no bypass'}",
 '$state|Add-Member -Force NoteProperty readinessDirectory $guardDir',
 "`$state|Add-Member -Force NoteProperty armedAt ([DateTime]::UtcNow.ToString('o'));`$state|Add-Member -Force NoteProperty deadlineUTC ([DateTime]::UtcNow.AddSeconds(300).ToString('o'));`$state.phase='ARM_ATTEMPTED';Save",
 "if([Environment]::TickCount64-`$guard.lastSampleStartMs-gt2000){throw 'ARM REFUSED: readiness expired while saving intent; preserve session, do not auto-retry'}",
 "(Adb -Arguments @('shell','am','startservice','-n',`$preflight.service,'-a','REQUEST_ONCE_AFTER_M4_PASS','--ez','m4_pass_confirmed','true','--ez','wait_for_target','true','--ei','vendor_id','6353','--ei','product_id','11521','--es','run_id',`$state.runId))")

# Fake adb: replays a fixed key->file map; unmapped commands (including any arm/install) fail with exit 1.
$fakeDir="$OutputDirectory/fake-adb";New-Item -ItemType Directory $fakeDir|Out-Null
@'
using System;using System.IO;using System.Threading;
public static class RdxFakeAdb{
 public static int Main(string[] a){
  string map=Environment.GetEnvironmentVariable("RDX_FAKE_ADB_MAP");
  if(map==null||a.Length<3||a[0]!="-s"){Console.Error.Write("fake-adb: missing map or bad arguments");return 2;}
  string key;string dest=null;
  if(a[2]=="pull"&&a.Length==5){key="pull|"+a[3];dest=a[4];}else{key=string.Join("|",a,2,a.Length-2);}
  foreach(string line in File.ReadAllLines(map)){
   string[] f=line.Split('\t');if(f.Length!=3||f[0]!=key)continue;
   int d=int.Parse(f[1]);if(d>0)Thread.Sleep(d);
   if(dest!=null){File.Copy(f[2],dest);}else{byte[] b=File.ReadAllBytes(f[2]);using(Stream o=Console.OpenStandardOutput()){o.Write(b,0,b.Length);}}
   return 0;
  }
  Console.Error.Write("fake-adb: unmapped command "+key);return 1;
 }
}
'@|Set-Content "$fakeDir/RdxFakeAdb.cs"
$fake="$fakeDir/rdx-fake-adb.exe"
powershell.exe -NoProfile -Command {param($Source,$Exe) Add-Type -Path $Source -OutputAssembly $Exe -OutputType ConsoleApplication} -args "$fakeDir/RdxFakeAdb.cs",$fake
if(-not(Test-Path -LiteralPath $fake -PathType Leaf)){throw 'Fake adb build failed'}
if([IO.Path]::GetFullPath($fake)-eq[IO.Path]::GetFullPath($preflight.adb)-or[IO.Path]::GetFileName($fake)-eq'adb.exe'){throw 'Fake adb must never coincide with the real adb'}
$fakeHash=(Get-FileHash $fake).Hash

# Command keys, replay output and measured real durations (all three captures).
function Key($Arguments){if($Arguments[0]-eq'pull'){"pull|$($Arguments[1])"}else{$Arguments-join'|'}}
$durations=@{};foreach($c in $captures){foreach($rec in @(Get-Content "$($c.FullName)/commands.json" -Raw|ConvertFrom-Json)){$k=Key $rec.arguments;if(-not$durations[$k]){$durations[$k]=[Collections.Generic.List[long]]::new()};$durations[$k].Add($rec.endMs-$rec.startMs)}}
$source=@{};foreach($rec in @(Get-Content "$replay/commands.json" -Raw|ConvertFrom-Json)){$k=Key $rec.arguments;if($source.ContainsKey($k)){continue}
 $source[$k]=if($rec.arguments[0]-eq'pull'){"$replay/$([IO.Path]::GetFileName($rec.arguments[2]))"}else{"$replay/$($rec.stdout)"}}
foreach($k in $source.Keys){if(-not(Test-Path -LiteralPath $source[$k] -PathType Leaf)){throw "Replay source missing for $k"}}

function Invoke-Fake([string[]]$Arguments,[string]$Scratch){
 $si=[Diagnostics.ProcessStartInfo]::new();$si.FileName=$fake;$si.UseShellExecute=$false;$si.CreateNoWindow=$true;$si.RedirectStandardOutput=$true;$si.RedirectStandardError=$true
 foreach($x in @('-s','00000000')+$Arguments){$si.ArgumentList.Add($x)}
 $p=[Diagnostics.Process]::new();$p.StartInfo=$si;$t=[Diagnostics.Stopwatch]::StartNew();[void]$p.Start()
 $o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync();[void]$p.WaitForExit(15000);$so=$o.GetAwaiter().GetResult();$se=$e.GetAwaiter().GetResult();$code=$p.ExitCode;$p.Dispose()
 $n=[guid]::NewGuid().ToString('N');[IO.File]::WriteAllText("$Scratch/$n.out",$so);[IO.File]::WriteAllText("$Scratch/$n.err",$se)
 if($code-ne0){throw "Fake adb calibration failed for $($Arguments-join' '): $se"};return $t.Elapsed.TotalMilliseconds
}
# Calibrate the fake's own spawn + read + write cost per key so delay = measured real duration - fake overhead.
$cal="$OutputDirectory/calibration";New-Item -ItemType Directory $cal|Out-Null
$zero="$cal/map-zero.tsv";($source.Keys|ForEach-Object{"$_`t0`t$($source[$_])"})|Set-Content $zero;$env:RDX_FAKE_ADB_MAP=$zero
$overhead=@{}
foreach($k in $source.Keys){
 $times=foreach($i in 1..5){$args2=if($k.StartsWith('pull|')){@('pull',$k.Substring(5),"$cal/$([guid]::NewGuid().ToString('N')).bin")}else{$k-split'\|'};Invoke-Fake $args2 $cal}
 $overhead[$k]=[long](@($times|Sort-Object)[2])
}
$maps=@{}
foreach($mode in $Modes){
 $lines=foreach($k in $source.Keys){$real=if($mode-eq'max'){($durations[$k]|Measure-Object -Maximum).Maximum}else{($durations[$k]|Measure-Object -Average).Average};"$k`t$([Math]::Max(0,[long][Math]::Round($real-$overhead[$k])))`t$($source[$k])"}
 $maps[$mode]="$cal/map-$mode.tsv";$lines|Set-Content $maps[$mode]
}

# Variant collectors: derived from the live collector text by exact single-occurrence replacements, in scratch mirrors.
$liveText=Get-Content $liveCollector -Raw
$edits=@{
 'no-sleep'=@(,@('  Start-Sleep -Milliseconds 400','  '))
 'deferred-writes'=@(
  @('$clock=[Environment]::TickCount64','$clock=[Environment]::TickCount64;$script:pendingWrites=[Collections.Generic.List[object]]::new()'),
  @('[IO.File]::WriteAllText("$OutputDirectory/$n.stdout.txt",$stdout);[IO.File]::WriteAllText("$OutputDirectory/$n.stderr.txt",$stderr)','$script:pendingWrites.Add(@("$OutputDirectory/$n.stdout.txt",$stdout,"$OutputDirectory/$n.stderr.txt",$stderr))'),
  @('ConvertTo-Json -InputObject $records.ToArray() -Depth 6|Set-Content "$OutputDirectory/commands.json"','foreach($w in $script:pendingWrites){[IO.File]::WriteAllText($w[0],$w[1]);[IO.File]::WriteAllText($w[2],$w[3])};ConvertTo-Json -InputObject $records.ToArray() -Depth 6|Set-Content "$OutputDirectory/commands.json"'))
}
$collectors=@{}
foreach($v in $Variants){
 $text=$liveText
 foreach($part in @($v-split'\+'|Where-Object{$_-ne'current'})){foreach($e in $edits[$part]){$c=([regex]::Matches($text,[regex]::Escape($e[0]))).Count;if($c-ne1){throw "Variant $v edit not unique ($c): $($e[0])"};$text=$text.Replace($e[0],$e[1])}}
 $mirror="$OutputDirectory/variants/$($v-replace'\+','_')";New-Item -ItemType Directory "$mirror/scripts","$mirror/tools/m5" -Force|Out-Null
 Copy-Item $liveCore "$mirror/tools/m5/M5ArmReadiness.ps1";if((Get-FileHash "$mirror/tools/m5/M5ArmReadiness.ps1").Hash-ne(Get-FileHash $liveCore).Hash){throw 'Core copy mismatch'}
 Set-Content "$mirror/scripts/Test-M5ArmReadiness.ps1" $text -NoNewline;$collectors[$v]="$mirror/scripts/Test-M5ArmReadiness.ps1"
}

# Session template: the real session's provenance files, with phase restored to INSTALLED in the copy only.
$template="$OutputDirectory/session-template";New-Item -ItemType Directory $template|Out-Null
foreach($f in 'fresh-install-proof.json','m5-installed-package.txt','m5-install-success.txt','packages-before-install.txt'){Copy-Item "$session/$f" "$template/$f"}
$st=Get-Content "$session/session.json" -Raw|ConvertFrom-Json;$st.phase='INSTALLED';$st|ConvertTo-Json -Depth 6|Set-Content "$template/session.json"

$results=[Collections.Generic.List[object]]::new();$Serial='00000000';$i=0
foreach($run in 1..$Runs){foreach($mode in $Modes){foreach($v in $Variants){
 $i++;$SessionDirectory="$OutputDirectory/runs/$i-$($v-replace'\+','_')-$mode";Copy-Item $template $SessionDirectory -Recurse
 $state=Get-Content "$SessionDirectory/session.json" -Raw|ConvertFrom-Json
 function Save { $state|ConvertTo-Json -Depth 6|Set-Content "$SessionDirectory/session.json" }
 $env:RDX_FAKE_ADB_MAP=$maps[$mode];$guardDir=Join-Path $SessionDirectory ('readiness-'+[guid]::NewGuid().ToString('N'))
 & $collectors[$v] -AdbPath $fake -Serial $Serial -SessionDirectory $SessionDirectory -OutputDirectory $guardDir|Out-Host
 $tReturn=[Environment]::TickCount64
 $guard=Get-Content "$guardDir/readiness.json" -Raw|ConvertFrom-Json
 $t64=[Environment]::TickCount64;$ok64=Test-M5ReadinessFresh $guard $state.runId $Serial $t64
 $t67=$null;$ok67=$null;$t19=$null;$ok19=$null
 if($ok64){
  $state|Add-Member -Force NoteProperty readinessDirectory $guardDir
  $state|Add-Member -Force NoteProperty armedAt ([DateTime]::UtcNow.ToString('o'));$state|Add-Member -Force NoteProperty deadlineUTC ([DateTime]::UtcNow.AddSeconds(300).ToString('o'));$state.phase='ARM_ATTEMPTED';Save
  $t67=[Environment]::TickCount64;$ok67=-not($t67-$guard.lastSampleStartMs-gt2000)
  if($ok67){
   # Mirror of runner Adb() up to, never including, Process.Start, called with the complete arm argument array.
   function MirrorAdb([string[]]$Arguments,[switch]$AllowFailure){
    $stem=Join-Path $SessionDirectory ((Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-m5-adb-'+[guid]::NewGuid().ToString('N').Substring(0,8))
    $si=[Diagnostics.ProcessStartInfo]::new();$si.FileName=$fake;$si.UseShellExecute=$false;$si.CreateNoWindow=$true;$si.RedirectStandardOutput=$true;$si.RedirectStandardError=$true
    foreach($a in (@('-s',$Serial)+$Arguments)){$si.ArgumentList.Add($a)}
    $p=[Diagnostics.Process]::new();$p.StartInfo=$si;$utc=[DateTime]::UtcNow.ToString('o')
    $t=[Environment]::TickCount64;$ok=($Arguments-contains'REQUEST_ONCE_AFTER_M4_PASS')-and(Test-M5ReadinessFresh $guard $state.runId $Serial $t);$p.Dispose()
    return @($t,$ok)
   }
   $t19,$ok19=MirrorAdb -Arguments @('shell','am','startservice','-n',$preflight.service,'-a','REQUEST_ONCE_AFTER_M4_PASS','--ez','m4_pass_confirmed','true','--ez','wait_for_target','true','--ei','vendor_id','6353','--ei','product_id','11521','--es','run_id',$state.runId)
  }
 }
 $samples=@(Get-Content "$guardDir/samples.json" -Raw|ConvertFrom-Json);$last=if($guard.lastSampleStartMs){$guard.lastSampleStartMs}else{0}
 $gaps=@(for($j=1;$j-lt$samples.Count;$j++){$samples[$j].startMs-$samples[$j-1].startMs})
 $row=[ordered]@{run=$run;mode=$mode;variant=$v;result=$guard.result;reasons=@($guard.reasons)-join'; ';samples=$samples.Count
  durations=@($samples|ForEach-Object{$_.endMs-$_.startMs})-join'/';gaps=$gaps-join'/';maxGap=($gaps|Measure-Object -Maximum).Maximum
  ageCreated=$guard.createdMs-$last;ageReturned=$tReturn-$last;ageLine64=$t64-$last;line64=$ok64;ageLine67=if($t67){$t67-$last};line67=$ok67;ageLine19=if($t19){$t19-$last};line19=$ok19
  mirroredChecksPassed=[bool]($ok64-and$ok67-and$ok19)}
 $results.Add([pscustomobject]$row);Write-Output ("[{0}] {1,-26} {2,-4} {3,-16} n={4} gaps={5,-24} ages created/return/64/67/19={6}/{7}/{8}/{9}/{10} mirroredChecksPassed={11}" -f $i,$v,$mode,$guard.result,$samples.Count,$row.gaps,$row.ageCreated,$row.ageReturned,$row.ageLine64,$row.ageLine67,$row.ageLine19,$row.mirroredChecksPassed)
}}}
Remove-Item Env:RDX_FAKE_ADB_MAP
$summary=foreach($g in ($results|Group-Object variant,mode)){$r=$g.Group;[pscustomobject][ordered]@{variant=$r[0].variant;mode=$r[0].mode;runs=$r.Count;mirroredChecksPassed=@($r|Where-Object mirroredChecksPassed).Count;maxGap=($r.maxGap|Measure-Object -Maximum).Maximum;minGapMargin=2000-($r.maxGap|Measure-Object -Maximum).Maximum
 worstAgeAtLine19OrLastCheck=(@($r|ForEach-Object{if($_.ageLine19){$_.ageLine19}elseif($_.ageLine67){$_.ageLine67}else{$_.ageLine64}})|Measure-Object -Maximum).Maximum;samples=(@($r.samples)|Sort-Object -Unique)-join','}}
[ordered]@{schema=1;scope='OFFLINE DISARMED HARNESS: fake adb replay of 2026-10-26 captures; mirrored checks stop before Process.Start; margins are replay estimates, not live qualification';fakeAdbSHA256=$fakeHash;liveCollectorSHA256=(Get-FileHash $liveCollector).Hash;liveCoreSHA256=(Get-FileHash $liveCore).Hash;runnerSHA256=(Get-FileHash $runnerPath).Hash;calibrationOverheadMs=$overhead;results=$results;summary=@($summary)}|ConvertTo-Json -Depth 6|Set-Content "$OutputDirectory/harness-results.json"
Write-Output '';$summary|Format-Table -AutoSize|Out-String -Width 200
