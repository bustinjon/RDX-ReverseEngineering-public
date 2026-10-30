# Host-only fixture authoring. No production Java codec, hardware, network or ADB invocation.
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$output=Join-Path $root 'analysis/parallel-aa-receiver/clean-receiver/test-fixtures/v1'
if(Test-Path -LiteralPath $output){throw 'v1 already exists; golden fixture versions are immutable'}
New-Item -ItemType Directory -Path $output | Out-Null
$cases=[Collections.Generic.List[object]]::new()
function Fixture([string]$Id,[string]$Kind,[string]$Verdict,[string]$Hex,[string]$Expected,[string]$Purpose,[string]$Provenance){
 $bytes=[Convert]::FromHexString($Hex)
 [IO.File]::WriteAllBytes((Join-Path $output ($Id+'.bin')),$bytes)
 $sha=(Get-FileHash -LiteralPath (Join-Path $output ($Id+'.bin'))).Hash
 $item=[ordered]@{id=$Id;kind=$Kind;verdict=$Verdict;purpose=$Purpose;expectedEncodedHex=$Hex.ToLowerInvariant();expectedDecodedRepresentation=$Expected;SHA256=$sha;bytes=$bytes.Length;provenance=$Provenance;privateAuthenticationMaterial=$false}
 $item|ConvertTo-Json -Depth 5|Set-Content (Join-Path $output ($Id+'.json'))
 $cases.Add([pscustomobject]$item)
}
$manual='Independently hand-encoded from pinned AASDK framing and Honda/OHU/OAA schema facts; no production writer invoked.'
Fixture 'version-request' 'wire' 'ACCEPT' '00030006000100010001' '0:0:000100010001' 'Control raw major1/minor1 request' $manual
Fixture 'two-complete' 'wire' 'ACCEPT' '000300060001000100010203000480000800' '0:0:000100010001|2:0:80000800' 'Concatenated control and service data' $manual
Fixture 'fragmented' 'wire' 'ACCEPT' '0201000200000005000b0200000108020200029601' '2:0:000b089601' 'FIRST/continuation/LAST; total5; no repeated type' $manual
Fixture 'fragment-then-complete' 'wire' 'ACCEPT' '0201000200000005000b02000001080202000296010703000480000800' '2:0:000b089601|7:0:80000800' 'Next frame begins immediately after fragmented completion' $manual
Fixture 'interleaved' 'wire' 'ACCEPT' '0201000200000004000b0701000200000004000c020200020801070200020802' '2:0:000b0801|7:0:000c0802' 'Two channels have independent partial states' $manual
Fixture 'control-flag' 'wire' 'ACCEPT' '00070004000b0801' '0:4:000b0801' 'CONTROL independent from fragmentation' $manual
Fixture 'empty-envelope' 'frame' 'ACCEPT' '02030000' '2:3:-1:' 'Zero body structurally legal; typed-message layer rejects it' $manual
Fixture 'opaque-encrypted' 'frame' 'ACCEPT' '000b0003999897' '0:11:-1:999897' 'Encrypted body remains opaque; no TLS executed' $manual
Fixture 'first-only' 'frame' 'ACCEPT' '0201000200000005000b' '2:1:5:000b' 'FIRST total extension' $manual
Fixture 'middle-only' 'frame' 'ACCEPT' '0200000108' '2:0:-1:08' 'Structurally valid middle; logical use requires pending first' $manual
Fixture 'last-only' 'frame' 'ACCEPT' '020200029601' '2:2:-1:9601' 'Structurally valid last; logical use requires pending first' $manual
Fixture 'reserved-flags' 'frame' 'REJECT' '001300020001' '-' 'Unsupported flag bit4' $manual
Fixture 'truncated-header' 'frame' 'REJECT' '000300' '-' 'Incomplete BE16 body length' $manual
Fixture 'truncated-extension' 'frame' 'REJECT' '020100020000' '-' 'Incomplete BE32 total' $manual
Fixture 'truncated-body' 'frame' 'REJECT' '000300060001000100' '-' 'Declared body exceeds supplied bytes' $manual
Fixture 'unsigned-total-overflow' 'frame' 'REJECT' '02010000ffffffff' '-' 'Unsigned BE32 exceeds local message maximum' $manual
Fixture 'unexpected-continuation' 'wire' 'REJECT' '020200029601' '-' 'Logical continuation without pending first' $manual
Fixture 'overlapping-first' 'wire' 'REJECT' '0201000200000005000b020300020001' '-' 'Complete frame overlaps pending message on same channel' $manual
Fixture 'fragment-underflow' 'wire' 'REJECT' '0201000200000005000b0202000108' '-' 'LAST cannot complete declared total' $manual
Fixture 'fragment-overflow' 'wire' 'REJECT' '0201000200000002000b0202000108' '-' 'Per-channel received bytes exceed declared total' $manual
Fixture 'incomplete-fragments' 'wire' 'REJECT' '0201000200000005000b' '-' 'EOF while logical fragment remains pending' $manual
$max=New-Object byte[] 16384
$max[0]=0;$max[1]=11
Fixture 'maximum-body' 'frame' 'ACCEPT' ('01034000'+[Convert]::ToHexString($max)) ('1:3:-1:'+([Convert]::ToHexString($max).ToLowerInvariant())) 'Actual default maximum body16384' 'Independently generated deterministic zero-filled maximum by PowerShell.'
Fixture 'over-maximum-body' 'frame' 'REJECT' '01034001' '-' 'Body16385 rejected from header before allocation' $manual
Fixture 'video-conservative' 'video' 'ACCEPT' '080210011800202028e501' '1280:720:0:32:229:60:UNSPECIFIED' 'Active1280x688 default capability' $manual
Fixture 'video-fullscreen' 'video' 'ACCEPT' '08031002180020e80228e501' '1920:1080:0:360:229:30:UNSPECIFIED' 'Opt-in active1920x720; placement not encoded/inferred' $manual
Fixture 'touchpad' 'input' 'ACCEPT' '08ad0a10d0051801203c28283001' '1325:720:60:40:true:true' 'Input independent of video' $manual
Fixture 'capture-open' 'open' 'ACCEPT' '08001001' '0:1' 'Public capture seq4 with BE16 type7 removed' 'Public-reference-derived: OAA61eab61 OEM VW capture seq4; plaintext only, no outer frame.'
Fixture 'ping-with-unknowns' 'proto' 'ACCEPT' '0896011203010203810101020304050607088d0101020304' 'field1=150; unknown wire2/1/5 retained byte-for-byte' 'Unknown field retention, no invented semantics' $manual
$cases|ConvertTo-Json -Depth 5|Set-Content "$output/manifest.json"
$lines=@('# id`t kind`t verdict`t expected`t sha256 (literal tabs below)')
$lines=@($cases|ForEach-Object { @($_.id,$_.kind,$_.verdict,$_.expectedDecodedRepresentation,$_.SHA256)-join "`t" })
[IO.File]::WriteAllLines("$output/cases.tsv",$lines,[Text.UTF8Encoding]::new($false))
Write-Output "Generated $($cases.Count) immutable v1 golden fixtures: $output"
