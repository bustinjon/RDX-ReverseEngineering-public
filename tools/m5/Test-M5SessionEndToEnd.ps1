#Requires -Version 7
# OFFLINE, DISARMED end-to-end rehearsal of every M5 runner stage against a FAKE adb that replays real car output
# (2026-10-26 install/uninstall/postcheck session + 2026-10-25 armed/retrieved session). A scratch mirror of the runner is
# pointed at the fake; the real adb is never invoked. Output must be outside the project tree. Hooks that add delay or
# inject failures exist only in the scratch mirror, controlled by RDX_E2E_* variables.
param(
 [Parameter(Mandatory=$true)][string]$OutputDirectory,
 [string]$RunnerPath,
 [string[]]$Scenarios
)
$all=@('happy','refuse-line67','refuse-line19','install-transport-failure','install-reply-lost','armed-marker-late','dump-late','stale-dump-token','verify-unscoped','postcheck-partial','uninstall-repeat','retrieve-after-deadline','preserve-needs-retrieve','preserve-active','armed-never-preserve')
if(-not$Scenarios){$Scenarios=$all};foreach($s in $Scenarios){if($s-notin$all){throw "Unknown scenario: $s"}}
$ErrorActionPreference='Stop';$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if(-not$RunnerPath){$RunnerPath="$PSScriptRoot/Invoke-M5FutureSession.ps1"}
if(Test-Path -LiteralPath $OutputDirectory){throw 'Fresh output directory required'}
$full=[IO.Path]::GetFullPath($OutputDirectory)
if($full.StartsWith($root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)-or$full-eq$root){throw 'Output must be outside the project tree (use a scratch directory)'}
New-Item -ItemType Directory -Path $full|Out-Null;$OutputDirectory=(Resolve-Path -LiteralPath $full).Path
$preflight=(& "$PSScriptRoot/Test-M5FrozenPreflight.ps1"|ConvertFrom-Json)
$T="$root/analysis/parallel-aa-receiver/m5-retry-live-20261026-174603";$TR="$T/readiness-255a9a215c0a44c299247adb878092c6"
$RSess="$root/analysis/parallel-aa-receiver/m5-live-retry-20261025-185128";$RSessRun='m5_270c93bb178648759beda65ed9593e72'

