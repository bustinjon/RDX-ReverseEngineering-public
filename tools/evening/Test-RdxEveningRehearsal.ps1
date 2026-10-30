param([Parameter(Mandatory)][string]$OutputDirectory)
# Offline fake-car rehearsal for tools/evening/Invoke-RdxEveningStage.ps1 (v2). The real adb is never used: a compiled fake
# adb keeps install/overscan/running/on-screen state and a growing log in files, and answers with real captures from
# 2026-10-26. Exits 1 on any failure.
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent;$runner=Join-Path $PSScriptRoot 'Invoke-RdxEveningStage.ps1'
$out=[IO.Path]::GetFullPath($OutputDirectory);if($out.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw 'Output must be outside the project'}
if($out-match'\s'){throw 'Output path must not contain spaces'};if(Test-Path -LiteralPath $out){throw 'Output exists'};New-Item -ItemType Directory -Path $out|Out-Null
$cap=Join-Path $root 'analysis/parallel-aa-receiver/m5-retry-live-20261026-174603/before'
$cs=@'
using System;using System.IO;using System.Linq;using System.Collections.Generic;
class F{static string S,D;static List<string> L(){return File.Exists(S)?File.ReadAllLines(S).ToList():new List<string>();}
static bool Has(string k){return L().Contains(k);}static void Set(string k,bool on){var l=L();l.Remove(k);if(on)l.Add(k);File.WriteAllLines(S,l);}
static void Log(string pid,string tag,string msg){File.AppendAllText(Path.Combine(D,"device-log.txt"),"10-27 20:00:"+DateTime.Now.ToString("ss.fff")+"  "+pid+"  "+pid+" I "+tag+": "+msg+"\n");}
static int Main(string[] a){D=Environment.GetEnvironmentVariable("FAKE_DIR");S=Path.Combine(D,"state.txt");
string j=string.Join(" ",a.Skip(2));File.AppendAllText(Path.Combine(D,"invocations.log"),string.Join(" ",a)+"\n");
string cap=Environment.GetEnvironmentVariable("FAKE_CAP");bool wide=Has("overscan");string pid=Has("newpid")?"5151":"4242";
if(j=="get-state"){if(Has("offline")){Console.Error.WriteLine("error: device offline");return 1;}Console.WriteLine("device");return 0;}
if(j=="shell cat /proc/sys/kernel/random/boot_id"){Console.WriteLine(Has("rebooted")?"bbbb":"aaaa");return 0;}
if(j=="shell getprop ro.build.fingerprint"){Console.WriteLine("Acura/gen1CBD_HS/gen1CBD_HS:5.1.1/LMY48P/14:user/release-keys");return 0;}
if(j.StartsWith("shell pm path ")){string p=a.Last();if(Has("pmfail")&&p.StartsWith("com.rdx")){Console.Error.WriteLine("error: device offline");return 1;}
 if(p=="com.honda.androidauto.projection.sink")Console.WriteLine("package:/system/app/AndroidAuto/AndroidAuto.apk");else if(Has("inst:"+p))Console.WriteLine("package:/data/app/"+p+"-1/base.apk");return 0;}
if(j=="shell dumpsys display"){string t=File.ReadAllText(Path.Combine(cap,"display.txt"));if(wide)t=t.Replace("app 1339 x 720, real 1920 x 720","app 1920 x 720, real 1920 x 720, overscan (0,0,-581,0)");Console.Write(t);return 0;}
if(j=="shell dumpsys window"){string t=File.ReadAllText(Path.Combine(cap,"window.txt"));if(wide)t=t.Replace("(0,0) 1339x720","(0,0) 1920x720").Replace("(0,0)-(1339,720)","(0,0)-(1920,720)").Replace("mSystem=(0,0)-(1920,720)","mSystem=(0,0)-(2501,720)");Console.Write(t);return 0;}
if(j=="shell dumpsys activity activities"){foreach(var k in L().Where(x=>x.StartsWith("onscreen:")))Console.WriteLine("  mResumedActivity: ActivityRecord{1 u0 "+k.Substring(9)+" t9}");Console.WriteLine("  mFocusedActivity: ActivityRecord{2 u0 com.honda.tjba.launcher/.ui.HomeActivity t1}");return 0;}
if(j=="shell ls -l /data/system/display_settings.xml"){Console.WriteLine("/data/system/display_settings.xml: Permission denied");return 0;}
if(j=="shell wm overscan 0,0,-581,0"){Set("overscan",true);return 0;}
if(j=="shell wm overscan reset"){if(Has("resetfail")){Console.Error.WriteLine("error: closed");return 1;}if(!Has("resetbroken"))Set("overscan",false);if(Has("writefail"))Log("700","WindowManager","Failed to write display settings, restoring backup.");return 0;}
if(j.StartsWith("install ")){if(Has("installfail")){Console.WriteLine("Failure [INSTALL_FAILED_INTERNAL_ERROR]");return 1;}string p=j.Contains("grid")?"com.rdx.fullscreen.gridtest":"com.rdx.fullscreen.decodertest";Set("inst:"+p,true);Console.WriteLine("Success");return 0;}
if(j.StartsWith("uninstall ")){Set("inst:"+a.Last(),false);Set("run:"+a.Last(),false);foreach(var k in L().Where(x=>x.StartsWith("onscreen:"+a.Last())).ToList())Set(k,false);Console.WriteLine("Success");return 0;}
if(j.StartsWith("shell am start")){string c=a.Last();string p=c.Split('/')[0];if(Has("lockrefuse")){Console.WriteLine("Error: Activity not started, unknown error code 5");return 0;}
 Set("run:"+p,true);Set("onscreen:"+c,true);if(!Has("nosurface")){string w=wide?"1920":"1339";Log(pid,p.Contains("grid")?"RDX.GRID":"RDX.DECODER","Surface="+w+"x"+(p.Contains("grid")?"720":"560"));}
 Console.WriteLine("Starting: Intent { cmp="+c+" }\nStatus: ok\nActivity: "+c+"\nThisTime: 300\nTotalTime: 300\nComplete");return 0;}
if(j=="shell ps"){Console.WriteLine("USER     PID   PPID  VSIZE  RSS     WCHAN    PC         NAME");Console.WriteLine("root      1     0     1000   500   ffffffff 00000000 S /init");foreach(var k in L().Where(x=>x.StartsWith("run:")))Console.WriteLine("u0_a50    "+pid+"  200   9000   900   ffffffff 00000000 S "+k.Substring(4));return 0;}
if(j=="exec-out screencap -p"){using(var o=Console.OpenStandardOutput()){var b=Has("badpng")?new byte[]{137,80,1,2}:new byte[]{137,80,78,71,13,10,26,10,0,0,0,13,73,72,68,82,0,0,7,128,0,0,2,208,8,6,0,0,0};o.Write(b,0,b.Length);}return 0;}
if(j=="logcat -d -v threadtime"){string f=Path.Combine(D,"device-log.txt");Console.WriteLine("10-27 19:00:00.000   1   1 I init: boot");if(File.Exists(f))Console.Write(File.ReadAllText(f));return 0;}
if(j.StartsWith("pull ")){File.Copy(Path.Combine(cap,"factory-aa.apk"),a.Last(),true);Console.WriteLine("1 file pulled");return 0;}
if(j.StartsWith("shell dumpsys ")){Console.WriteLine("fake dump");return 0;}
Console.WriteLine("fake: unhandled "+j);return 0;}}
'@
$fake=Join-Path $out 'fakeadb.exe';$src=Join-Path $out 'fake.cs';Set-Content $src $cs
powershell.exe -NoProfile -Command "Add-Type -TypeDefinition (Get-Content -Raw '$src') -OutputAssembly '$fake' -OutputType ConsoleApplication" 2>&1|Out-Null
if(-not(Test-Path $fake)){throw 'fake adb compile failed'}
$env:FAKE_CAP=$cap;$results=[Collections.Generic.List[object]]::new()
function Scenario([string]$Name,[scriptblock]$Body){$d=Join-Path $out $Name;New-Item -ItemType Directory -Path $d|Out-Null;$env:FAKE_DIR=$d;$script:sess=Join-Path $d 'session';$script:fails=@();$script:sdir=$d
 & $Body;$inv=@(Get-Content (Join-Path $d 'invocations.log') -ErrorAction SilentlyContinue);if($inv|Where-Object{$_-match'unhandled'}){$script:fails+='unhandled command'}
 $results.Add([pscustomobject]@{scenario=$Name;pass=-not$script:fails.Count;fails=$script:fails;adbCalls=$inv.Count})}
