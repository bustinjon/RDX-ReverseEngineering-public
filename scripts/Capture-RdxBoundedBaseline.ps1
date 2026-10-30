param(
 [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9._:-]+$')][string]$Serial,
 [Parameter(Mandatory)][ValidateSet('com.rdx.fullscreen.usbprobe','com.rdx.fullscreen.gridtest','com.rdx.fullscreen.decodertest','com.rdx.fullscreen.m5permission')][string]$TestPackage,
 [switch]$PlanOnly
)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$output=Join-Path $root ('analysis/live-logs/'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $output -ErrorAction Stop|Out-Null
$plan=[Collections.Generic.List[object]]::new()
function AddCapture([string]$Name,[string[]]$Arguments,[int]$Timeout=12000){$plan.Add([pscustomobject]@{name=$Name;arguments=$Arguments;timeoutMs=$Timeout})}
AddCapture 'devices' @('devices')
AddCapture 'selected-state' @('-s',$Serial,'get-state')
foreach($property in @('ro.build.fingerprint','ro.build.version.release','ro.build.version.sdk','ro.product.cpu.abi','ro.build.display.id')){AddCapture ('identity-'+$property.Replace('.','-')) @('-s',$Serial,'shell','getprop',$property)}
AddCapture 'uptime' @('-s',$Serial,'shell','cat','/proc/uptime')
foreach($package in @('com.honda.androidauto.projection.sink',$TestPackage,'com.honda.maliciousdetector')){
 AddCapture ('path-'+$package) @('-s',$Serial,'shell','pm','path',$package)
 AddCapture ('package-'+$package) @('-s',$Serial,'shell','dumpsys','package',$package)
}
AddCapture 'processes' @('-s',$Serial,'shell','ps')
AddCapture 'process-contexts' @('-s',$Serial,'shell','ps','-Z')
AddCapture 'window' @('-s',$Serial,'shell','dumpsys','window')
AddCapture 'display' @('-s',$Serial,'shell','dumpsys','display')
AddCapture 'activities' @('-s',$Serial,'shell','dumpsys','activity','activities')
AddCapture 'usb' @('-s',$Serial,'shell','dumpsys','usb')
AddCapture 'logs' @('-s',$Serial,'logcat','-d','-v','threadtime') 20000
AddCapture 'uptime-end' @('-s',$Serial,'shell','cat','/proc/uptime')
$plan|ConvertTo-Json -Depth 6|Set-Content "$output/plan.json"
if($PlanOnly){Write-Output "PLAN ONLY; ADB not launched. $output";return}
$adb=Join-Path $root 'adb/adb.exe'
if(-not(Test-Path $adb)){throw 'ADB executable missing'}
function Capture([string]$Name,[string[]]$Arguments,[int]$Timeout){
 $si=[Diagnostics.ProcessStartInfo]::new();$si.FileName=$adb;$si.UseShellExecute=$false;$si.CreateNoWindow=$true;$si.RedirectStandardOutput=$true;$si.RedirectStandardError=$true
 foreach($argument in $Arguments){$si.ArgumentList.Add($argument)}
 $process=[Diagnostics.Process]::new();$process.StartInfo=$si;$utc=[DateTime]::UtcNow.ToString('o')
 [void]$process.Start();$outTask=$process.StandardOutput.ReadToEndAsync();$errTask=$process.StandardError.ReadToEndAsync()
 $timedOut=-not$process.WaitForExit($Timeout)
 if($timedOut){$process.Kill();$process.WaitForExit()}
 $stdout=$outTask.GetAwaiter().GetResult();$stderr=$errTask.GetAwaiter().GetResult();$code=$process.ExitCode
 [IO.File]::WriteAllText("$output/$Name.stdout.txt",$stdout);[IO.File]::WriteAllText("$output/$Name.stderr.txt",$stderr)
 [ordered]@{name=$Name;utc=$utc;endUtc=[DateTime]::UtcNow.ToString('o');arguments=$Arguments;exitCode=$code;timedOut=$timedOut;timeoutMs=$Timeout}|ConvertTo-Json -Depth 5|Set-Content "$output/$Name.command.json"
 $process.Dispose();return [pscustomobject]@{stdout=$stdout;exitCode=$code;timedOut=$timedOut}
}
$plainProcesses=$null
foreach($item in $plan){
 $result=Capture $item.name $item.arguments $item.timeoutMs
 if($item.name-eq'selected-state'-and($result.exitCode-ne0-or$result.timedOut-or$result.stdout.Trim()-ne'device')){throw "Selected serial unavailable; stopped without trying other devices. Evidence: $output"}
 if($item.name-eq'processes'){$plainProcesses=$result.stdout}
}
# Resolve only the currently tested app's PIDs. No historical PID or private-data access.
if($plainProcesses){
 $lines=@($plainProcesses-split'\r?\n'|Where-Object {$_.Trim()})
 if($lines.Count){$header=$lines[0].Trim()-split'\s+';$pidIndex=[Array]::IndexOf($header,'PID')
  if($pidIndex-ge0){foreach($line in $lines|Select-Object -Skip 1){$fields=$line.Trim()-split'\s+';$name=$fields[-1]
   if(($name-eq$TestPackage-or$name.StartsWith($TestPackage+':'))-and$fields[$pidIndex]-match'^\d+$'){
    $appPid=$fields[$pidIndex]
    [void](Capture "app-$appPid-context" @('-s',$Serial,'shell','cat',"/proc/$appPid/attr/current") 6000)
    [void](Capture "app-$appPid-status" @('-s',$Serial,'shell','cat',"/proc/$appPid/status") 6000)
   }
  }}
 }
}
Get-ChildItem $output -File|Get-FileHash|Select-Object Path,Hash|ConvertTo-Json|Set-Content "$output/hashes.json"
Write-Output "Read-only capture complete: $output"
