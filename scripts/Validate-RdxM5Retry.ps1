$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$project=Join-Path $root 'analysis/parallel-aa-receiver/m5-permission'
$session=(Get-Content "$project/latest-retry-session.txt" -Raw).Trim()
$build=(Get-Content "$project/latest-build.txt" -Raw).Trim()
$auditDir=(Get-Content "$project/latest-audit.txt" -Raw).Trim()
$audit=Get-Content "$auditDir/audit.json" -Raw|ConvertFrom-Json
$report=Get-Content "$build/build-report.json" -Raw|ConvertFrom-Json
$hostDir=(Get-Content "$project/latest-host-test.txt" -Raw).Trim()
$hostResult=Get-Content "$hostDir/result.json" -Raw|ConvertFrom-Json
foreach($entry in @($report.sourceHashes)+@($hostResult.inputHashes)){
 if((Get-FileHash -LiteralPath $entry.Path).Hash -ne $entry.Hash){throw 'Untested/unaudited source change'}
}
if(-not$audit.PASS -or (Get-FileHash $report.apk).Hash -ne $audit.sha256){throw 'APK audit/hash failure'}
$callSites=@(Get-Content "$auditDir/dexdump.txt"|Where-Object {$_ -match 'invoke-.*Landroid/hardware/usb/UsbManager;\.requestPermission:'})
if($callSites.Count -ne 1){throw 'Expected exactly one SDK request invoke instruction'}
if(@($audit.definedClasses|Where-Object {$_ -match 'PermissionTests|Rig|Fake'}).Count){throw 'Host tests leaked into APK'}
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -Path @("$root/scripts/RdxDex.cs","$root/scripts/RdxDexApi.cs")
$definitions=[Collections.Generic.HashSet[string]]::new();$parents=@{};$platformHashes=@()
foreach($name in @('core-libart.jar','framework.jar')){
 $path=Join-Path $root "adb/RDX-Audit/framework/$name" # LOCAL previously pulled files only; no device command.
 $platformHashes+=Get-FileHash $path
 $zip=[IO.Compression.ZipFile]::OpenRead($path)
 try{foreach($entry in $zip.Entries|Where-Object FullName -match '^classes\d*\.dex$'){
  $stream=$entry.Open();$memory=[IO.MemoryStream]::new()
  try{$stream.CopyTo($memory);$dex=[RdxOffline.Dex]::new($memory.ToArray());$api=[RdxOffline.DexApi]::new($dex)
   foreach($definition in $api.Definitions){[void]$definitions.Add($definition)}
   foreach($pair in $api.Parents.GetEnumerator()){$parents[$pair.Key]=@($pair.Value)}
  }finally{$stream.Dispose();$memory.Dispose()}
 }}finally{$zip.Dispose()}
}
function Resolve-Method([string]$Type,[string]$Suffix,[Collections.Generic.HashSet[string]]$Seen){
 if(-not$Seen.Add($Type)){return $false}
 if($definitions.Contains($Type+'->'+$Suffix)){return $true}
 if($Suffix.StartsWith('<init>')){return $false}
 foreach($parent in $parents[$Type]){if(Resolve-Method $parent $Suffix $Seen){return $true}}
 return $false
}
$methods=Get-Content "$auditDir/dex-methods.txt"
$apiResults=@(foreach($method in $methods){
 if($method.StartsWith('Lcom/rdx/fullscreen/m5permission/')){continue}
 $parts=$method -split '->',2
 $intrinsic=$parts[0].StartsWith('[') -and $parts[1] -eq 'clone()Ljava/lang/Object;'
 $found=$intrinsic -or (Resolve-Method $parts[0] $parts[1] ([Collections.Generic.HashSet[string]]::new()))
 [pscustomobject]@{method=$method;presentInActualAPI22Definitions=$found}
})
$apiResults|ConvertTo-Json|Set-Content "$session/api22-methods.json"
if(@($apiResults|Where-Object {-not$_.presentInActualAPI22Definitions}).Count){throw 'API unavailable on pulled target platform'}
$protected=Get-Content "$session/protected-apks-before.json" -Raw|ConvertFrom-Json
foreach($entry in $protected){if((Get-FileHash $entry.Path).Hash -ne $entry.Hash){throw 'Historical APK modified'}}
$result=[ordered]@{PASS=$true;scope='OFFLINE ONLY: source, local files, host JVM and SDK tools; no ADB/device';apk=$report.apk;sha256=$report.sha256;build=$build;audit=$auditDir;host=$hostDir;hostSummary=$hostResult.output;staticSDKRequestCallSites=$callSites.Count;API22MethodChecks=$apiResults.Count;targetFiles=$platformHashes;compiler='javac source7/target7, SDK33 compile stubs, D8min21; all method refs verified against pulled D.1.6.4 API22 definitions/inherited methods';historicalAPKCount=$protected.Count;allHistoricalAPKsUnchanged=$true;manualFlowReview='Separate final clearance document required';sourceHashes=$report.sourceHashes;testHashes=$hostResult.inputHashes;M4='PASS (historical)';M5='INCONCLUSIVE (historical); new APK not live tested';M6='DISABLED; no implementation change';realDeviceUsed=$false}
$result|ConvertTo-Json -Depth 6|Set-Content "$session/validation.json"
$result|ConvertTo-Json -Depth 6