# Fake adb. Map lines: state<TAB>key<TAB>file. key may end in * (prefix). "state:key#n" style is expressed as state "S2#1".
# file FAIL = exit 1 with an adb-style error. Device state moves on install / arm / dump / uninstall.
$fakeDir="$OutputDirectory/fake-adb";New-Item -ItemType Directory $fakeDir|Out-Null
@'
using System;using System.IO;using System.Collections.Generic;
public static class RdxFakeAdbE2E{
 static bool KeyOk(string pat,string key){return pat==key||(pat.EndsWith("*")&&key.StartsWith(pat.Substring(0,pat.Length-1)));}
 // Priority: "S#n" (n-th call of this key in this state), then "S<k" (while fewer than k calls of ANY key in this state), then "S".
 static string Look(string[] map,string c,string st,string key,int n,int total){
  foreach(string line in map){string[] f=line.Split('\t');if(f.Length==3&&f[0]==c+"#"+n&&KeyOk(f[1],key))return f[2];}
  if(c==st)foreach(string line in map){string[] f=line.Split('\t');if(f.Length!=3||!f[0].StartsWith(c+"<"))continue;int k;if(int.TryParse(f[0].Substring(c.Length+1),out k)&&total<k&&KeyOk(f[1],key))return f[2];}
  foreach(string line in map){string[] f=line.Split('\t');if(f.Length==3&&f[0]==c&&KeyOk(f[1],key))return f[2];}
  return null;}
 public static int Main(string[] a){
  string mapPath=Environment.GetEnvironmentVariable("RDX_FAKE_ADB_MAP"),dir=Environment.GetEnvironmentVariable("RDX_FAKE_ADB_STATE");
  if(mapPath==null||dir==null||a.Length<3||a[0]!="-s"||a[1]!="00000000"){Console.Error.Write("fake-adb: missing map/state or bad serial");return 2;}
  string key;string dest=null;
  if(a[2]=="pull"&&a.Length==5){key="pull|"+a[3];dest=a[4];}else{key=string.Join("|",a,2,a.Length-2);}
  File.AppendAllText(Path.Combine(dir,"invocations.log"),key+"\n");
  string sf=Path.Combine(dir,"device-state.txt");string st=File.Exists(sf)?File.ReadAllText(sf).Trim():"S0";
  string cf=Path.Combine(dir,"count-"+st+"-"+((uint)key.GetHashCode()).ToString()+".txt");int n=File.Exists(cf)?int.Parse(File.ReadAllText(cf))+1:1;File.WriteAllText(cf,n.ToString());
  string tf=Path.Combine(dir,"total-"+st+".txt");int total=File.Exists(tf)?int.Parse(File.ReadAllText(tf)):0;File.WriteAllText(tf,(total+1).ToString());
  string[] map=File.ReadAllLines(mapPath);
  string[] chain=st=="S4"?new[]{"S4","*"}:st=="S3"?new[]{"S3","S2","S1","*"}:st=="S2"?new[]{"S2","S1","*"}:st=="S1"?new[]{"S1","*"}:new[]{"S0","*"};
  string file=null;foreach(string c in chain){file=Look(map,c,st,key,n,total);if(file!=null)break;}
  if(file==null){Console.Error.Write("fake-adb: unmapped command "+key+" in "+st);return 1;}
  if(file=="FAIL"){Console.Error.Write("error: device offline");return 1;}
  if(key.StartsWith("install|"))File.WriteAllText(sf,"S1");
  if(key.Contains("|REQUEST_ONCE_AFTER_M4_PASS|"))File.WriteAllText(sf,"S2");
  if(key.Contains("|DUMP_RESULTS|"))File.WriteAllText(sf,"S3");
  if(key.StartsWith("uninstall|"))File.WriteAllText(sf,"S4");
  if(file=="FAIL-AFTER"){Console.Error.Write("error: closed");return 1;}
  if(file=="FAILURE-TEXT"){Console.Out.Write("Failure\n");return 1;}
  if(dest!=null){File.Copy(file,dest);}else{byte[] b=File.ReadAllBytes(file);using(Stream o=Console.OpenStandardOutput()){o.Write(b,0,b.Length);}}
  return 0;
 }
}
'@|Set-Content "$fakeDir/RdxFakeAdbE2E.cs"
$fake="$fakeDir/rdx-fake-adb-e2e.exe"
powershell.exe -NoProfile -Command {param($Source,$Exe) Add-Type -Path $Source -OutputAssembly $Exe -OutputType ConsoleApplication} -args "$fakeDir/RdxFakeAdbE2E.cs",$fake
if(-not(Test-Path -LiteralPath $fake -PathType Leaf)){throw 'Fake adb build failed'}
if([IO.Path]::GetFullPath($fake)-eq[IO.Path]::GetFullPath($preflight.adb)-or[IO.Path]::GetFileName($fake)-eq'adb.exe'){throw 'Fake adb must never coincide with the real adb'}

