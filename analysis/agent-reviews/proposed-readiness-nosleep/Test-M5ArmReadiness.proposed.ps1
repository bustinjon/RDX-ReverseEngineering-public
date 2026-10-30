param(
 [Parameter(Mandatory=$true)][string]$AdbPath,
 [Parameter(Mandatory=$true)][string]$Serial,
 [Parameter(Mandatory=$true)][string]$SessionDirectory,
 [ValidateRange(5,15)][int]$StabilizationSeconds=5,
 [Parameter(Mandatory=$true)][string]$OutputDirectory
)
# READ ONLY ON DEVICE. This is not a live authorization or an arming command.
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
. "$root/tools/m5/M5ArmReadiness.ps1"
$samples=[Collections.Generic.List[object]]::new();$records=[Collections.Generic.List[object]]::new();$failure='';$proof=$null;$state=$null
$clock=[Environment]::TickCount64
if(Test-Path -LiteralPath $OutputDirectory){Write-Output 'NOT_READY_TO_ARM: fresh output directory required';return}
New-Item -ItemType Directory -Path $OutputDirectory|Out-Null
$OutputDirectory=(Resolve-Path -LiteralPath $OutputDirectory).Path
function ReadDevice([string[]]$Arguments){
 # Every device operation goes through this closed command allowlist.
 $key=$Arguments -join '|'
 $allowed=$key-match '^shell\|getprop\|ro\.(build\.(fingerprint|version\.(sdk|release))|product\.cpu\.abi)$'-or$key-in@(
  'shell|cat|/proc/sys/kernel/random/boot_id','shell|dumpsys|activity|activities','shell|dumpsys|activity|services','shell|dumpsys|window','shell|dumpsys|display',
  'shell|dumpsys|package|com.rdx.fullscreen.m5permission','shell|pm|list|packages|-u','shell|pm|path|com.rdx.fullscreen.m5permission','shell|ps')
 if($key-eq'shell|service|call|activity|217'){$allowed=$script:frameworkVerified}
 if($Arguments.Count-eq3-and$Arguments[0]-eq'pull'){
  $remote=$Arguments[1];$local=[IO.Path]::GetFullPath($Arguments[2]);$allowed=$local.StartsWith($OutputDirectory+[IO.Path]::DirectorySeparatorChar)-and($remote-in@('/system/framework/framework.jar','/system/framework/services.jar')-or($script:installedApk-and$remote-eq$script:installedApk))
 }
 if(-not$allowed){throw 'Internal read-only command allowlist refusal'}
 $si=[Diagnostics.ProcessStartInfo]::new();$si.FileName=$AdbPath;$si.UseShellExecute=$false;$si.CreateNoWindow=$true;$si.RedirectStandardOutput=$true;$si.RedirectStandardError=$true
 foreach($a in @('-s',$Serial)+$Arguments){$si.ArgumentList.Add($a)}
 $p=[Diagnostics.Process]::new();$p.StartInfo=$si;$start=[Environment]::TickCount64;$utc=[DateTime]::UtcNow.ToString('o');[void]$p.Start()
 $out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$timeout=-not$p.WaitForExit(15000);if($timeout){$p.Kill();$p.WaitForExit()}
 $stdout=$out.GetAwaiter().GetResult();$stderr=$err.GetAwaiter().GetResult();$code=$p.ExitCode;$p.Dispose();$n=$records.Count
 [IO.File]::WriteAllText("$OutputDirectory/$n.stdout.txt",$stdout);[IO.File]::WriteAllText("$OutputDirectory/$n.stderr.txt",$stderr)
 $records.Add([pscustomobject]@{utc=$utc;startMs=$start;endMs=[Environment]::TickCount64;serial=$Serial;arguments=$Arguments;exit=$code;timeout=$timeout;stdout="$n.stdout.txt";stderr="$n.stderr.txt"})
 if($timeout-or$code-ne0-or$stderr-match'(?i)error|denied|unauthorized|offline'){throw "Read-only query failed: $key"};return $stdout
}
try{
 if($Serial-ne'00000000'){throw 'Wrong target serial; no ADB invoked'}
 $SessionDirectory=(Resolve-Path -LiteralPath $SessionDirectory).Path
 # Require provenance before any ADB process; no user-supplied READY artifact accepted.
 $state=Get-Content "$SessionDirectory/session.json" -Raw|ConvertFrom-Json
 $proof=Get-Content "$SessionDirectory/fresh-install-proof.json" -Raw|ConvertFrom-Json
 if($state.phase-ne'INSTALLED'-or$state.serial-ne$Serial-or$state.apkSHA256-ne$script:M5FrozenHash-or$proof.schema-ne1-or$proof.runId-ne$state.runId-or$proof.serial-ne$Serial-or$proof.apkSHA256-ne$script:M5FrozenHash-or$proof.absentBeforeInstall-ne$true){throw 'Fresh unarmed installation provenance missing or inconsistent'}
 foreach($pair in @(@('m5-installed-package.txt',$proof.packageDumpSHA256),@('m5-install-success.txt',$proof.installReplySHA256),@('packages-before-install.txt',$proof.inventorySHA256))){if((Get-FileHash -LiteralPath "$SessionDirectory/$($pair[0])").Hash-ne$pair[1]){throw 'Fresh-install provenance file mismatch'}}
 $inventory=Get-Content "$SessionDirectory/packages-before-install.txt" -Raw
 if($inventory-match'(?m)^package:com\.rdx\.fullscreen\.m5permission\s*$'-or$inventory-notmatch'(?m)^package:com\.honda\.androidauto\.projection\.sink\s*$'-or@($inventory-split'[\r\n]+'|Where-Object {$_-and$_-notmatch'^package:[a-zA-Z0-9_.]+\s*$'}).Count){throw 'Absent-before inventory not proven'}
 $initial=Get-M5PackageFacts (Get-Content "$SessionDirectory/m5-installed-package.txt" -Raw)
 if(-not$initial.fresh-or$initial.uid-ne$proof.uid-or$initial.firstInstallTime-ne$proof.firstInstallTime-or$initial.lastUpdateTime-ne$proof.lastUpdateTime-or(@((Get-Content "$SessionDirectory/m5-install-success.txt" -Raw)-split'[\r\n]+'|Where-Object{$_.Trim()-eq'Success'})).Count-eq0){throw 'Fresh never-launched state not proven'}
 if(-not(Test-Path -LiteralPath $AdbPath -PathType Leaf)){throw 'Explicit ADB executable not found; no ADB invoked'}
 $script:frameworkVerified=$false;$script:installedApk=''
 $identity=Get-M5IdentitySafe $Serial (ReadDevice @('shell','getprop','ro.build.fingerprint')) (ReadDevice @('shell','getprop','ro.build.version.sdk')) (ReadDevice @('shell','getprop','ro.build.version.release')) (ReadDevice @('shell','getprop','ro.product.cpu.abi'))
 if(-not$identity){throw 'RDX identity/API/ABI mismatch'}
 if((ReadDevice @('shell','cat','/proc/sys/kernel/random/boot_id')).Trim()-ne$proof.bootId){throw 'Device rebooted since fresh install; provenance review required'}
 $path=(ReadDevice @('shell','pm','path','com.rdx.fullscreen.m5permission')).Trim()
 if($path-notmatch'^package:(/data/app/[A-Za-z0-9_./-]+\.apk)$'){throw 'Installed M5 path ambiguous'};$script:installedApk=$Matches[1]
 [void](ReadDevice @('pull',$script:installedApk,"$OutputDirectory/installed-m5.apk"))
 if((Get-FileHash "$OutputDirectory/installed-m5.apk").Hash-ne$script:M5FrozenHash){throw 'Installed M5 frozen hash mismatch'}
 # Pin transaction dispatch and implementation before the only Binder getter.
 # Each entry lists every build whose framework.jar/services.jar were reviewed line-by-line against
 # the saved build-168 copy and found identical (or differing only in decompiler-artifact annotations
 # unrelated to isInLockTaskMode) for this one transaction: build 168 (original review) and build 14
 # (live car, reviewed 2026-10-26 after a live ARM refusal; see analysis/agent-reviews/proposed-framework-pin/).
 foreach($item in @(@('framework',@('76073B0BD397FFE3412F2EA1CF10BF28CC4F2018D62E5621F2443C70B14374B5','BCED4FA8112E2A2D1EDA2FD0007EA962718BFFC08B2B9A9D9A3529A98EE3F2D6')),@('services',@('98B4C3D3E2B0F2DDF3CEB9B582DED93DC0E73D922BB913D0B263E8812A0B6474','53F33BED0D73584F925932B363F0B1BF554F4FF56E489D0B4BDC7B8174453F57')))){
  [void](ReadDevice @('pull',"/system/framework/$($item[0]).jar","$OutputDirectory/$($item[0]).jar"))
  if((Get-FileHash "$OutputDirectory/$($item[0]).jar").Hash-notin$item[1]){throw 'Framework binary not a reviewed getter/implementation pair; refuse numeric Binder transaction'}
 };$script:frameworkVerified=$true
 do{
  $s=[ordered]@{startMs=[Environment]::TickCount64;lockBefore=ReadDevice @('shell','service','call','activity','217');activities=ReadDevice @('shell','dumpsys','activity','activities');window=ReadDevice @('shell','dumpsys','window');services=ReadDevice @('shell','dumpsys','activity','services');package=ReadDevice @('shell','dumpsys','package','com.rdx.fullscreen.m5permission');packages=ReadDevice @('shell','pm','list','packages','-u');processes=ReadDevice @('shell','ps');display=ReadDevice @('shell','dumpsys','display');lockAfter=ReadDevice @('shell','service','call','activity','217');endMs=[Environment]::TickCount64}
  $samples.Add([pscustomobject]$s);$a=Get-M5SampleAssessment $samples[-1] $proof;if(-not$a.safe){throw ($a.reasons-join'; ')}
  if($samples.Count-gt1-and$samples[-1].startMs-$samples[0].startMs-ge$StabilizationSeconds*1000){break}
  if([Environment]::TickCount64-$samples[0].startMs-gt20000){throw 'Bounded readiness observation expired'}
 }while($true)
 $window=Get-M5WindowAssessment @($samples.ToArray()) $proof ([Environment]::TickCount64) $StabilizationSeconds
 if(-not$window.ready){throw ($window.reasons-join'; ')}
}catch{$failure=$_.Exception.Message}
$resultRunId='';if($null-ne$state-and$null-ne$state.PSObject.Properties['runId']){$resultRunId=[string]$state.runId}
$result=[ordered]@{schema=1;result=if($failure){'NOT_READY_TO_ARM'}else{'READY_TO_ARM'};reasons=@($failure|Where-Object {$_});utc=[DateTime]::UtcNow.ToString('o');createdMs=[Environment]::TickCount64;startedMs=$clock;lastSampleStartMs=if($samples.Count){$samples[-1].startMs}else{0};stabilizationSeconds=$StabilizationSeconds;serial=$Serial;runId=$resultRunId;apkSHA256=$script:M5FrozenHash;sampleCount=$samples.Count;runtimeGetterQualified='NOT PREVIOUSLY EXECUTED: current successful checks required';deviceMutation='NONE';freshInstallInference='Never launched/stopped + absent-before normal install: no app run/journal/request. Not a private journal read.'}
ConvertTo-Json -InputObject $records.ToArray() -Depth 6|Set-Content "$OutputDirectory/commands.json"
ConvertTo-Json -InputObject $samples.ToArray() -Depth 5|Set-Content "$OutputDirectory/samples.json"
$result|ConvertTo-Json -Depth 5|Set-Content "$OutputDirectory/readiness.json"
if($failure){Write-Output "NOT_READY_TO_ARM: $failure"}else{Write-Output 'READY_TO_ARM'}
