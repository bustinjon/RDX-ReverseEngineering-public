param([ValidatePattern('^emulator-[0-9]{4,5}$')][string]$Serial,[Parameter(Mandatory=$true)][string]$OutputDirectory,[string]$AdbPath,[ValidateRange(60,900)][int]$TimeoutSeconds=720,[ValidateRange(1,5000)][int]$MechanicsCases=500,[ValidateRange(1,5000)][int]$CombinedCases=200)
$ErrorActionPreference='Stop';$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. "$PSScriptRoot/EmulatorSafety.ps1"
if([string]::IsNullOrWhiteSpace($Serial)){throw 'Explicit emulator serial required; NO ADB invoked'}
if(-not$AdbPath){$AdbPath=Join-Path $root 'adb/adb.exe'}
$port=[int]($Serial-split'-')[1];if($port-lt1024-or$port-gt65534-or$port%2){throw 'Official emulator even console port required'}
$freeze=Get-Content "$root/analysis/parallel-aa-receiver/api22-tls-qualifier/FROZEN.json" -Raw|ConvertFrom-Json
$apk=Join-Path $root $freeze.path;if((Get-FileHash -LiteralPath $apk).Hash-ne$freeze.sha256){throw 'Frozen qualifier hash mismatch'}
if(-not(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.ProcessName-match'^(emulator|qemu-system.*)$'})){throw 'No positively identified local emulator process; NO ADB invoked'}
New-Item -ItemType Directory -Path $OutputDirectory -ErrorAction Stop|Out-Null;$OutputDirectory=(Resolve-Path $OutputDirectory).Path
$script:commandIndex=0
function Adb([string[]]$Arguments,[switch]$AllowFailure){
 if($Arguments.Count-eq0){throw 'Empty ADB operation'}
 if($Arguments[0]-ne'devices'){$current=Adb -Arguments @('devices','-l');Assert-OnlyEmulatorInventory -Serial $Serial -Inventory $current}
 $script:commandIndex++;$prefix=Join-Path $OutputDirectory ('cmd-'+$script:commandIndex)
 # Every invocation, including HOST inventory, has an explicit emulator serial. No physical bypass exists.
 $argsList=@('-s',$Serial)+$Arguments;$quoted=@($argsList|ForEach-Object {'"'+$_.Replace('"','\"')+'"'})
 $p=Start-Process -FilePath $AdbPath -ArgumentList $quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput "$prefix.out" -RedirectStandardError "$prefix.err"
 if(-not$p.WaitForExit(30000)){$p.Kill();throw 'Bounded emulator ADB command timed out'};$p.WaitForExit();$text=Get-Content "$prefix.out" -Raw -ErrorAction SilentlyContinue
 [ordered]@{serial=$Serial;arguments=$Arguments;exitCode=$p.ExitCode}|ConvertTo-Json|Set-Content "$prefix.json"
 if($p.ExitCode-ne0-and-not$AllowFailure){throw "Emulator command failed; inspect $prefix"};return [string]$text
}
# Host-server enumeration only: stop before ANY device-target command if a physical/offline/unknown serial exists.
$devices=Adb -Arguments @('devices','-l');$devices|Set-Content "$OutputDirectory/devices.txt"
Assert-OnlyEmulatorInventory -Serial $Serial -Inventory $devices
$qemu=(Adb -Arguments @('shell','getprop','ro.kernel.qemu')).Trim();$api=(Adb -Arguments @('shell','getprop','ro.build.version.sdk')).Trim();$release=(Adb -Arguments @('shell','getprop','ro.build.version.release')).Trim();$hardware=(Adb -Arguments @('shell','getprop','ro.hardware')).Trim()
Assert-Api22EmulatorIdentity -Qemu $qemu -API $api -Release $release -Hardware $hardware
$package='com.rdx.fullscreen.api22tls';if((Adb -Arguments @('shell','pm','list','packages',$package))-match('(?m)^package:'+ [regex]::Escape($package)+'\s*$')){throw 'Qualifier already installed: preserve prior evidence and uninstall separately first'}
$run='api22_'+[guid]::NewGuid().ToString('N');$installed=$false;$complete=$false
try{
 $identity=[ordered]@{serial=$Serial;API=$api;release=$release;qemu=$qemu;hardware=$hardware;fingerprint=(Adb -Arguments @('shell','getprop','ro.build.fingerprint')).Trim();abi=(Adb -Arguments @('shell','getprop','ro.product.cpu.abi')).Trim();apkSHA256=$freeze.sha256;runId=$run};$identity|ConvertTo-Json|Set-Content "$OutputDirectory/runtime-identity.json"
 [void](Adb -Arguments @('install','-t',$apk));$installed=$true
 [void](Adb -Arguments @('shell','am','start','-W','-n',"$package/.TlsQualificationActivity",'-a','RUN_API22_TLS','--es','run_id',$run,'--es','apk_sha256',$freeze.sha256,'--ei','mechanics_cases',[string]$MechanicsCases,'--ei','combined_cases',[string]$CombinedCases))
 $until=[DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
 while([DateTime]::UtcNow-lt$until){$text=Adb -Arguments @('exec-out','run-as',$package,'cat',"files/runs/$run/results.json") -AllowFailure;try{$json=$text|ConvertFrom-Json;if($json.complete-eq$true){[IO.File]::WriteAllText("$OutputDirectory/results.json",$text);$complete=$true;break}}catch{};Start-Sleep -Seconds 2}
 foreach($name in @('results.txt','provider-info.json','trace-summary.json','failure-details.txt','progress.json','close-probe-before.txt','close-probe-after.json')){$text=Adb -Arguments @('exec-out','run-as',$package,'cat',"files/runs/$run/$name") -AllowFailure;[IO.File]::WriteAllText("$OutputDirectory/$name",$text)}
 (Adb -Arguments @('logcat','-d','-v','threadtime','-s','RDX.Api22TLS:I','AndroidRuntime:E','libc:F','*:S'))|Set-Content "$OutputDirectory/logcat.txt"
 if(-not$complete){throw 'INCONCLUSIVE: no durable completed result within bounded wait'}
 & "$PSScriptRoot/Compare-Api22TlsResults.ps1" -Results "$OutputDirectory/results.json" -Output "$OutputDirectory/comparison.json"
}finally{
 if($installed){Get-ChildItem -LiteralPath $OutputDirectory -File|Get-FileHash|ConvertTo-Json|Set-Content "$OutputDirectory/evidence-before-uninstall.json";[void](Adb -Arguments @('uninstall',$package));$path=Adb -Arguments @('shell','pm','list','packages',$package);$ps=Adb -Arguments @('shell','ps');$process=@($ps-split'\r?\n'|Where-Object {$_-match'\bcom\.rdx\.fullscreen\.api22tls\s*$'});if($path-match('(?m)^package:'+ [regex]::Escape($package)+'\s*$')-or$process.Count){throw 'Qualifier cleanup not verified'};[ordered]@{packageAbsent=$true;processAbsent=$true;data='Normal successful uninstall guarantee; no privileged private-directory probe';resultsRetrieved=$complete}|ConvertTo-Json|Set-Content "$OutputDirectory/cleanup.json"}
}
