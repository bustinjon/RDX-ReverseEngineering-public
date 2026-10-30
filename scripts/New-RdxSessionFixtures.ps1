# OFFLINE independent fixture author: scalar/tag/length authoring here imports NO Java production codec.
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$out=Join-Path $root 'analysis/parallel-aa-receiver/clean-receiver/test-fixtures/session'
if(Test-Path "$out/manifest.json"){throw 'Session fixtures frozen; version a new directory instead of overwriting'}
function HexBytes([string]$Hex){return [Convert]::FromHexString(($Hex-replace'\s',''))}
function V([long]$n){$b=[Collections.Generic.List[byte]]::new();do{$v=$n-band127;$n=$n-shr7;if($n){$v=$v-bor128};$b.Add([byte]$v)}while($n);return $b.ToArray()}
function B([int]$field,[byte[]]$value){return [byte[]](@(V ($field*8+2))+@(V $value.Length)+@($value))}
function T([int]$field,[string]$text){return B $field ([Text.Encoding]::UTF8.GetBytes($text))}
function Wire([int]$ch,[int]$flags,[int]$type,[byte[]]$payload){$body=[byte[]](@([byte]($type-shr8),[byte]($type-band255))+@($payload));return [byte[]](@([byte]$ch,[byte]$flags,[byte]($body.Length-shr8),[byte]($body.Length-band255))+@($body))}
$videoA=HexBytes '08 02 10 01 18 00 20 20 28 e5 01'
$videoB=HexBytes '08 03 10 02 18 00 20 e8 02 28 e5 01'
function Advertisement([byte[]]$video,[byte[]]$extra=@()){
 $sink=[byte[]](@(HexBytes '0803')+@(B 4 $video));$service=[byte[]](@(HexBytes '0801')+@(B 3 $sink))
 $touch=HexBytes '08ad0a10d0051801203c28283001'
 $input=[byte[]](@(HexBytes '0802')+@(B 4 (B 3 $touch)))
 $all=[Collections.Generic.List[byte]]::new();$all.AddRange([byte[]](B 1 $service));$all.AddRange([byte[]](B 1 $input))
 if($extra.Length){$all.AddRange([byte[]](B 1 $extra))}
 foreach($pair in @(@(2,'RDX research'),@(3,'Offline core'),@(4,'2021'),@(5,''))){$all.AddRange([byte[]](T $pair[0] $pair[1]))}
 $all.AddRange([byte[]](HexBytes '3000'))
 foreach($pair in @(@(7,'Independent'),@(8,'Pure Java'),@(9,'offline'),@(10,'0.3-protocol'))){$all.AddRange([byte[]](T $pair[0] $pair[1]))}
 $all.AddRange([byte[]](HexBytes '5800'));return $all.ToArray()
}
$cases=@(
 @('version-request',(Wire 0 3 1 (HexBytes '00010001')),'NEW/start','VERSION_PENDING','raw base1.1; no extensions','CONFIRMED'),
 @('version-response',(Wire 0 3 2 (HexBytes '000100010000')),'VERSION_PENDING','VERSION_ESTABLISHED','base response1.1,status0','CONFIRMED'),
 @('unsupported-version',(Wire 0 3 2 (HexBytes '000200010000')),'VERSION_PENDING','ERROR','major2 rejected by local supported-profile policy','IMPLEMENTATION STRUCTURE'),
 @('malformed-version',(Wire 0 3 2 (HexBytes '0001')),'VERSION_PENDING','ERROR','truncated raw version','CONFIRMED'),
 @('discovery-request',(Wire 0 3 5 (HexBytes '220550686f6e652a0158')),'DISCOVERY_PENDING','SERVICES_ADVERTISED','phone=Phone,brand=X','CONFIRMED'),
 @('open-video',(Wire 1 7 7 (HexBytes '08001001')),'SERVICES_ADVERTISED','VIDEO_SERVICE_AVAILABLE','priority0,service1','STRONGLY INFERRED'),
 @('open-input',(Wire 2 7 7 (HexBytes '08001002')),'SERVICES_ADVERTISED','SERVICES_ADVERTISED','priority0,service2; independent service','STRONGLY INFERRED'),
 @('media-setup',(Wire 1 3 0x8000 (HexBytes '0803')),'VIDEO_SERVICE_AVAILABLE','MEDIA_SETUP_PENDING','raw field1=3; meaning UNKNOWN','UNKNOWN'),
 @('media-start',(Wire 1 3 0x8001 (HexBytes '08011000')),'MEDIA_SETUP_PENDING','MEDIA_SETUP_PENDING','session1,config0; progression UNKNOWN','UNKNOWN'),
 @('media-stop',(Wire 1 3 0x8002 @()),'MEDIA_SETUP_PENDING','MEDIA_SETUP_PENDING','empty protobuf; no guessed closure','STRONGLY INFERRED'),
 @('media-ack',(Wire 1 3 0x8004 (HexBytes '08011001')),'codec-only','codec-only','session1,count1; no automatic ACK generation','STRONGLY INFERRED'),
 @('ping-unknown',(Wire 0 3 11 (HexBytes '0801980607')),'SERVICES_ADVERTISED','SERVICES_ADVERTISED','timestamp1,unknown99=7 retained; response not blind echo','CONFIRMED'),
 @('shutdown-request',(Wire 0 3 15 (HexBytes '0801')),'SERVICES_ADVERTISED','CLOSED','reason1; inferred orderly stop policy','STRONGLY INFERRED'),
 @('shutdown-response',(Wire 0 3 16 @()),'STOPPING','CLOSED','empty response','STRONGLY INFERRED'),
 @('malformed-frame',(HexBytes '00100000'),'active','ERROR','reserved flag0x10','CONFIRMED'),
 @('partial-frame',(HexBytes '00030008'),'VERSION_PENDING','timeout ERROR','header awaiting body','IMPLEMENTATION STRUCTURE'),
 @('first-fragment',(HexBytes '00010002000000080002'),'VERSION_PENDING','timeout ERROR','FIRST,total8,body type2 only','CONFIRMED'),
 @('video-conservative',$videoA,'codec-only','codec-only','1280x688/229/60; placement UNSPECIFIED','CONFIRMED'),
 @('video-experimental',$videoB,'codec-only','codec-only','1920x720 active/229/30; placement UNSPECIFIED','CONFIRMED'),
 @('discovery-conservative',(Advertisement $videoA),'LOCAL_HU_CATALOG','SERVICES_ADVERTISED','HU video1/input2; full response PAYLOAD, not phone inbound','CONFIRMED'),
 @('discovery-experimental',(Advertisement $videoB),'LOCAL_HU_CATALOG','SERVICES_ADVERTISED','explicit opt-in only; response PAYLOAD','CONFIRMED'),
 @('discovery-unknown-service',(Advertisement $videoA (HexBytes '08634a00')),'LOCAL_HU_CATALOG','SERVICES_ADVERTISED','unknown service99 alongside video1/input2','STRONGLY INFERRED')
)
$manifest=@(foreach($case in $cases){
 $id=$case[0];$bytes=[byte[]]$case[1];[IO.File]::WriteAllBytes("$out/$id.bin",$bytes)
 $metadata=[ordered]@{id=$id;rawHex=[Convert]::ToHexString($bytes).ToLowerInvariant();decodedExpectation=$case[4];stateBefore=$case[2];stateAfter=$case[3];confidence=$case[5];provenance='Independently authored host scalar/length/header fixture; no production Java codec imported';evidence='Existing ControlMessages/field-confidence plus pinned AASDK AV schemas, OAA AV schemas, Honda VideoSink; source hashes in M7 evidence inventory';unknownNotes='Media setup field1 and setup response direction conflict; no fabricated readiness. Unrecognized supported protobuf fields retain original bytes.';sha256=(Get-FileHash "$out/$id.bin").Hash}
 $metadata|ConvertTo-Json|Set-Content "$out/$id.json";$metadata
})
$manifest|ConvertTo-Json -Depth 4|Set-Content "$out/manifest.json"
"Created $($manifest.Count) independent session fixtures"