# Scratch mirror of the runner under test: project paths absolute, adb = fake, test-only delay hooks.
$text=Get-Content -LiteralPath $RunnerPath -Raw
function Sub([string]$Old,[string]$New){if(([regex]::Matches($script:text,[regex]::Escape($Old))).Count-ne1){throw "Mirror substitution not unique/missing: $Old"};$script:text=$script:text.Replace($Old,$New)}
Sub '$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent' "`$root='$root';`$ProgressPreference='SilentlyContinue'"
Sub '. "$PSScriptRoot/M5ArmReadiness.ps1"' ". '$root/tools/m5/M5ArmReadiness.ps1'"
Sub '(& "$PSScriptRoot/Test-M5FrozenPreflight.ps1"|ConvertFrom-Json)' "(& '$root/tools/m5/Test-M5FrozenPreflight.ps1'|ConvertFrom-Json)"
Sub '& "$PSScriptRoot/Get-M5JournalVerdict.ps1"' "& '$root/tools/m5/Get-M5JournalVerdict.ps1'"
Sub '$adb=$preflight.adb' '$adb=$env:RDX_E2E_FAKE_ADB'
Sub "`$state.phase='ARM_ATTEMPTED';Save" "`$state.phase='ARM_ATTEMPTED';Save;if(`$env:RDX_E2E_SLEEP67){Start-Sleep -Milliseconds 2100}"
Sub "`$p=[Diagnostics.Process]::new();`$p.StartInfo=`$si;`$utc=[DateTime]::UtcNow.ToString('o')" "`$p=[Diagnostics.Process]::new();`$p.StartInfo=`$si;`$utc=[DateTime]::UtcNow.ToString('o');if(`$env:RDX_E2E_SLEEP19-and`$Arguments-contains'REQUEST_ONCE_AFTER_M4_PASS'){Start-Sleep -Milliseconds 2100}"
if($text-match'PSScriptRoot'-or$text.Contains('$preflight.adb')){throw 'Mirror still references the real adb or relative paths'}
$mirror="$OutputDirectory/mirror/Invoke-M5FutureSession.mirror.ps1";New-Item -ItemType Directory (Split-Path $mirror)|Out-Null;Set-Content -LiteralPath $mirror -Value $text

# Base map from real captures. S0 before install, S1 installed, S2 armed, S3 dumped, S4 uninstalled.
function Key($Arguments){if($Arguments[0]-eq'pull'){"pull|$($Arguments[1])"}else{$Arguments-join'|'}}
$base=[Collections.Generic.List[string]]::new();$seen=@{}
function Add([string]$State,[string]$K,[string]$File){if($seen.ContainsKey("$State|$K")){return};$seen["$State|$K"]=1;if($File-notin@('FAIL','FAIL-AFTER','FAILURE-TEXT')-and-not(Test-Path -LiteralPath $File -PathType Leaf)){throw "Replay source missing: $File"};$base.Add("$State`t$K`t$File")}
$st='S0'
foreach($line in Get-Content -LiteralPath "$T/commands.jsonl"){$r=$line|ConvertFrom-Json;$k=Key $r.arguments
 $src=if($r.arguments[0]-eq'pull'){$r.arguments[2]}else{$r.stdout}
 if($r.arguments[0]-eq'pull'){$src=(Join-Path $T ((Split-Path (Split-Path $r.arguments[2] -Parent) -Leaf)+'/factory-aa.apk'))}
 if($r.arguments[0]-in@('install','uninstall')-or($r.arguments-join' ')-match'^shell (getprop|am stopservice)'){Add '*' $k $src}
 elseif($st-eq'S0'){Add 'S0' $k $src}else{Add $st $k $src}
 if($r.arguments[0]-eq'install'){$st='S1'};if($r.arguments[0]-eq'uninstall'){$st='S4'}}
foreach($r in @(Get-Content -LiteralPath "$TR/commands.json" -Raw|ConvertFrom-Json)){$k=Key $r.arguments;$src=if($r.arguments[0]-eq'pull'){Join-Path $TR ([IO.Path]::GetFileName($r.arguments[2]))}else{Join-Path $TR $r.stdout};Add 'S1' $k $src}
$svc=$preflight.service

