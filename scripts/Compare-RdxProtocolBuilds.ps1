param([Parameter(Mandatory)][string]$First,[Parameter(Mandatory)][string]$Second,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$a=Get-Content "$First/build-validation.json" -Raw|ConvertFrom-Json
$b=Get-Content "$Second/build-validation.json" -Raw|ConvertFrom-Json
function Same-Inputs($x,$y){
 $left=@($x|ForEach-Object {$_.Path+'='+$_.Hash}|Sort-Object)
 $right=@($y|ForEach-Object {$_.Path+'='+$_.Hash}|Sort-Object)
 return @((Compare-Object $left $right)).Count-eq0
}
$sourceSame=Same-Inputs $a.sourceHashes $b.sourceHashes
$testsSame=Same-Inputs $a.testHashes $b.testHashes
$fixturesSame=Same-Inputs $a.fixtureHashes $b.fixtureHashes
function Jar-Contents([string]$Path){
 $zip=[IO.Compression.ZipFile]::OpenRead($Path);$items=@()
 try{foreach($entry in $zip.Entries){if($entry.FullName.EndsWith('/')){continue};$stream=$entry.Open();$memory=[IO.MemoryStream]::new()
  try{$stream.CopyTo($memory);$items += [pscustomobject]@{name=$entry.FullName;sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($memory.ToArray()));zipTimestamp=$entry.LastWriteTime.ToString('o')}}finally{$stream.Dispose();$memory.Dispose()}
 }}finally{$zip.Dispose()};return $items
}
$entriesA=Jar-Contents "$First/clean-foundation.jar";$entriesB=Jar-Contents "$Second/clean-foundation.jar"
$entryDiff=@(Compare-Object @($entriesA|ForEach-Object {$_.name+'='+$_.sha256}|Sort-Object) @($entriesB|ForEach-Object {$_.name+'='+$_.sha256}|Sort-Object))
$dexSame=$a.DEX_SHA256-eq$b.DEX_SHA256
$result=[ordered]@{PASS=($sourceSame-and$testsSame-and$fixturesSame-and$dexSame-and$entryDiff.Count-eq0);first=$First;second=$Second;sourceInputsEqual=$sourceSame;testInputsEqual=$testsSame;fixtureInputsEqual=$fixturesSame;DEXByteIdentical=$dexSame;DEX_SHA256=$b.DEX_SHA256;jarArchiveByteIdentical=($a.librarySHA256-eq$b.librarySHA256);jarPayloadEntriesIdentical=($entryDiff.Count-eq0);jarSHA256First=$a.librarySHA256;jarSHA256Second=$b.librarySHA256;jarEntriesFirst=$entriesA;jarEntriesSecond=$entriesB;nondeterminism='Standard jar cf retains creation/file-entry ZIP timestamps. Container hashes may differ even when all entry payloads/classes and DEX match; no timestamps normalized or artifacts overwritten.'}
$result|ConvertTo-Json -Depth 6|Set-Content -LiteralPath $Output
if(-not$result.PASS){throw 'Clean rebuild differs in inputs/semantic outputs'}
Write-Output "PASS reproducibility: DEX byte-identical; JAR payloads identical; container-identical=$($result.jarArchiveByteIdentical)"
