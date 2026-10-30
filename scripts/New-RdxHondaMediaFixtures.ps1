$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$out=Join-Path $root 'analysis/parallel-aa-receiver/clean-receiver/test-fixtures/honda-media-v1'
if(Test-Path "$out/manifest.json"){throw 'Versioned fixture set already exists'}
New-Item -ItemType Directory $out -Force|Out-Null
# Literal manually authored wire vectors: no production codec or writer imported.
$rows=@(
 @('setup-h264','0103000480000803','PHONE_TO_HU','codec=3 H264 baseline','VIDEO_SERVICE_AVAILABLE','MEDIA_SETUP_RECEIVED'),
 @('setup-missing','010300028000','PHONE_TO_HU','missing required codec','VIDEO_SERVICE_AVAILABLE','ERROR'),
 @('setup-wrongwire','0103000580000a0103','PHONE_TO_HU','codec wrong wire type','VIDEO_SERVICE_AVAILABLE','ERROR'),
 @('setup-unknown','0103000480000863','PHONE_TO_HU','unsupported codec99 retained','VIDEO_SERVICE_AVAILABLE','VIDEO_SERVICE_AVAILABLE'),
 @('setup-duplicate','01030006800008010803','PHONE_TO_HU','protobuf last singular codec wins; raw retained','VIDEO_SERVICE_AVAILABLE','MEDIA_SETUP_RECEIVED'),
 @('setup-unknownfield','0103000780000803980607','PHONE_TO_HU','codec3 plus unknown field99=7','VIDEO_SERVICE_AVAILABLE','MEDIA_SETUP_RECEIVED'),
 @('config-wait','010300088003080110101800','HU_TO_PHONE','WAIT1 window16 index0','MEDIA_SETUP_RECEIVED','MEDIA_CONFIG_WAIT_ADVERTISED'),
 @('config-ready-one','010300088003080210101800','HU_TO_PHONE','READY2 window16 index0','MEDIA_SETUP_RECEIVED','MEDIA_CONFIG_ADVERTISED'),
 @('config-ready-two','0103000a80030802101018001801','HU_TO_PHONE','READY2 window16 indices0,1','MEDIA_SETUP_RECEIVED','MEDIA_CONFIG_ADVERTISED'),
 @('config-zero','010300088003080010101800','HU_TO_PHONE','status0 unsupported, not control success','MEDIA_SETUP_RECEIVED','UNCHANGED_REJECTED'),
 @('config-unknown','010300088003080910101800','HU_TO_PHONE','status9 retained, unsupported','MEDIA_SETUP_RECEIVED','UNCHANGED_REJECTED'),
 @('config-no-window','01030006800308021800','HU_TO_PHONE','optional max-unacked absent','MEDIA_SETUP_RECEIVED','MEDIA_CONFIG_ADVERTISED'),
 @('config-empty','01030006800308021010','HU_TO_PHONE','empty allowed list retained; no selection permitted','MEDIA_SETUP_RECEIVED','MEDIA_CONFIG_ADVERTISED'),
 @('start-one','01030006800108011000','PHONE_TO_HU','session1 index0','MEDIA_CONFIG_ADVERTISED','MEDIA_CONFIGURATION_SELECTED'),
 @('start-bad','01030006800108011003','PHONE_TO_HU','session1 index3 not advertised','MEDIA_CONFIG_ADVERTISED','UNCHANGED_REJECTED'),
 @('ack-one','01030006800408011001','HU_TO_PHONE','session1 count1 accounting only','MEDIA_CONFIGURATION_SELECTED','MEDIA_CONFIGURATION_SELECTED'),
 @('focus-projected','01030006800808011001','HU_TO_PHONE','focus projected1 unsolicited true','MEDIA_CONFIG_ADVERTISED','MEDIA_CONFIG_ADVERTISED'),
 @('config-unknownfield','0103000b8003080210101800980607','HU_TO_PHONE','READY plus unknown field99=7','MEDIA_SETUP_RECEIVED','MEDIA_CONFIG_ADVERTISED'),
 @('start-unknownfield','01030009800108011000980607','PHONE_TO_HU','Start unknown field99 retained','MEDIA_CONFIG_ADVERTISED','MEDIA_CONFIGURATION_SELECTED'),
 @('ack-unknownfield','01030009800408011001980607','HU_TO_PHONE','ACK unknown field99 retained','MEDIA_CONFIGURATION_SELECTED','MEDIA_CONFIGURATION_SELECTED')
)
$manifest=@(foreach($r in $rows){
 $b=[Convert]::FromHexString($r[1]);if($b.Length -ne 4+256*$b[2]+$b[3]){throw "Literal header mismatch: $($r[0])"}
 [IO.File]::WriteAllBytes("$out/$($r[0]).bin",$b)
 $m=[ordered]@{id=$r[0];rawHex=$r[1];direction=$r[2];channel=1;decoded=$r[3];stateBefore=$r[4];stateAfter=$r[5];confidence='CONFIRMED layout; state names IMPLEMENTATION STRUCTURE';provenance='Independently handwritten literals from Honda target evidence; no production encoder used';evidence='MEDIA-8000-8003-EVIDENCE-REVIEW.md; Protos.Setup/Config/Start/Ack/VideoFocusNotification; native routeMessage/sendConfig';unknownFields='Original supported-wire bytes retained including order/nonminimal encoding; unsupported enums never imply READY';sha256=(Get-FileHash "$out/$($r[0]).bin").Hash}
 $m|ConvertTo-Json|Set-Content "$out/$($r[0]).json";$m
})
$manifest|ConvertTo-Json -Depth 5|Set-Content "$out/manifest.json"
Write-Output "Created $($manifest.Count) independent Honda media fixtures"
