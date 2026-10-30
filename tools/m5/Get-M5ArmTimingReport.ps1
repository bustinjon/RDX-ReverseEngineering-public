param([Parameter(Mandatory=$true)][string]$SessionDirectory,[string]$ConsoleLog)
# OFFLINE, READ ONLY. Reconstructs readiness/ARM timing margins from a saved M5 session directory.
# Writes nothing; prints JSON. No ADB. Limits mirror tools/m5/M5ArmReadiness.ps1 and the runner (all 2000 ms).
$ErrorActionPreference='Stop'
$SessionDirectory=(Resolve-Path -LiteralPath $SessionDirectory).Path
$limit=2000
# ConvertFrom-Json (pwsh 7) already turns ISO strings into DateTime; converting those back to text would drop milliseconds.
function Utc($s){if($s-is[DateTime]){return $s.ToUniversalTime()};[DateTime]::Parse([string]$s,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AdjustToUniversal-bor[Globalization.DateTimeStyles]::AssumeUniversal)}
$state=Get-Content -LiteralPath "$SessionDirectory/session.json" -Raw|ConvertFrom-Json
$runner=@();if(Test-Path -LiteralPath "$SessionDirectory/commands.jsonl"){$runner=@(Get-Content -LiteralPath "$SessionDirectory/commands.jsonl"|Where-Object{$_.Trim()}|ForEach-Object{$_|ConvertFrom-Json})}
$armCmd=@($runner|Where-Object{$_.arguments-contains'REQUEST_ONCE_AFTER_M4_PASS'})
$used='';if($null-ne$state.PSObject.Properties['readinessDirectory']){$used=[IO.Path]::GetFileName([string]$state.readinessDirectory)}
# Readiness runs whose ARM was refused after intent but before the arm process (runner restores INSTALLED).
$notIssued=@{};if($null-ne$state.PSObject.Properties['notIssuedArms']){foreach($n in @($state.notIssuedArms)){$notIssued[[IO.Path]::GetFileName([string]$n.readinessDirectory)]=$n}}
$reports=foreach($dir in @(Get-ChildItem -LiteralPath $SessionDirectory -Directory -Filter 'readiness-*'|Sort-Object CreationTimeUtc)){
 $r=Get-Content -LiteralPath "$($dir.FullName)/readiness.json" -Raw|ConvertFrom-Json
 $samples=@();if(Test-Path -LiteralPath "$($dir.FullName)/samples.json"){$samples=@(Get-Content -LiteralPath "$($dir.FullName)/samples.json" -Raw|ConvertFrom-Json)}
 $cmds=@();if(Test-Path -LiteralPath "$($dir.FullName)/commands.json"){$cmds=@(Get-Content -LiteralPath "$($dir.FullName)/commands.json" -Raw|ConvertFrom-Json)}
 $durations=@($samples|ForEach-Object{[long]$_.endMs-[long]$_.startMs})
 $gaps=@(for($i=1;$i-lt$samples.Count;$i++){[long]$samples[$i].startMs-[long]$samples[$i-1].startMs})
 $byKey=[ordered]@{}
 foreach($c in $cmds){$k=@($c.arguments)-join' ';$ms=[long]$c.endMs-[long]$c.startMs;$bytes=0;$f=Join-Path $dir.FullName $c.stdout;if(Test-Path -LiteralPath $f){$bytes=(Get-Item -LiteralPath $f).Length}
  if(-not$byKey.Contains($k)){$byKey[$k]=[Collections.Generic.List[object]]::new()};$byKey[$k].Add([pscustomobject]@{ms=$ms;bytes=$bytes;exit=$c.exit;timeout=$c.timeout})}
 $commandStats=foreach($k in $byKey.Keys){$v=$byKey[$k];$m=$v|Measure-Object ms -Minimum -Maximum;[ordered]@{command=$k;count=$v.Count;minMs=$m.Minimum;maxMs=$m.Maximum;maxStdoutBytes=($v|Measure-Object bytes -Maximum).Maximum;failures=@($v|Where-Object{$_.exit-ne0-or$_.timeout}).Count}}
 # readiness.json stores utc and createdMs back to back, which ties the TickCount64 clock to UTC (about 1 ms).
 $lastStartUtc=$null;if($r.lastSampleStartMs){$lastStartUtc=(Utc $r.utc).AddMilliseconds(-([long]$r.createdMs-[long]$r.lastSampleStartMs))}
 $o=[ordered]@{directory=$dir.Name;usedForArm=($dir.Name-eq$used);result=$r.result;reasons=@($r.reasons);sampleCount=$r.sampleCount
  sampleDurationsMs=$durations;maxSampleDurationMs=if($durations.Count){($durations|Measure-Object -Maximum).Maximum}else{$null}
  startGapsMs=$gaps;maxGapMs=if($gaps.Count){($gaps|Measure-Object -Maximum).Maximum}else{$null}
  spanMs=if($samples.Count){[long]$samples[-1].startMs-[long]$samples[0].startMs}else{$null}
  resultAgeMs=if($r.lastSampleStartMs){[long]$r.createdMs-[long]$r.lastSampleStartMs}else{$null}
  lastSampleStartUtc=if($lastStartUtc){$lastStartUtc.ToString('o')}else{$null};commands=@($commandStats)}
 $o.gapMarginMs=if($null-ne$o.maxGapMs){$limit-$o.maxGapMs}else{$null};$o.durationMarginMs=if($null-ne$o.maxSampleDurationMs){$limit-$o.maxSampleDurationMs}else{$null}
 # Runner checkpoints, only for the readiness run the runner actually used.
 if($notIssued.ContainsKey($dir.Name)-and$lastStartUtc){$n=$notIssued[$dir.Name];$o.armNotIssued=$true;$o.notIssuedReason=$n.reason
  $o.ageAtArmedAtMs=[math]::Round(((Utc $n.armedAt)-$lastStartUtc).TotalMilliseconds);$o.ageAtRefusalRecordMs=[math]::Round(((Utc $n.refusedAt)-$lastStartUtc).TotalMilliseconds)}
 if($o.usedForArm-and$lastStartUtc){
  if($null-ne$state.PSObject.Properties['armedAt']){$a=((Utc $state.armedAt)-$lastStartUtc).TotalMilliseconds;$o.ageAtArmedAtMs=[math]::Round($a);$o.note64_67='armedAt is written after the line-64 check and before the line-67 check: it lower-bounds the line-67 age and upper-bounds the line-64 age'}
  if($armCmd.Count){$a=((Utc $armCmd[0].utc)-$lastStartUtc).TotalMilliseconds;$o.ageAtArmProcessStartMs=[math]::Round($a);$o.armProcessStartMarginMs=$limit-[math]::Round($a);$o.note19='the runner records utc immediately before the line-19 freshness check and Process.Start'}
 }
 [pscustomobject]$o
}
$refusal=$null
if($ConsoleLog){$text=Get-Content -LiteralPath $ConsoleLog -Raw
 # The console log is cumulative (tee -Append): report the LAST ARM outcome only, so an earlier refusal does not mask a later try.
 $marks=[ordered]@{'line19-process-start'='ARM REFUSED at process-start boundary';'line67-after-intent-save'='readiness expired while saving intent';'line64-after-collector'='current internal readiness failed or stale';'precondition'='ARM REFUSED before ADB';'collector-not-ready'='NOT_READY_TO_ARM';'arm-not-confirmed'='ARM not confirmed';'none-latest-arm-issued'='SWAP TO PHONE NOW'}
 $best=-1;$refusal='none-found';foreach($k in $marks.Keys){$i=$text.LastIndexOf($marks[$k]);if($i-gt$best){$best=$i;$refusal=$k}}}
[ordered]@{schema=1;scope='OFFLINE READ ONLY: no ADB, writes nothing';sessionDirectory=$SessionDirectory;phase=$state.phase;limitMs=$limit
 armProcessStarted=[bool]$armCmd.Count;armProcessEvidence='commands.jsonl record exists only if the adb arm process ran to completion; also check arm-response.txt'
 armResponseFile=(Test-Path -LiteralPath "$SessionDirectory/arm-response.txt");consoleRefusal=$refusal;readinessRuns=@($reports)}|ConvertTo-Json -Depth 6