function Get-DumpBlock([string]$Prefix,[string]$Token,[string]$RunId,[byte[]]$Data){
 # Re-encodes a journal exactly as the app does: BEGIN (bytes, sha256), 1200-byte base64 chunks, END.
 $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Data)).ToLowerInvariant();$n=[int][Math]::Ceiling($Data.Length/1200.0)
 $lines=@("${Prefix}DUMP_BEGIN token=$Token run=$RunId bytes=$($Data.Length) sha256=$hash")
 for($i=0;$i-lt$n;$i++){$len=[Math]::Min(1200,$Data.Length-$i*1200);$lines+="${Prefix}DUMP_CHUNK token=$Token index=$i base64=$([Convert]::ToBase64String($Data,$i*1200,$len))"}
 $lines+="${Prefix}DUMP_END token=$Token chunks=$n";return $lines
}
function New-Scenario([string]$Name){
 $d="$OutputDirectory/$Name";New-Item -ItemType Directory "$d/fake-state","$d/fixtures"|Out-Null
 $session="$d/session";[void](& pwsh -NoProfile -File $mirror -Stage PREPARE -SessionDirectory $session 2>&1);$runId=(Get-Content "$session/session.json" -Raw|ConvertFrom-Json).runId
 # Armed/dumped device outputs from the 2026-10-25 session, rewritten for this run. The journal inside the dump is decoded,
 # its run id replaced, and re-encoded, so envelope and journal agree (token A = original token, token B = a later dump).
 $fx="$d/fixtures"
 foreach($n in 'arm-response.txt','armed-logcat.txt','armed-selinux-processes.txt','m5-before-dump.txt'){[IO.File]::WriteAllText("$fx/$n",([IO.File]::ReadAllText("$RSess/$n")).Replace($RSessRun,$runId))}
 $pre=Get-ChildItem -LiteralPath $RSess -Filter 'reconnect-before-dump-*.txt'|Select-Object -First 1;[IO.File]::WriteAllText("$fx/before-dump-full.txt",([IO.File]::ReadAllText($pre.FullName)).Replace($RSessRun,$runId))
 $journal=[IO.File]::ReadAllBytes((Get-ChildItem "$RSess/reconstructed" -Filter '*.txt'|Where-Object{$_.Name-notlike'*.json'}|Select-Object -First 1).FullName)
 $journal=[Text.Encoding]::UTF8.GetBytes([Text.Encoding]::UTF8.GetString($journal).Replace($RSessRun,$runId))
 $full=[IO.File]::ReadAllText("$RSess/reconnect-logcat.txt").Replace($RSessRun,$runId)-split'\r?\n'
 $first=-1;$keep=[Collections.Generic.List[string]]::new();for($i=0;$i-lt$full.Count;$i++){if($full[$i]-match'^(.*?)DUMP_(BEGIN|CHUNK|END) '){if($first-lt0){$first=$keep.Count;$prefix=$Matches[1]}}else{$keep.Add($full[$i])}}
 $tokenA=([regex]::Match([IO.File]::ReadAllText("$RSess/reconnect-logcat.txt"),'DUMP_BEGIN token=([a-f0-9-]{36})')).Groups[1].Value;$tokenB=[guid]::NewGuid().ToString()
 $blockA=Get-DumpBlock $prefix $tokenA $runId $journal;$blockB=Get-DumpBlock $prefix $tokenB $runId $journal
 $withA=[Collections.Generic.List[string]]::new($keep);$withA.InsertRange($first,[string[]]$blockA)
 $withAB=[Collections.Generic.List[string]]::new($withA);$withAB.InsertRange($first+$blockA.Count,[string[]]$blockB)
 [IO.File]::WriteAllText("$fx/reconnect-logcat.txt",($withA-join"`n"));[IO.File]::WriteAllText("$fx/reconnect-logcat-AB.txt",($withAB-join"`n"))
 [IO.File]::WriteAllText("$fx/dumped-tag.txt",(@($withA|Where-Object{$_-match' RDX\.M5 '})-join"`n"));[IO.File]::WriteAllText("$fx/dumped-tag-AB.txt",(@($withAB|Where-Object{$_-match' RDX\.M5 '})-join"`n"))
 $noArmed=@($withA|Where-Object{$_-notmatch('run='+[regex]::Escape($runId)+'.*event=ARMED')});[IO.File]::WriteAllText("$fx/reconnect-logcat-noarmed.txt",($noArmed-join"`n"))
 $tps=Get-Content -LiteralPath "$T/20261026-175026-056-m5-adb-ffeb6a6e.stdout.txt" -Raw;[IO.File]::WriteAllText("$fx/ps-m5-running.txt",$tps.TrimEnd()+"`nu0_a49     8902  177   500000 30000 ffffffff 00000000 S com.rdx.fullscreen.m5permission`n")
 [IO.File]::WriteAllText("$fx/empty.txt",'')
 $map=[Collections.Generic.List[string]]::new($base)
 $map.Add("*`tshell|am|startservice|-n|$svc|-a|REQUEST_ONCE_AFTER_M4_PASS*`t$fx/arm-response.txt")
 $map.Add("*`tshell|am|startservice|-n|$svc|-a|DUMP_RESULTS*`t$fx/arm-response.txt")
 $map.Add("*`tlogcat|-d|-v|threadtime|-s|RDX.M5:I|*:S`t$fx/empty.txt")
 $map.Add("*`tlogcat|-d|-v|threadtime`t$fx/before-dump-full.txt");$map.Add("*`tshell|ps`t$T/20261026-175026-056-m5-adb-ffeb6a6e.stdout.txt")
 $map.Add("S2`tlogcat|-d|-v|threadtime|-s|RDX.M5:I|*:S`t$fx/m5-before-dump.txt")
 $map.Add("S2`tshell|ps|-Z`t$fx/armed-selinux-processes.txt")
 $map.Add("S2`tlogcat|-d|-v|threadtime`t$fx/before-dump-full.txt")
 $map.Add("S3`tlogcat|-d|-v|threadtime|-s|RDX.M5:I|*:S`t$fx/dumped-tag.txt")
 $map.Add("S3`tlogcat|-d|-v|threadtime`t$fx/reconnect-logcat.txt")
 [pscustomobject]@{dir=$d;session=$session;runId=$runId;fx=$fx;map=$map;state="$d/fake-state"}
}
function Write-Map($S){Set-Content -LiteralPath "$($S.dir)/map.tsv" -Value $S.map}
function Over($S,[string]$State,[string]$Key,[string]$File){$S.map.Insert(0,"$State`t$Key`t$File")}
$TAG='logcat|-d|-v|threadtime|-s|RDX.M5:I|*:S';$FULL='logcat|-d|-v|threadtime'
function Stage($S,[string]$Name,[hashtable]$Env=@{}){
 $env:RDX_FAKE_ADB_MAP="$($S.dir)/map.tsv";$env:RDX_FAKE_ADB_STATE=$S.state;$env:RDX_E2E_FAKE_ADB=$fake
 foreach($k in 'RDX_E2E_SLEEP67','RDX_E2E_SLEEP19'){Remove-Item "env:$k" -ErrorAction SilentlyContinue};foreach($k in $Env.Keys){Set-Item "env:$k" $Env[$k]}
 $o=& pwsh -NoProfile -File $mirror -Stage $Name -SessionDirectory $S.session -Serial 00000000 -LiveAuthorization M5_PERMISSION_ONLY 2>&1;$code=$LASTEXITCODE
 foreach($k in 'RDX_E2E_SLEEP67','RDX_E2E_SLEEP19'){Remove-Item "env:$k" -ErrorAction SilentlyContinue}
 $text=($o|Out-String);Add-Content -LiteralPath "$($S.dir)/console.txt" -Value "===== $Name exit=$code`n$text"
 [pscustomobject]@{ok=($code-eq0);text=$text;phase=(Get-Content "$($S.session)/session.json" -Raw|ConvertFrom-Json).phase}
}
function Phase($S){(Get-Content "$($S.session)/session.json" -Raw|ConvertFrom-Json)}
function Invocations($S){if(Test-Path "$($S.state)/invocations.log"){@(Get-Content "$($S.state)/invocations.log")}else{@()}}
function ArmCount($S){@(Invocations $S|Where-Object{$_-match'\|REQUEST_ONCE_AFTER_M4_PASS\|'}).Count}
function Verdict($S){Get-Content "$($S.session)/m5-verdict.json" -Raw|ConvertFrom-Json}
$results=[Collections.Generic.List[object]]::new()
function Expect([string]$Scenario,[bool]$Condition,[string]$What){$results.Add([pscustomobject]@{scenario=$Scenario;check=$What;PASS=$Condition})}
function Finish($S,[string]$Sc,[string[]]$Stages){foreach($n in $Stages){$r=Stage $S $n;Expect $Sc $r.ok "$n succeeds";if(-not$r.ok){return}};if($Stages[-1]-eq'POSTCHECK'){Expect $Sc ((Phase $S).phase-eq'FINISHED') 'ends FINISHED'}}
function Edit-Session($S,[scriptblock]$Change){$j=Get-Content "$($S.session)/session.json" -Raw|ConvertFrom-Json -DateKind String;& $Change $j;$j|ConvertTo-Json -Depth 6|Set-Content "$($S.session)/session.json"}
function Expire($S){Edit-Session $S {param($j)$j.deadlineUTC=[DateTime]::UtcNow.AddSeconds(-10).ToString('o')}}
function Age-Failures($S){Edit-Session $S {param($j)$j.retrieveFailures[0].at=[DateTime]::UtcNow.AddSeconds(-60).ToString('o')}}
function Fail-Retrieve-Twice($S,[string]$Sc){for($i=1;$i-le2;$i++){$r=Stage $S 'RETRIEVE';Expect $Sc (-not$r.ok-and$r.text-match'No new complete dump') "RETRIEVE $i fails without a journal"};Age-Failures $S}

