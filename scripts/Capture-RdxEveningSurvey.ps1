param(
 [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9._:-]+$')][string]$Serial,
 [Parameter(Mandatory)][ValidateSet('Survey','Input')][string]$Mode,
 [Parameter(Mandatory)][string]$OutputDirectory,
 [ValidateRange(10,180)][int]$InputSeconds=60,
 [ValidateRange(50,20000)][int]$InputEventCount=4000,
 [string]$AdbPath,
 [switch]$PlanOnly
)
# READ-ONLY evening survey (2026-10-27). Every device command is fixed below and re-checked against an allowlist
# immediately before it starts. Nothing here installs, launches, taps, types, changes settings/properties, kills,
# reboots or writes on the device. Survey = system/input/audio/codec/display/USB inventory. Input = one bounded
# `getevent` capture while the user touches/turns controls; it stops on event count or host timeout.
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(-not$AdbPath){$AdbPath=Join-Path $root 'adb/adb.exe'}
$output=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $output){throw "Output directory already exists; choose a new one: $output"}
New-Item -ItemType Directory -Path $output|Out-Null
$plan=[Collections.Generic.List[object]]::new()
function Add([string]$Name,[string[]]$Arguments,[int]$Timeout=15000){$plan.Add([pscustomobject]@{name=$Name;arguments=$Arguments;timeoutMs=$Timeout})}
function Sh([string]$Name,[string[]]$ShellArgs,[int]$Timeout=15000){Add $Name (@('-s',$Serial,'shell')+$ShellArgs) $Timeout}
Add 'selected-state' @('-s',$Serial,'get-state') 8000
Sh 'uptime-start' @('cat','/proc/uptime')
Sh 'boot-id' @('cat','/proc/sys/kernel/random/boot_id')
Sh 'fingerprint' @('getprop','ro.build.fingerprint')
if($Mode-eq'Survey'){
 Sh 'getprop-all' @('getprop')
 Sh 'processes' @('ps')
 # Input: devices, axes/ranges, key layouts, current InputReader/Dispatcher routing.
 Sh 'input-devices-raw' @('getevent','-p') 20000
 Sh 'input-devices-labels' @('getevent','-lp') 20000
 Sh 'dev-input' @('ls','-l','/dev/input')
 Sh 'proc-input-devices' @('cat','/proc/bus/input/devices')
 Sh 'dumpsys-input' @('dumpsys','input') 20000
 Sh 'keylayouts' @('ls','-l','/system/usr/keylayout')
 Sh 'idc' @('ls','-l','/system/usr/idc')
 # Audio: routing, focus, outputs/inputs, ALSA cards.
 Sh 'dumpsys-audio' @('dumpsys','audio') 20000
 Sh 'dumpsys-audio-policy' @('dumpsys','media.audio_policy') 20000
 Sh 'dumpsys-audio-flinger' @('dumpsys','media.audio_flinger') 20000
 Sh 'audio-policy-conf' @('cat','/system/etc/audio_policy.conf')
 Sh 'asound-cards' @('cat','/proc/asound/cards')
 Sh 'asound-pcm' @('cat','/proc/asound/pcm')
 # Video decoder: declared codecs/limits, current media-server clients.
 Sh 'media-codecs' @('cat','/system/etc/media_codecs.xml')
 Sh 'media-codecs-performance' @('cat','/system/etc/media_codecs_performance.xml')
 Sh 'media-profiles' @('cat','/system/etc/media_profiles.xml')
 Sh 'etc-listing' @('ls','-l','/system/etc')
 Sh 'dumpsys-media-player' @('dumpsys','media.player') 20000
 # Display/window: geometry, overscan state (DisplayInfo prints ", overscan (" only when non-zero), layers.
 Sh 'dumpsys-display' @('dumpsys','display') 20000
 Sh 'dumpsys-window' @('dumpsys','window') 20000
 Sh 'dumpsys-surfaceflinger' @('dumpsys','SurfaceFlinger') 20000
 # USB and Honda AA receiver state.
 Sh 'dumpsys-usb' @('dumpsys','usb') 20000
 Sh 'honda-aa-package' @('dumpsys','package','com.honda.androidauto.projection.sink') 20000
 Sh 'honda-aa-services' @('dumpsys','activity','services','com.honda.androidauto.projection.sink') 20000
 Sh 'activities' @('dumpsys','activity','activities') 20000
 Sh 'service-list' @('service','list')
 Sh 'meminfo' @('cat','/proc/meminfo')
 Add 'logcat-main' @('-s',$Serial,'logcat','-d','-v','threadtime') 40000
 Add 'logcat-events' @('-s',$Serial,'logcat','-b','events','-d','-v','threadtime') 40000
}else{
 Sh 'input-devices-labels' @('getevent','-lp') 20000
 Sh 'getevent-capture' @('getevent','-lt','-c',[string]$InputEventCount) ($InputSeconds*1000)
 Sh 'processes-after-capture' @('ps')
}
Sh 'uptime-end' @('cat','/proc/uptime')
$plan|ConvertTo-Json -Depth 6|Set-Content (Join-Path $output 'plan.json')

