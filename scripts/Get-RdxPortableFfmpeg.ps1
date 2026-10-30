$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$dest=Join-Path $root 'tools/ffmpeg'
New-Item -ItemType Directory -Path $dest -Force|Out-Null
$url='https://www.gyan.dev/ffmpeg/builds/packages/ffmpeg-9.0.2-essentials_build.zip'
$expected='60F467265B1E312373DBCD92200C2618A74850F98D3D078E94296BB3FA2047BA'
$archive=Join-Path $dest 'ffmpeg-9.0.2-essentials_build.zip'
if(-not(Test-Path $archive)){Invoke-WebRequest -Uri $url -OutFile $archive -TimeoutSec 180}
if((Get-FileHash $archive).Hash-ne$expected){throw 'Archive differs from published SHA256; do not execute'}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::OpenRead($archive)
try {
 $inventory=@($zip.Entries|ForEach-Object {[ordered]@{name=$_.FullName;bytes=$_.Length;compressedBytes=$_.CompressedLength;attributes=$_.ExternalAttributes}})
 foreach($entry in $zip.Entries){
  $resolved=[IO.Path]::GetFullPath((Join-Path $dest $entry.FullName))
  if(-not$resolved.StartsWith($dest+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Archive path traversal'}
  if((($entry.ExternalAttributes-shr16)-band0xf000)-eq0xa000){throw 'Archive symlink rejected'}
 }
 $inventory|ConvertTo-Json -Depth 5|Set-Content "$dest/archive-inventory.json"
 # Extract only the two host tools and license/readme; no installer, PATH change or ffplay.
 foreach($entry in $zip.Entries|Where-Object {$_.FullName-match'/bin/(ffmpeg|ffprobe)\.exe$|/(LICENSE|README)(\.txt)?$'}){
  $target=Join-Path $dest $entry.FullName
  New-Item -ItemType Directory -Path (Split-Path $target) -Force|Out-Null
  if(-not(Test-Path $target)){[IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$target)}
  $stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create()
  try{$entryHash=[Convert]::ToHexString($sha.ComputeHash($stream))}finally{$stream.Dispose();$sha.Dispose()}
  if((Get-FileHash $target).Hash-ne$entryHash){throw 'Existing/extracted tool differs from verified archive; do not execute'}
 }
}finally{$zip.Dispose()}
$bins=@(Get-ChildItem $dest -Recurse -File|Where-Object {$_.Name-in'ffmpeg.exe','ffprobe.exe'})
if($bins.Count-ne2){throw 'Expected exactly two extracted tools'}
foreach($bin in $bins){$bytes=[IO.File]::ReadAllBytes($bin.FullName);if($bytes[0]-ne77-or$bytes[1]-ne90){throw 'Not a PE executable'};if([BitConverter]::ToUInt16($bytes,[BitConverter]::ToInt32($bytes,60)+4)-ne0x8664){throw 'Unexpected host architecture'}}
foreach($bin in $bins){& $bin.FullName -version > "$dest/$($bin.BaseName)-version.txt";if($LASTEXITCODE-ne0){throw 'Host tool version query failed'}}
[ordered]@{utc=[DateTime]::UtcNow.ToString('o');source=$url;upstreamDownloadPage='https://ffmpeg.org/download.html';publisherPage='https://www.gyan.dev/ffmpeg/builds/';publisherChecksumURL=$url+'.sha256';publisherSHA256=$expected;archiveSHA256=(Get-FileHash $archive).Hash;version='9.0.2';files=@($bins|ForEach-Object {[ordered]@{path=$_.FullName;sha256=(Get-FileHash $_.FullName).Hash}});archiveInspectedBeforeExecution=$true;globalInstall=$false;PATHModified=$false;verificationLimit='Publisher HTTPS checksum, not independent binary reproducibility or upstream source-release signature'}|ConvertTo-Json -Depth 6|Set-Content "$dest/provenance.json"
Get-Content "$dest/provenance.json"
