param(
 [Parameter(Mandatory)][string]$LogFile,
 [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]{1,64}$')][string]$RunId,
 [Parameter(Mandatory)][string]$OutputDirectory
)
# HOST ONLY. Reads a saved logcat text file; never executes device commands.
$ErrorActionPreference='Stop'
if((Get-Item -LiteralPath $LogFile).Length -gt 268435456){throw 'Saved log exceeds local bound'}
$lines=Get-Content -LiteralPath $LogFile
$begins=@(foreach($line in $lines){
 if($line -match 'DUMP_BEGIN token=([a-f0-9-]{36}) run=([A-Za-z0-9_-]{1,64}) bytes=(\d+) sha256=([a-f0-9]{64})'){
  if($Matches[2] -ceq $RunId){[pscustomobject]@{token=$Matches[1];run=$Matches[2];length=[long]$Matches[3];hash=$Matches[4]}}
 }
})
if(-not$begins.Count){throw 'No dump for specified run'}
$begin=$begins[-1] # Never silently substitute an older successful dump for a damaged newest dump.
if($begin.length -gt 65536){throw 'Dump length exceeds private journal bound'}
$chunks=@{};$endCount=$null
foreach($line in $lines){
 if($line -match 'DUMP_CHUNK token=([a-f0-9-]{36}) index=(\d+) base64=([A-Za-z0-9+/=]+)'){
  if($Matches[1] -cne $begin.token){continue}
  $index=[long]$Matches[2];$payload=$Matches[3]
  if($index -ge 55 -or $payload.Length -gt 1600){throw 'Chunk bound exceeded'}
  if($chunks.ContainsKey($index) -and $chunks[$index] -cne $payload){throw 'Conflicting duplicate chunk'}
  $chunks[$index]=$payload
 }
 if($line -match 'DUMP_END token=([a-f0-9-]{36}) chunks=(\d+)' -and $Matches[1] -ceq $begin.token){$endCount=[long]$Matches[2]}
}
$expected=[long][Math]::Ceiling($begin.length/1200.0)
if($null -eq $endCount -or $endCount -ne $expected -or $chunks.Count -ne $expected){throw 'Incomplete dump; repeat explicit DUMP only, not permission test'}
$stream=[IO.MemoryStream]::new()
try{
 for($i=[long]0;$i -lt $expected;$i++){
  if(-not$chunks.ContainsKey($i)){throw 'Missing chunk index'}
  $bytes=[Convert]::FromBase64String($chunks[$i]);$expectedBytes=[Math]::Min(1200,$begin.length-$i*1200)
  if($bytes.Length -ne $expectedBytes){throw 'Chunk byte count mismatch'}
  $stream.Write($bytes,0,$bytes.Length)
 }
 $data=$stream.ToArray()
}finally{$stream.Dispose()}
$hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($data)).ToLowerInvariant()
if($data.Length -ne $begin.length -or $hash -cne $begin.hash){throw 'Dump length/SHA256 mismatch'}
if(-not(Test-Path -LiteralPath $OutputDirectory)){[void](New-Item -ItemType Directory -Path $OutputDirectory)}
$target=Join-Path $OutputDirectory ("m5-$RunId-$($begin.token).txt")
$file=[IO.File]::Open($target,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write)
try{$file.Write($data,0,$data.Length)}finally{$file.Dispose()}
$result=[ordered]@{PASS=$true;scope='HOST reconstruction only';run=$RunId;token=$begin.token;bytes=$data.Length;sha256=$hash;file=[IO.Path]::GetFullPath($target);source=[IO.Path]::GetFullPath($LogFile)}
$result|ConvertTo-Json|Set-Content ($target+'.json')
$result|ConvertTo-Json