# Allowlist: shell commands that only read. Exact command words; arguments are fixed paths/flags from the plan above.
$allowed=@(
 '^get-state$','^logcat -d -v threadtime$','^logcat -b events -d -v threadtime$',
 '^shell cat /(proc|system/etc|proc/sys/kernel/random|proc/bus/input|proc/asound)/[A-Za-z0-9_./-]+$',
 '^shell getprop( ro\.build\.fingerprint)?$','^shell ps$','^shell service list$',
 '^shell ls -l /(dev/input|system/usr/keylayout|system/usr/idc|system/etc)$',
 '^shell getevent -(p|lp)$','^shell getevent -lt -c \d+$',
 '^shell dumpsys (input|audio|media\.audio_policy|media\.audio_flinger|media\.player|display|window|SurfaceFlinger|usb)$',
 '^shell dumpsys package com\.honda\.androidauto\.projection\.sink$',
 '^shell dumpsys activity (activities|services com\.honda\.androidauto\.projection\.sink)$'
)
foreach($item in $plan){
 if($item.arguments[0]-cne'-s'-or$item.arguments[1]-cne$Serial){throw "Plan entry $($item.name) does not select the serial"}
 $rest=($item.arguments|Select-Object -Skip 2)-join' '
 if(-not($allowed|Where-Object{$rest-cmatch$_})){throw "Plan entry $($item.name) is not on the read-only allowlist: $rest"}
}
if($PlanOnly){Write-Output "PLAN ONLY; ADB not launched. $output";return}
if(-not(Test-Path -LiteralPath $AdbPath)){throw "ADB executable missing: $AdbPath"}

function Capture($Item){
 $si=[Diagnostics.ProcessStartInfo]::new();$si.FileName=$AdbPath;$si.UseShellExecute=$false;$si.CreateNoWindow=$true;$si.RedirectStandardOutput=$true;$si.RedirectStandardError=$true
 foreach($a in $Item.arguments){$si.ArgumentList.Add($a)}
 $p=[Diagnostics.Process]::new();$p.StartInfo=$si;$utc=[DateTime]::UtcNow.ToString('o')
 [void]$p.Start();$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync()
 $timedOut=-not$p.WaitForExit($Item.timeoutMs)
 if($timedOut){try{$p.Kill()}catch{};$p.WaitForExit()}
 $stdout=$o.GetAwaiter().GetResult();$stderr=$e.GetAwaiter().GetResult();$code=$p.ExitCode;$p.Dispose()
 [IO.File]::WriteAllText((Join-Path $output "$($Item.name).stdout.txt"),$stdout);[IO.File]::WriteAllText((Join-Path $output "$($Item.name).stderr.txt"),$stderr)
 [ordered]@{name=$Item.name;utc=$utc;endUtc=[DateTime]::UtcNow.ToString('o');arguments=$Item.arguments;exitCode=$code;timedOut=$timedOut;timeoutMs=$Item.timeoutMs;stdoutBytes=$stdout.Length}|ConvertTo-Json -Depth 5|Set-Content (Join-Path $output "$($Item.name).command.json")
 return [pscustomobject]@{name=$Item.name;stdout=$stdout;exitCode=$code;timedOut=$timedOut}
}
$results=[Collections.Generic.List[object]]::new()
foreach($item in $plan){
 $r=Capture $item;$results.Add($r)
 if($item.name-eq'selected-state'-and($r.exitCode-ne0-or$r.timedOut-or$r.stdout.Trim()-ne'device')){throw "Selected serial not available; stopped before any shell command. Evidence: $output"}
 if($item.name-eq'getevent-capture'){Write-Output "Input capture finished (timedOut=$($r.timedOut), lines=$(@($r.stdout-split'\r?\n'|Where-Object{$_.Trim()}).Count))."}
}
# A host-side timeout ends the adb client; report (never kill) a getevent left on the device.
$leftover=$null
$after=$results|Where-Object name -eq 'processes-after-capture'
if($after){$first=@($after.stdout-split'\r?\n'|Where-Object{$_.Trim()})|Select-Object -First 1
 $leftover=if($after.exitCode-ne0-or$after.timedOut-or$first-notmatch'^USER\s+PID\s+PPID\b.*\bNAME\s*$'){'UNKNOWN (process listing failed)'}else{@($after.stdout-split'\r?\n'|Where-Object{$_-match'\sgetevent\s*$'}).Count}}
$summary=[ordered]@{mode=$Mode;serial=$Serial;output=$output;commands=$results.Count;
 timedOut=@($results|Where-Object timedOut|ForEach-Object name);nonZeroExit=@($results|Where-Object{$_.exitCode-ne0}|ForEach-Object name);
 geteventLeftOnDevice=$leftover}
$summary|ConvertTo-Json -Depth 4|Set-Content (Join-Path $output 'summary.json')
Get-ChildItem -LiteralPath $output -File|Where-Object Name -ne 'hashes.json'|Get-FileHash|Select-Object @{n='file';e={Split-Path $_.Path -Leaf}},Hash|ConvertTo-Json|Set-Content (Join-Path $output 'hashes.json')
$summary|ConvertTo-Json -Depth 4
if($leftover-is[string]){Write-Output "NOTE: could not check for a leftover getevent ($leftover). Report it; do not kill anything."}
elseif($leftover){Write-Output "NOTE: a getevent process is still on the device. It only reads; it ends after $InputEventCount events. Report it; do not kill it."}
Write-Output "Read-only $Mode capture complete: $output"
