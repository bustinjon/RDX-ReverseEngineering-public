param([Parameter(Mandatory=$true)][string]$Session)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$Session=(Resolve-Path $Session).Path
$rows=@()
$files=@(Get-ChildItem "$root/tools/api22","$root/tools/m5" -File -Filter *.ps1)+@(Get-ChildItem "$root/scripts" -File | Where-Object Name -in @('Build-RdxApi22Qualifier.ps1','Freeze-RdxApi22Qualifier.ps1','Audit-RdxOfflineFoundation.ps1','Finalize-RdxOfflineFreeze.ps1','Build-RdxCleanFoundation.ps1','Test-RdxFreezeTools.ps1','Seal-RdxOfflineFreeze.ps1'))+@(Get-Item "$root/tools/Test-RdxOfflineIntegrity.ps1")
foreach($f in $files){$tokens=$null;$errors=$null;[void][Management.Automation.Language.Parser]::ParseFile($f.FullName,[ref]$tokens,[ref]$errors);if($errors.Count){throw "Parse failure: $($f.FullName) $errors"};$rows+=[pscustomobject]@{test=$f.Name;result='PARSE PASS'}}
. "$root/tools/api22/EmulatorSafety.ps1"
foreach($status in @('device','offline','unauthorized','recovery','sideload','no permissions')){
 $refused=$false;try{Assert-OnlyEmulatorInventory -Serial emulator-5554 -Inventory "List of devices attached`nemulator-5554 device`nPHYSICAL $status"}catch{$refused=$true}
 if(-not$refused){throw 'Physical inventory not refused'};$rows+=[pscustomobject]@{test="physical inventory $status";result='REFUSED; PURE STRING TEST; NO ADB'}
}
Assert-OnlyEmulatorInventory -Serial emulator-5554 -Inventory "List of devices attached`nemulator-5554 device`nemulator-5556 device"
Assert-Api22EmulatorIdentity -Qemu 1 -API 22 -Release 5.1.1 -Hardware goldfish
$rows+=[pscustomobject]@{test='Explicit emulator selection and identity';result='PURE MODEL PASS; NO ADB'}
$out=Join-Path $Session 'final-tool-qa';New-Item -ItemType Directory -Force $out|Out-Null
& "$root/tools/api22/Compare-Api22TlsResults.ps1" -Results "$Session/qualifier-bidirectional-desktop/results.json" -Output "$out/desktop-comparison.json" | Out-Null
$cmp=Get-Content "$out/desktop-comparison.json" -Raw|ConvertFrom-Json
if($cmp.runtimeEvidence-or$cmp.automaticTargetQualification-or@($cmp.rows|Where-Object classification -ne MATCH).Count){throw 'Comparator incorrectly classified desktop evidence'}
$rows+=[pscustomobject]@{test='Final 20-group desktop comparator';result='MATCH; NOT API22 EVIDENCE'}
$r=Get-Content "$Session/qualifier-bidirectional-desktop/results.json" -Raw|ConvertFrom-Json
$r.tests.PSObject.Properties.Remove('bidirectional-coverage');$r|ConvertTo-Json -Depth 20|Set-Content "$out/missing-group.json"
$refused=$false;try{& "$root/tools/api22/Compare-Api22TlsResults.ps1" -Results "$out/missing-group.json" -Output "$out/invalid-comparison.json"|Out-Null}catch{$refused=$true}
if(-not$refused){throw 'Comparator accepted missing group'}
$rows+=[pscustomobject]@{test='Missing mandatory bidirectional group';result='REFUSED'}
$rows|ConvertTo-Json -Depth 4|Set-Content "$out/tool-tests.json"
Write-Output "PASS: $($rows.Count) final syntax/host-model/comparator checks. No process/device commands invoked."
