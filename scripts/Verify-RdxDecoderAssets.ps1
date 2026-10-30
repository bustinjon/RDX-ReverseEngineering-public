$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$base=Join-Path $root 'analysis/parallel-aa-receiver/decoder-test'
$build=(Get-Content "$base/latest-build.txt" -Raw).Trim()
$report=Get-Content "$build/build-report.json" -Raw|ConvertFrom-Json
$audit=(Get-Content "$base/latest-audit.txt" -Raw).Trim()
$clips=@(Get-Content "$base/clips/clip-manifest.json" -Raw|ConvertFrom-Json)
if($clips.Count-ne6){throw 'Expected six inspected clips'}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::OpenRead($report.apk)
try{
 $checked=@(foreach($clip in $clips){
  $entry=$zip.GetEntry('assets/clips/'+$clip.file)
  if(-not$entry-or$entry.Length-ne$entry.CompressedLength){throw 'Missing/compressed asset; openFd may not work'}
  $stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create()
  try{$actual=[Convert]::ToHexString($sha.ComputeHash($stream))}finally{$stream.Dispose();$sha.Dispose()}
  if($actual-ne$clip.sha256-or(Get-FileHash $clip.path).Hash-ne$clip.sha256){throw 'Packaged/source clip hash mismatch'}
  if($clip.SPS.DisplayWidth-ne$clip.width-or$clip.SPS.DisplayHeight-ne$clip.height-or$clip.SPS.ProfileIdc-ne66-or$clip.BFrames-ne0-or$clip.frameCount-ne10*$clip.fps){throw 'Clip metadata invariant failed'}
  [ordered]@{asset=$entry.FullName;bytes=$entry.Length;sha256=$actual;stored=$true;SPS=$clip.SPS;fps=$clip.fps;frames=$clip.frameCount}
 })
 $catalogEntry=$zip.GetEntry('assets/clip-catalog.json');if(-not$catalogEntry){throw 'No packaged SPS catalog'}
 $reader=[IO.StreamReader]::new($catalogEntry.Open());try{$catalog=$reader.ReadToEnd()|ConvertFrom-Json}finally{$reader.Dispose()}
 foreach($clip in $clips){$c=@($catalog.clips|Where-Object file -eq $clip.file);if($c.Count-ne1-or$c[0].sha256-ne$clip.sha256-or$c[0].SPS.CodedHeight-ne$clip.SPS.CodedHeight){throw 'Packaged catalog mismatch'}}
}finally{$zip.Dispose()}
$java='C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin/java.exe';$bt='C:/Program Files (x86)/Android/android-sdk/build-tools/32.0.0'
& $java -jar "$bt/lib/apksigner.jar" verify --min-sdk-version 22 --max-sdk-version 22 --verbose --print-certs $report.apk *> "$audit/signature-fresh.txt"
if($LASTEXITCODE-ne0){throw 'Fresh signature check failed'}
& "$bt/zipalign.exe" -c -v 4 $report.apk *> "$audit/zipalign-fresh.txt"
if($LASTEXITCODE-ne0){throw 'Fresh alignment check failed'}
& "$bt/aapt.exe" list -v $report.apk > "$audit/zip-list-verbose.txt"
if($LASTEXITCODE-ne0){throw 'ZIP inventory failed'}
[ordered]@{utc=[DateTime]::UtcNow.ToString('o');PASS=$true;apk=$report.apk;sha256=(Get-FileHash $report.apk).Hash;version=$report.version;clips=$checked;catalogMatches=$true;noVehicleExecution=$true}|ConvertTo-Json -Depth 8|Set-Content "$audit/packaged-assets-validation.json"
Write-Output 'PASS: six packaged uncompressed MP4 hashes/SPS catalog/frame counts, API22 signature and alignment'
