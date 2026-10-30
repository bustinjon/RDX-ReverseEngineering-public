# Offline, host-only, writes no files. Pins the pure-core timing boundaries of the readiness core at their exact
# limits, using real captured car text (2026-10-26 session) as sample content. No ADB, no device. Collector-only
# limits (20 s soft loop expiry, 15 s per-command wait) are only statically pinned here.
$ErrorActionPreference='Stop';$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. "$PSScriptRoot/M5ArmReadiness.ps1"
$session="$root/analysis/parallel-aa-receiver/m5-retry-live-20261026-174603"
$capture="$session/readiness-255a9a215c0a44c299247adb878092c6"
$real=@(Get-Content "$capture/samples.json" -Raw|ConvertFrom-Json)
$realResult=Get-Content "$capture/readiness.json" -Raw|ConvertFrom-Json
$pr=Get-Content "$session/fresh-install-proof.json" -Raw|ConvertFrom-Json
$proof=[pscustomobject]@{uid=$pr.uid;firstInstallTime=$pr.firstInstallTime;lastUpdateTime=$pr.lastUpdateTime}
$gapReason='Polling gap/clock order unsafe';$durReason='Critical snapshot exceeds 2000 ms or clock regressed'
$spanReason='Stabilization duration incomplete';$staleReason='Final precheck stale or time invalid'
$policyReason='Stabilization policy must be 5..15 seconds';$countReason='CHECK A and CHECK B plus stabilization required'
$script:checks=0;$script:failed=[Collections.Generic.List[string]]::new()
function Check([bool]$Condition,[string]$Name){$script:checks++;if(-not$Condition){$script:failed.Add($Name)}}
function Seq([long[]]$Starts,[long]$Duration=1500){
 $out=[Collections.Generic.List[object]]::new()
 for($i=0;$i-lt$Starts.Count;$i++){$t=$real[$i%$real.Count];$o=[ordered]@{};foreach($p in $t.PSObject.Properties){$o[$p.Name]=$p.Value};$o.startMs=$Starts[$i];$o.endMs=$Starts[$i]+$Duration;$out.Add([pscustomobject]$o)}
 return ,$out.ToArray()
}
function Even([long]$Gap,[long]$Span=5000){$s=[Collections.Generic.List[long]]::new();$s.Add(0);while($s[-1]-lt$Span){$s.Add($s[-1]+$Gap)};return ,$s.ToArray()}
function Win($Samples,[long]$Now,[int]$Required=5){Get-M5WindowAssessment $Samples $proof $Now $Required}
function Only($Assessment,[string]$Reason){$Assessment.ready-eq$false-and@($Assessment.reasons).Count-eq1-and$Assessment.reasons[0]-eq$Reason}
function Clean($Assessment){$Assessment.ready-and@($Assessment.reasons).Count-eq0}

# Real capture, unchanged: refused for the gap alone (content predicates accept real car text).
$a=Win $real $realResult.createdMs;Check (Only $a $gapReason) 'real capture C refused only for polling gap'
foreach($t in $real){$sa=Get-M5SampleAssessment $t $proof;Check $sa.safe "real sample at $($t.startMs) individually safe"}

# Inter-sample start gap: 2000 inclusive.
foreach($g in 1999,2000){$s=Seq (Even $g);Check (Clean (Win $s ($s[-1].startMs+1700))) "uniform gap $g ms accepted"}
$s=Seq (Even 2001);Check (Only (Win $s ($s[-1].startMs+1700)) $gapReason) 'uniform gap 2001 ms refused for gap only'
$s=Seq @(0,1500,3501,5000);Check (Only (Win $s 6700) $gapReason) 'single 2001 ms gap among short gaps refused'
$s=Seq @(0,1500,3500,5000);Check (Clean (Win $s 6700)) 'single 2000 ms gap among short gaps accepted'
$s=Seq @(0,1500,1500,3000,4500,5000);Check (Only (Win $s 6700) $gapReason) 'repeated start time refused'
$s=Seq @(0,1500,1400,3000,4500,5000);Check (-not(Win $s 6700).ready-and(Win $s 6700).reasons-contains$gapReason) 'decreasing start time refused'

# Per-sample duration: 2000 inclusive.
foreach($d in 1999,2000){$s=Seq (Even 2000) $d;Check (Clean (Win $s ($s[-1].startMs+$d))) "sample duration $d ms accepted (non-overlapping, 2000 ms starts)"}
$s=Seq (Even 1500);$s[2].endMs=$s[2].startMs+2001;Check (Only (Win $s ($s[-1].startMs+1700)) $durReason) 'mid-window sample duration 2001 ms refused for duration only'
$s=Seq (Even 1500) 2001;$a=Win $s ($s[-1].startMs+2001);Check ($a.reasons-contains$durReason-and$a.reasons-contains$staleReason) 'last sample 2001 ms cannot also satisfy final 2000 ms precheck'
$s=Seq (Even 1500);$s[2].endMs=$s[2].startMs-1;Check (-not(Win $s ($s[-1].startMs+1700)).ready) 'sample end before start refused'