foreach($sc in $Scenarios){$S=New-Scenario $sc
 switch($sc){
  'happy'{Write-Map $S;Finish $S $sc @('INSTALL','ARM','RETRIEVE','VERIFY','UNINSTALL','POSTCHECK');Expect $sc ((ArmCount $S)-eq1) 'exactly one arm command'
   $v=Verdict $S;Expect $sc ($v.verdict-match'INCONCLUSIVE: permission Activity blocked'-and$null-ne$v.PSObject.Properties['permissionUiEvidence']) 'run-scoped blocked UI gives the blocked-UI INCONCLUSIVE verdict'}
  {$_-in'refuse-line67','refuse-line19'}{Write-Map $S;$v=if($sc-eq'refuse-line67'){'RDX_E2E_SLEEP67'}else{'RDX_E2E_SLEEP19'}
   $r=Stage $S 'INSTALL';Expect $sc $r.ok 'INSTALL succeeds'
   $r=Stage $S 'ARM' @{$v='1'};$p=Phase $S
   Expect $sc (-not$r.ok-and$r.text-match'ARM NOT ISSUED') 'late freshness refusal reported as not issued';Expect $sc ($p.phase-eq'INSTALLED') 'phase restored to INSTALLED'
   Expect $sc ((ArmCount $S)-eq0) 'no arm command reached the device';Expect $sc (@($p.notIssuedArms).Count-eq1-and-not(Test-Path "$($S.session)/arm-response.txt")) 'attempt recorded, no arm response'
   Finish $S $sc @('ARM','RETRIEVE','VERIFY','UNINSTALL','POSTCHECK');Expect $sc ((ArmCount $S)-eq1) 'exactly one arm command overall'}
  'install-transport-failure'{Over $S 'S0' "install|$($preflight.apk)" 'FAIL';Write-Map $S
   $r=Stage $S 'INSTALL';Expect $sc (-not$r.ok-and$r.phase-eq'INSTALL_REVIEW_REQUIRED') 'failed install leaves INSTALL_REVIEW_REQUIRED (not PREPARED)'
   $r=Stage $S 'ARM';Expect $sc (-not$r.ok-and(ArmCount $S)-eq0) 'ARM refused after ambiguous install'
   $r=Stage $S 'UNINSTALL';Expect $sc (-not$r.ok) 'UNINSTALL refused before PRESERVE'
   Finish $S $sc @('PRESERVE','UNINSTALL','POSTCHECK');Expect $sc (Test-Path "$($S.session)/evidence-before-uninstall.json") 'evidence hashed'}
  'install-reply-lost'{Over $S 'S0' "install|$($preflight.apk)" 'FAIL-AFTER';Write-Map $S
   $r=Stage $S 'INSTALL';Expect $sc (-not$r.ok-and$r.phase-eq'INSTALL_REVIEW_REQUIRED') 'installed-but-reply-lost leaves INSTALL_REVIEW_REQUIRED'
   Finish $S $sc @('PRESERVE','UNINSTALL','POSTCHECK');Expect $sc (@(Invocations $S|Where-Object{$_-eq'uninstall|com.rdx.fullscreen.m5permission'}).Count-eq1) 'the app that did install is uninstalled'}
  'armed-marker-late'{Over $S 'S2#1' $TAG "$($S.fx)/empty.txt";Over $S 'S2#2' $TAG "$($S.fx)/empty.txt";Write-Map $S
   Finish $S $sc @('INSTALL','ARM','RETRIEVE','VERIFY','UNINSTALL','POSTCHECK');Expect $sc ((ArmCount $S)-eq1) 'arm sent once despite late marker'}
  'dump-late'{# The dump becomes visible in BOTH logs only after 4 device calls in S3.
   Over $S 'S3<4' $TAG "$($S.fx)/m5-before-dump.txt";Over $S 'S3<4' $FULL "$($S.fx)/before-dump-full.txt";Write-Map $S
   Finish $S $sc @('INSTALL','ARM','RETRIEVE','VERIFY','UNINSTALL','POSTCHECK')
   Expect $sc (@(Invocations $S|Where-Object{$_-eq$TAG}).Count-ge7) 'RETRIEVE kept polling until the dump appeared (1 ARM + 1 pre-dump + 5 polls)'}
  'stale-dump-token'{# An older complete dump (token A) is already in the log; the new one (B) appears only later.
   Over $S 'S2' $TAG "$($S.fx)/dumped-tag.txt";Over $S 'S3<3' $TAG "$($S.fx)/dumped-tag.txt";Over $S 'S3' $TAG "$($S.fx)/dumped-tag-AB.txt";Over $S 'S3' $FULL "$($S.fx)/reconnect-logcat-AB.txt";Write-Map $S
   Finish $S $sc @('INSTALL','ARM','RETRIEVE');$j=Phase $S
   Expect $sc ([IO.Path]::GetFileName($j.journal)-notmatch([regex]::Escape(([regex]::Match([IO.File]::ReadAllText("$($S.fx)/dumped-tag.txt"),'DUMP_BEGIN token=([a-f0-9-]{36})')).Groups[1].Value))) 'old token not used; new dump reconstructed'
   Finish $S $sc @('VERIFY','UNINSTALL','POSTCHECK')}
  'verify-unscoped'{Over $S 'S3' $FULL "$($S.fx)/reconnect-logcat-noarmed.txt";Write-Map $S
   Finish $S $sc @('INSTALL','ARM','RETRIEVE','VERIFY');$v=Verdict $S
   Expect $sc ($null-ne$v.PSObject.Properties['permissionUiAttribution']-and$null-eq$v.PSObject.Properties['permissionUiEvidence']-and$v.verdict-notmatch'permission Activity blocked') 'unscoped blocked-UI line is reported UNKNOWN, verdict not overridden'
   Finish $S $sc @('UNINSTALL','POSTCHECK')}
  'postcheck-partial'{Over $S 'S4#1' 'pull|/system/app/AndroidAuto/AndroidAuto.apk' 'FAIL';Write-Map $S
   Finish $S $sc @('INSTALL','ARM','RETRIEVE','VERIFY','UNINSTALL');$r=Stage $S 'POSTCHECK';Expect $sc (-not$r.ok-and$r.phase-eq'UNINSTALLED') 'first POSTCHECK fails, phase stays UNINSTALLED'
   $r=Stage $S 'POSTCHECK';Expect $sc ($r.ok-and$r.phase-eq'FINISHED') 'repeated POSTCHECK finishes';Expect $sc (@(Get-ChildItem $S.session -Directory -Filter 'after-incomplete-*').Count-eq1) 'partial snapshot kept aside'}
  'uninstall-repeat'{Over $S 'S4#1' 'shell|ps' 'FAIL';Over $S 'S4' 'uninstall|com.rdx.fullscreen.m5permission' 'FAILURE-TEXT';Write-Map $S
   Finish $S $sc @('INSTALL','ARM','RETRIEVE','VERIFY');$r=Stage $S 'UNINSTALL';Expect $sc (-not$r.ok-and$r.phase-eq'VERIFIED') 'interrupted UNINSTALL keeps VERIFIED'
   $r=Stage $S 'UNINSTALL';Expect $sc ($r.ok-and$r.phase-eq'UNINSTALLED') 'repeated UNINSTALL on absent package completes';$r=Stage $S 'POSTCHECK';Expect $sc $r.ok 'POSTCHECK succeeds'}
  'retrieve-after-deadline'{Over $S 'S2' $TAG "$($S.fx)/armed-logcat.txt";Write-Map $S
   Finish $S $sc @('INSTALL','ARM');$r=Stage $S 'RETRIEVE';Expect $sc (-not$r.ok-and$r.text-match'still be active') 'RETRIEVE waits while inside the deadline without a terminal marker'
   Expire $S;Finish $S $sc @('RETRIEVE','VERIFY','UNINSTALL','POSTCHECK')}
  'preserve-needs-retrieve'{Write-Map $S
   Finish $S $sc @('INSTALL','ARM');Expire $S;$r=Stage $S 'PRESERVE';Expect $sc (-not$r.ok-and$r.text-match'two recorded RETRIEVE failures'-and(Phase $S).phase-eq'PHONE_SWAP_WAIT_RECONNECT') 'PRESERVE refused while the journal was never attempted'
   Finish $S $sc @('RETRIEVE','VERIFY','UNINSTALL','POSTCHECK')}
  'preserve-active'{# No journal ever appears, and the app process is still alive with no terminal marker.
   Over $S 'S3' $TAG "$($S.fx)/empty.txt";Over $S 'S3' $FULL "$($S.fx)/before-dump-full.txt";Over $S 'S3#1' 'shell|ps' "$($S.fx)/ps-m5-running.txt";Write-Map $S
   Finish $S $sc @('INSTALL','ARM');Expire $S;Fail-Retrieve-Twice $S $sc
   $r=Stage $S 'PRESERVE';Expect $sc (-not$r.ok-and$r.text-match'termination is UNKNOWN'-and(Phase $S).phase-eq'PHONE_SWAP_WAIT_RECONNECT') 'PRESERVE saves evidence but does not unlock cleanup while M5 may be active'
   Expect $sc (@(Get-ChildItem $S.session -Filter 'preserve-ps-*').Count-eq1) 'evidence from the refused PRESERVE kept'
   Finish $S $sc @('PRESERVE','UNINSTALL','POSTCHECK')}
  'armed-never-preserve'{for($i=1;$i-le10;$i++){Over $S "S2#$i" $TAG "$($S.fx)/empty.txt"};Over $S 'S3' $TAG "$($S.fx)/empty.txt";Over $S 'S3' $FULL "$($S.fx)/before-dump-full.txt";Write-Map $S
   $r=Stage $S 'INSTALL';$r=Stage $S 'ARM';Expect $sc (-not$r.ok-and$r.phase-eq'ARM_ATTEMPTED'-and$r.text-match'ARM not confirmed') 'missing ARMED marker after issuing keeps ARM_ATTEMPTED'
   $r=Stage $S 'PRESERVE';Expect $sc (-not$r.ok-and$r.text-match'still be active') 'PRESERVE refused before the deadline'
   Expire $S;Fail-Retrieve-Twice $S $sc
   Finish $S $sc @('PRESERVE','UNINSTALL','POSTCHECK');Expect $sc ((ArmCount $S)-eq1) 'arm sent once, never resent'}
  default{throw "Scenario has no assertions: $sc"}
 }
 $bad=@(Invocations $S|Where-Object{$_-match'\|(clear|disable|force-stop|reboot)\b|^shell\|(settings|wm|input)\|'});Expect $sc ($bad.Count-eq0) 'no forbidden device command'
}
$results|ConvertTo-Json -Depth 4|Set-Content "$OutputDirectory/results.json"
$failed=@($results|Where-Object{-not$_.PASS})
[ordered]@{schema=1;scope='OFFLINE DISARMED: fake adb replay; real adb never invoked; delay/failure hooks only in the scratch mirror';runner=$RunnerPath;runnerSHA256=(Get-FileHash -LiteralPath $RunnerPath).Hash;scenarios=$Scenarios.Count;checks=$results.Count;failed=$failed.Count;PASS=($failed.Count-eq0);failures=@($failed|ForEach-Object{"$($_.scenario): $($_.check)"})}|ConvertTo-Json -Depth 4
if($failed.Count){exit 1}
