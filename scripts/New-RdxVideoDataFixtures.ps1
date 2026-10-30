$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$out=Join-Path $root 'analysis/parallel-aa-receiver/clean-receiver/test-fixtures/video-data-v1'
if(Test-Path "$out/manifest.json"){throw 'Existing fixture set is immutable'}
New-Item -ItemType Directory $out -Force|Out-Null
$manifest=[Collections.Generic.List[object]]::new()
function Save-Fixture($id,[byte[]]$bytes,$meaning,$disposition,$origin){
 [IO.File]::WriteAllBytes("$out/$id.bin",$bytes)
 $m=[ordered]@{id=$id;rawHex=[Convert]::ToHexString($bytes).ToLowerInvariant();meaning=$meaning;expectedDisposition=$disposition;direction='PHONE_TO_HU video unless ACK noted';provenance=$origin;confidence='CONFIRMED envelope; synthetic NAL/AU binding and local safety dispositions';sha256=(Get-FileHash "$out/$id.bin").Hash}
 $m|ConvertTo-Json|Set-Content "$out/$id.json";$manifest.Add($m)
}
foreach($name in @('1280x720-30','1280x688-60','1920x720-30','1920x720-60','1920x1080-30','1920x1080-60')){
 $path=Join-Path $root "analysis/parallel-aa-receiver/decoder-test/clips/grid-$name.mp4.first.h264"
 $b=[IO.File]::ReadAllBytes($path);$starts=[Collections.Generic.List[object]]::new()
 for($i=0;$i-lt$b.Length-3;$i++){if($b[$i]-eq0-and$b[$i+1]-eq0){$n=if($b[$i+2]-eq1){3}elseif($b[$i+2]-eq0-and$b[$i+3]-eq1){4}else{0};if($n){$starts.Add(@{pos=$i;data=$i+$n});$i+=$n-1}}}
 $csd=[IO.MemoryStream]::new();try{for($i=0;$i-lt$starts.Count;$i++){$a=$starts[$i].data;$end=if($i+1-lt$starts.Count){$starts[$i+1].pos}else{$b.Length};$type=$b[$a]-band31;if($type-eq7-or$type-eq8){$csd.Write([byte[]]@(0,0,0,1),0,4);$csd.Write($b,$a,$end-$a)}};Save-Fixture "config-$name" $csd.ToArray() 'AnnexB SPS/PPS from preserved independent ffmpeg extraction' 'CONFIGURED_ABSTRACT under explicit HOST policy' "Saved first.h264; source SHA256=$((Get-FileHash $path).Hash)"}finally{$csd.Dispose()}
}
$rows=@(
 @('data-basic','0000000000000000000100000001658884','timestamp1 plus synthetic minimal VCL NAL; NOT decoded','accepted only with valid config/selection'),
 @('timestamp-max','0000ffffffffffffffff00000001658884','uint64 bits max','raw bits retained; units UNKNOWN'),
 @('timestamp-truncated','0000000000000000','only6 timestamp bytes','MALFORMED envelope'),
 @('empty-data','00000000000000000000','timestamp0 empty opaque payload','envelope valid; synthetic AU policy rejects'),
 @('empty-config','0001','empty config opaque','envelope valid; AnnexB policy rejects'),
 @('sps-truncated','000167','truncated SPS','AnnexB/config rejects'),
 @('pps-truncated','00010000000168','truncated PPS','config rejects'),
 @('nal-length-overflow','ffffffff65','AVCC length overflow','length-prefixed parser rejects'),
 @('empty-nal','00000001','empty AnnexB NAL','AnnexB rejects'),
 @('forbidden-nal','00000001e5','forbidden_zero_bit set','AnnexB rejects'),
 @('unknown-id','12340102','unknown video ID','unsupported local whole-stream invalidation'),
 @('stop','8002','Stop empty-base','abstract stop after selection'),
 @('invalid-index','800108011007','Start index7 not advertised','selection rejected'),
 @('impossible-ack','800408011020','count32 with debt1','count greater than debt rejected'),
 @('duplicate-config','0001000000016742','new config after config accepted','RECONFIGURATION_UNKNOWN before parse'),
 @('before-setup','0000000000000000000100000001658884','data before typed Start','REJECT_NOT_SELECTED'),
 @('after-stop','0000000000000000000100000001658884','data after terminal Stop','no queue/no revival'),
 @('sei-aud','0000000109f000000001060580','AUD/SEI classification','NAL types9 and6; not an AU')
)
foreach($r in $rows){Save-Fixture $r[0] ([Convert]::FromHexString($r[1])) $r[2] $r[3] 'Independently handwritten; no production parser/writer imported'}
$manifest|ConvertTo-Json -Depth 5|Set-Content "$out/manifest.json"
Write-Output "Created $($manifest.Count) video data fixtures"
