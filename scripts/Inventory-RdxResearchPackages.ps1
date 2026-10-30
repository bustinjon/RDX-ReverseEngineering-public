param([Parameter(Mandatory=$true)][string]$OutputDirectory)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$OutputDirectory=[IO.Path]::GetFullPath($OutputDirectory)
if(-not$OutputDirectory.StartsWith($root+[IO.Path]::DirectorySeparatorChar)){throw 'Inventory must stay inside project'}
[IO.Directory]::CreateDirectory($OutputDirectory)|Out-Null
$aapt='C:/Program Files (x86)/Android/android-sdk/build-tools/32.0.0/aapt.exe'
$files=@(& rg --files -g '*.apk' (Join-Path $root 'analysis'))
$cache=@{};$rows=@()
foreach($file in $files){
 $hash=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
 if(-not$cache.ContainsKey($hash)){
  $badging=@(& $aapt dump badging $file 2>&1);$exit=$LASTEXITCODE
  $line=$badging|Where-Object {$_-match'^package: '}|Select-Object -First 1
  if($exit-ne0-or$line-notmatch"package: name='([^']+)' versionCode='([^']*)' versionName='([^']*)'"){throw "Cannot identify APK manifest: $file"}
  $cache[$hash]=[pscustomobject]@{package=$Matches[1];versionCode=$Matches[2];versionName=$Matches[3]}
 }
 $m=$cache[$hash];$rel=[IO.Path]::GetFullPath($file).Substring($root.Length+1).Replace('\','/')
 $purpose=switch -Regex ($rel){'/m5-permission/' {'M5 USB permission-only';break};'/usb-probe/' {'M4 passive USB inventory';break};'/decoder-test/' {'Prepared decoder test; not live-authorized here';break};'/grid-test/' {'Prepared visual grid test';break};'/m6-aoa/' {'M6 OFFLINE DISABLED; must never install in this session';break};'/api22-tls-qualifier/' {'Emulator-only qualifier; never vehicle';break};default {'Prototype, archived build, factory copy or patched research artifact'}}
 $rows+=[pscustomobject]@{path=$rel;sha256=$hash;package=$m.package;versionName=$m.versionName;versionCode=$m.versionCode;purpose=$purpose;attribution=if($m.package.StartsWith('com.rdx.fullscreen.')){'PROJECT MANIFEST CONFIRMED'}else{'FACTORY/OTHER IDENTITY; NOT A CLEANUP TARGET'}}
}
$rows|Sort-Object package,path|Export-Csv "$OutputDirectory/apk-manifest-inventory.csv" -NoTypeInformation
$rows|Sort-Object package,path|ConvertTo-Json -Depth 5|Set-Content "$OutputDirectory/apk-manifest-inventory.json"
$packages=@($rows|Where-Object attribution -eq 'PROJECT MANIFEST CONFIRMED'|Group-Object package|ForEach-Object {
 $pkg=$_.Name
 $hits=@(& rg -l -F -g '*LIVE*RESULTS.md' -g 'LIVE-TEST-*-RESULTS.md' -- $pkg (Join-Path $root 'analysis/parallel-aa-receiver'))
 [pscustomobject]@{package=$pkg;manifestConfirmed=$true;artifactCount=$_.Count;versions=@($_.Group.versionName|Sort-Object -Unique);purposes=@($_.Group.purpose|Sort-Object -Unique);liveHistoryReports=$hits;liveInstalledNow='UNKNOWN UNTIL VEHICLE INVENTORY';action='NONE; inventory only'}
})
$packages|ConvertTo-Json -Depth 6|Set-Content "$OutputDirectory/project-packages.json"
Write-Output "HOST MANIFEST INVENTORY: $($rows.Count) APK paths /$($cache.Count) distinct hashes /$($packages.Count) project package identities; no ADB or uninstall."
$packages|Select-Object package,artifactCount,versions|Format-Table -AutoSize