function Run([string]$Stage,[string[]]$More=@()){$o=& pwsh -NoProfile -File $runner -Session $script:sess -Stage $Stage -Serial 00000000 -AdbPath $fake @More 2>&1|Out-String;Add-Content (Join-Path $script:sdir 'console.txt') "=== $Stage $More (exit $LASTEXITCODE)`n$o";return [pscustomobject]@{code=$LASTEXITCODE;text=$o}}
function Expect($R,[int]$Code,[string]$Pattern){if($R.code-ne$Code-or$R.text-notmatch$Pattern){$script:fails+="expected exit $Code /$Pattern/ got $($R.code): $(($R.text-split"`n"|Where-Object{$_.Trim()}|Select-Object -Last 2)-join' | ')"}}
function Fake([string]$Key,[bool]$On){$f=Join-Path $env:FAKE_DIR 'state.txt';$l=@(if(Test-Path $f){Get-Content $f});$l=@($l|Where-Object{$_-ne$Key});if($On){$l+=$Key};Set-Content $f $l}
function ExitApp([string]$Component){Fake "onscreen:$Component" $false}   # user presses EXIT: Activity finishes, process stays
function DevLog([string]$Tag,[string]$Msg){Add-Content (Join-Path $env:FAKE_DIR 'device-log.txt') "10-27 20:00:$((Get-Date).ToString('ss.fff'))  4242  4242 I ${Tag}: $Msg"}
function Calls([string]$Pattern){@(Get-Content (Join-Path $env:FAKE_DIR 'invocations.log')|Where-Object{$_-match$Pattern}).Count}
$G='com.rdx.fullscreen.gridtest/.GridActivity';$Dc='com.rdx.fullscreen.decodertest/.DecoderTestActivity'
$gA=@('-App','grid','-Authorization','GRID_TEST');$dA=@('-App','decoder','-Authorization','DECODER_TEST');$oA=@('-Authorization','OVERSCAN')

Scenario 'happy' {
 Expect (Run BASELINE) 0 'BASELINE OK: boot aaaa, mOverscanScreen=\(0,0\) 1339x720'
 Expect (Run INSTALL $gA) 0 'installed'
 Expect (Run LAUNCH ($gA+@('-Label','normal'))) 0 'overscan ZERO\); Surface=1339x720'
 ExitApp $G
 Expect (Run OVERSCAN_APPLY $oA) 0 'full width: mOverscanScreen=\(0,0\) 1920x720; system bounds \(0,0\)-\(2501,720\)'
 Expect (Run LAUNCH ($gA+@('-Label','wide'))) 0 'overscan APPLIED\); Surface=1920x720'
 ExitApp $G
 Expect (Run OVERSCAN_RESTORE $oA) 0 'restored: .*11 window-policy rectangles match'
 Expect (Run UNINSTALL $gA) 0 'removed'
 Expect (Run INSTALL $dA) 0 'installed'
 Expect (Run LAUNCH ($dA+@('-Label','start'))) 0 'Surface=1339x560'
 DevLog 'RDX.DECODER' 'BEGIN clip=grid-1280x720-30 requestedCodec=OMX.TI.DUCATI1.VIDEO.DECODER wallMs=1'
 Expect (Run CAPTURE @('-Label','clip-1')) 3 'no NEW complete clip result yet \(BEGIN lines: 1\)'
 DevLog 'RDX.DECODER' 'END wallMs=2 clip1 frames=300 EOS'
 Expect (Run CAPTURE @('-Label','clip-1b')) 0 'clip result: END wallMs=2 clip1'
 Expect (Run CAPTURE @('-Label','clip-2-too-early')) 3 'no NEW complete clip result yet \(BEGIN lines: 0\)'
 DevLog 'RDX.DECODER' 'BEGIN clip=grid-1280x688-60 wallMs=3';DevLog 'RDX.DECODER' 'END wallMs=4 clip2 frames=600 EOS'
 Expect (Run CAPTURE @('-Label','clip-2')) 0 'clip result: END wallMs=4 clip2'
 DevLog 'RDX.DECODER' 'BEGIN clip=grid-1920x720-30 wallMs=5';DevLog 'RDX.DECODER' 'ERROR; STOP: codec fail'
 Expect (Run CAPTURE @('-Label','clip-3')) 3 'STOP/ERROR in this clip'
 ExitApp $Dc
 Expect (Run UNINSTALL $dA) 0 'removed'
 Expect (Run POSTCHECK) 0 'FINISHED: the measured checks match'
 if((Calls 'wm overscan') -ne 2){$script:fails+='expected exactly 2 overscan commands'}}
Scenario 'no-authorization' {
 Expect (Run BASELINE) 0 'OK'
 Expect (Run INSTALL @('-App','grid')) 1 'needs -Authorization GRID_TEST'
 Expect (Run INSTALL @('-App','grid','-Authorization','DECODER_TEST')) 1 'needs -Authorization GRID_TEST'
 Expect (Run OVERSCAN_APPLY @('-Authorization','GRID_TEST')) 1 'needs -Authorization OVERSCAN'
 Expect (Run INSTALL $gA) 0 'installed'
 Expect (Run UNINSTALL @('-App','grid')) 1 'needs -Authorization GRID_TEST'
 if((Calls ' uninstall |wm overscan') -ne 0){$script:fails+='a change command ran without authorization'}}
Scenario 'process-survives-exit' {
 Expect (Run BASELINE) 0 'OK';Expect (Run INSTALL $gA) 0 'installed';Fake 'newpid' $false
 Expect (Run LAUNCH $gA) 0 'Surface=1339x720'
 Expect (Run LAUNCH $gA) 1 'already on screen; press its EXIT'
 ExitApp $G
 Expect (Run LAUNCH ($gA+@('-Label','again'))) 0 'Surface=1339x720'}
Scenario 'launch-no-new-surface-line' {
 Expect (Run BASELINE) 0 'OK';Expect (Run INSTALL $gA) 0 'installed'
 Expect (Run LAUNCH $gA) 0 'Surface=1339x720';ExitApp $G;Fake 'nosurface' $true
 Expect (Run LAUNCH ($gA+@('-Label','second'))) 3 'no NEW RDX.GRID Surface line'}
Scenario 'stale-line-other-process' {
 Expect (Run BASELINE) 0 'OK';Expect (Run INSTALL $gA) 0 'installed';Fake 'newpid' $true;Fake 'nosurface' $true
 DevLog 'RDX.GRID' 'Surface=1920x720 (old process)'
 Expect (Run LAUNCH $gA) 3 'no NEW RDX.GRID Surface line'}
Scenario 'pm-path-fails-after-install' {
 Expect (Run BASELINE) 0 'OK';Expect (Run INSTALL $gA) 0 'installed';Fake 'pmfail' $true
 Expect (Run UNINSTALL $gA) 1 'Uninstall not confirmed.*package UNKNOWN'
 Expect (Run POSTCHECK) 2 'POSTCHECK_MISMATCH: packagesAbsent'
 Fake 'pmfail' $false;Expect (Run UNINSTALL $gA) 0 'removed';Expect (Run POSTCHECK) 0 'FINISHED'}
Scenario 'state-absent-but-installed' {
 Expect (Run BASELINE) 0 'OK';Fake 'inst:com.rdx.fullscreen.gridtest' $true
 Expect (Run UNINSTALL $gA) 0 'removed'}
Scenario 'baseline-overscan-present' {Fake 'overscan' $true;Expect (Run BASELINE) 1 'already non-zero';if((Calls 'wm overscan') -ne 0){$script:fails+='changed overscan'}}
Scenario 'baseline-package-present' {Fake 'inst:com.rdx.fullscreen.m5permission' $true;Expect (Run BASELINE) 1 'm5permission is PRESENT'}
Scenario 'restore-fails-then-works' {
 Expect (Run BASELINE) 0 'OK';Fake 'resetbroken' $true
 Expect (Run OVERSCAN_APPLY $oA) 0 'full width'
 Expect (Run OVERSCAN_RESTORE $oA) 1 'RESTORE NOT VERIFIED'
 Expect (Run OVERSCAN_APPLY $oA) 1 'state is UNKNOWN; restore first'
 Expect (Run INSTALL $gA) 1 'Overscan state is UNKNOWN; run OVERSCAN_RESTORE first'
 Fake 'resetbroken' $false
 Expect (Run OVERSCAN_RESTORE $oA) 0 'restored';Expect (Run POSTCHECK) 0 'FINISHED'}
Scenario 'restore-file-write-fails' {
 Expect (Run BASELINE) 0 'OK';Expect (Run OVERSCAN_APPLY $oA) 0 'full width';Fake 'writefail' $true
 Expect (Run OVERSCAN_RESTORE $oA) 1 'Screen restored NOW, but the saved file may still hold the change'
 Expect (Run LAUNCH $gA) 1 'Overscan state is RUNTIME_ONLY'
 Expect (Run POSTCHECK) 2 'overscanStateZero'
 Fake 'writefail' $false;Expect (Run OVERSCAN_RESTORE $oA) 0 'restored';Expect (Run POSTCHECK) 0 'FINISHED'}
Scenario 'restore-retry-reset-fails' {
 Expect (Run BASELINE) 0 'OK';Expect (Run OVERSCAN_APPLY $oA) 0 'full width';Fake 'writefail' $true
 Expect (Run OVERSCAN_RESTORE $oA) 1 'saved file may still hold the change'
 Fake 'writefail' $false;Fake 'resetfail' $true
 Expect (Run OVERSCAN_RESTORE $oA) 1 'reset command ok: False'
 Expect (Run POSTCHECK) 2 'overscanStateZero'
 Fake 'resetfail' $false;Expect (Run OVERSCAN_RESTORE $oA) 0 'restored';Expect (Run POSTCHECK) 0 'FINISHED'}
Scenario 'journal-partial-recovery' {
 Expect (Run BASELINE) 0 'OK';Expect (Run OVERSCAN_APPLY $oA) 0 'full width'
 $j=Get-Content (Join-Path $script:sess 'session.json') -Raw|ConvertFrom-Json;$j.baseline.geometry.PSObject.Properties.Remove('rects');$j|ConvertTo-Json -Depth 8|Set-Content (Join-Path $script:sess 'session.json')
 Expect (Run INSTALL $gA) 1 'only OVERSCAN_RESTORE, UNINSTALL and POSTCHECK'
 Expect (Run OVERSCAN_RESTORE $oA) 0 '(?s)restored.*session.json was unreadable'
 Expect (Run POSTCHECK) 0 'boot NOT compared'}
Scenario 'bad-screenshot' {
 Expect (Run BASELINE) 0 'OK';Expect (Run INSTALL $gA) 0 'installed';Fake 'badpng' $true
 Expect (Run LAUNCH $gA) 3 'screenshot failed'}
Scenario 'journal-corrupt-recovery' {
 Expect (Run BASELINE) 0 'OK';Expect (Run INSTALL $gA) 0 'installed';Expect (Run OVERSCAN_APPLY $oA) 0 'full width'
 Set-Content (Join-Path $script:sess 'session.json') '{"serial":"4108'
 Expect (Run LAUNCH $gA) 1 'only OVERSCAN_RESTORE, UNINSTALL and POSTCHECK'
 Expect (Run OVERSCAN_RESTORE $oA) 0 '(?s)restored.*session.json was unreadable'
 Expect (Run UNINSTALL $gA) 0 'removed'
 Expect (Run POSTCHECK) 0 'FINISHED'
 if(-not(Get-ChildItem $script:sess -Filter 'session.json.unreadable-*')){$script:fails+='unreadable journal not preserved'}}
Scenario 'postcheck-overscan-left' {Expect (Run BASELINE) 0 'OK';Expect (Run OVERSCAN_APPLY $oA) 0 'full width';Expect (Run POSTCHECK) 2 'POSTCHECK_MISMATCH: overscanZero'}
Scenario 'postcheck-reboot' {Expect (Run BASELINE) 0 'OK';Fake 'rebooted' $true;Expect (Run POSTCHECK) 2 'POSTCHECK_MISMATCH: sameBoot'}
Scenario 'two-apps-refused' {
 Expect (Run BASELINE) 0 'OK';Expect (Run INSTALL $gA) 0 'installed'
 Expect (Run INSTALL $dA) 1 'Uninstall grid first'
 Expect (Run INSTALL $gA) 1 'is PRESENT; no reinstall'}
Scenario 'lock-task-refusal' {
 Expect (Run BASELINE) 0 'OK';Expect (Run INSTALL $gA) 0 'installed';Fake 'lockrefuse' $true
 Expect (Run LAUNCH $gA) 1 'Launch refused'
 Expect (Run UNINSTALL $gA) 0 'removed';Expect (Run POSTCHECK) 0 'FINISHED'}
Scenario 'install-fails' {
 Expect (Run BASELINE) 0 'OK';Fake 'installfail' $true
 Expect (Run INSTALL $gA) 1 'Install not confirmed.*package ABSENT'
 Fake 'installfail' $false;Expect (Run INSTALL $gA) 0 'installed'}
Scenario 'device-offline' {Expect (Run BASELINE) 0 'OK';Fake 'offline' $true;Expect (Run POSTCHECK) 1 'Selected serial not available'}
Scenario 'session-exists' {Expect (Run BASELINE) 0 'OK';Expect (Run BASELINE) 1 'already exists'}

$all=@(Get-ChildItem $out -Recurse -Filter invocations.log|Get-Content)
$allowed='^-s 00000000 (get-state|logcat -d -v threadtime|exec-out screencap -p|shell cat /proc/sys/kernel/random/boot_id|shell getprop ro\.build\.fingerprint|shell ps|shell dumpsys (display|window|window windows|SurfaceFlinger|media\.player|activity activities|package [a-z0-9.]+)|shell pm path [a-z0-9.]+|shell ls -l /data/system/display_settings\.xml|pull /system/app/AndroidAuto/AndroidAuto\.apk \S+|install \S+\.apk|uninstall com\.rdx\.fullscreen\.(gridtest|decodertest)|shell am start -W -n com\.rdx\.fullscreen\.(gridtest/\.GridActivity|decodertest/\.DecoderTestActivity)|shell wm overscan (0,0,-581,0|reset))$'
$bad=@($all|Where-Object{$_-notmatch$allowed}|Select-Object -Unique)
$summary=[ordered]@{scenarios=$results.Count;passed=@($results|Where-Object pass).Count;totalAdbCalls=$all.Count;commandsOutsideAllowlist=$bad;results=$results}
$summary|ConvertTo-Json -Depth 5|Tee-Object -FilePath (Join-Path $out 'results.json')
if($summary.passed-ne$summary.scenarios-or$bad.Count){exit 1}