# Stabilization span: first-to-last start >= RequiredSeconds*1000.
$s=Seq @(0,1500,3000,4500,4999);Check (Only (Win $s 6600) $spanReason) 'span 4999 ms refused for span only'
$s=Seq @(0,1500,3000,4500,5000);Check (Clean (Win $s 6600)) 'span 5000 ms accepted'
$s=Seq (Even 1500 15000);Check (Clean (Win $s ($s[-1].startMs+1600) 15)) 'span 15 s with policy 15 accepted'
$s=Seq (Even 1500 16500);Check (Only (Win $s ($s[-1].startMs+1600) 16) $policyReason) 'policy 16 s refused for policy only'
$s=Seq (Even 1500 4000);Check ((Win $s ($s[-1].startMs+1600) 4).reasons-contains$policyReason) 'policy 4 s refused'
$s=Seq @(0);Check ((Win $s 1600).reasons-contains$countReason) 'single sample refused'

# Final precheck inside the window assessment: NowMs-last.startMs <= 2000, NowMs >= last.endMs.
$s=Seq (Even 1500)
Check (Clean (Win $s ($s[-1].startMs+1999))) 'final precheck age 1999 ms accepted'
Check (Clean (Win $s ($s[-1].startMs+2000))) 'final precheck age 2000 ms accepted'
Check (Only (Win $s ($s[-1].startMs+2001)) $staleReason) 'final precheck age 2001 ms refused for staleness only'
Check (Only (Win $s ($s[-1].endMs-1)) $staleReason) 'final precheck before last sample end refused'

# Runner-side freshness (Test-M5ReadinessFresh): NowMs-lastSampleStartMs <= 2000, NowMs >= createdMs and lastSampleStartMs.
function Result{[pscustomobject]@{schema=1;result='READY_TO_ARM';runId='boundary';serial='00000000';apkSHA256=$script:M5FrozenHash;stabilizationSeconds=5;sampleCount=4;createdMs=11700L;lastSampleStartMs=10000L}}
$r=Result
Check (Test-M5ReadinessFresh $r 'boundary' '00000000' 11999) 'runner freshness age 1999 ms accepted'
Check (Test-M5ReadinessFresh $r 'boundary' '00000000' 12000) 'runner freshness age 2000 ms accepted'
$r=Result;$r.sampleCount=2;Check (Test-M5ReadinessFresh $r 'boundary' '00000000' 11800) 'runner freshness minimum sampleCount 2 accepted'
foreach($p in 5,15){$r=Result;$r.stabilizationSeconds=$p;Check (Test-M5ReadinessFresh $r 'boundary' '00000000' 11800) "runner freshness policy $p s accepted"}
$r=Result;Check (Test-M5ReadinessFresh $r 'boundary' '00000000' 11700) 'runner freshness at exactly createdMs accepted'
Check (-not(Test-M5ReadinessFresh $r 'boundary' '00000000' 12001)) 'runner freshness age 2001 ms refused'
Check (-not(Test-M5ReadinessFresh $r 'boundary' '00000000' 11699)) 'runner freshness before createdMs refused'
$r=Result;$r.createdMs=9000;Check (-not(Test-M5ReadinessFresh $r 'boundary' '00000000' 9999)) 'runner freshness before lastSampleStartMs refused'
$r=Result;$r.sampleCount=1;Check (-not(Test-M5ReadinessFresh $r 'boundary' '00000000' 11800)) 'runner freshness sampleCount 1 refused'
foreach($p in 4,16){$r=Result;$r.stabilizationSeconds=$p;Check (-not(Test-M5ReadinessFresh $r 'boundary' '00000000' 11800)) "runner freshness policy $p s refused"}
$r=Result;$r.result='NOT_READY_TO_ARM';Check (-not(Test-M5ReadinessFresh $r 'boundary' '00000000' 11800)) 'runner freshness NOT_READY refused'

# Static pins for limits that only exist as runner/collector text.
$runner=Get-Content "$root/tools/m5/Invoke-M5FutureSession.ps1" -Raw
$collector=Get-Content "$root/scripts/Test-M5ArmReadiness.ps1" -Raw
Check ($runner.Contains('if([Environment]::TickCount64-$guard.lastSampleStartMs-gt2000){throw') ) 'runner post-intent 2000 ms check present'
Check ($runner.Contains("if(`$Arguments-contains'REQUEST_ONCE_AFTER_M4_PASS'-and-not(Test-M5ReadinessFresh `$guard")) 'runner process-start freshness check present'
$iFresh=$runner.IndexOf('Test-M5ReadinessFresh $guard $state.runId $Serial ([Environment]::TickCount64))){throw ''ARM REFUSED: current');$iArm=$runner.IndexOf("'REQUEST_ONCE_AFTER_M4_PASS','--ez'")
Check ($iFresh-ge0-and$iArm-ge0-and$iFresh-lt$iArm) 'runner freshness present and precedes arm command'
Check ($collector.Contains('[Environment]::TickCount64-$samples[0].startMs-gt20000')) 'collector 20 s bounded observation present'
Check ($collector.Contains('$timeout=-not$p.WaitForExit(15000)')) 'collector 15 s per-command wait present'

$summary=[ordered]@{PASS=($script:failed.Count-eq0);checks=$script:checks;failed=@($script:failed);source='real capture C content; synthetic timestamps';adbInvocations=0;filesWritten=0}
$summary|ConvertTo-Json -Depth 3
if($script:failed.Count){throw "TIMING BOUNDARY TESTS FAILED: $($script:failed-join'; ')"}
