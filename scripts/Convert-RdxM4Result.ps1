param([Parameter(Mandatory)][string]$InputFile,[Parameter(Mandatory)][string]$OutputPrefix)
$ErrorActionPreference='Stop'
$samples=[Collections.Generic.List[object]]::new();$sample=$null;$device=$null;$interface=$null;$end=$null;$errors=@();$resultFile=$null
foreach($line in Get-Content -LiteralPath $InputFile){
 if($line-notmatch'^wallMs=(\d+) elapsedMs=(\d+) (.*)$'){continue}
 $wall=[long]$Matches[1];$elapsed=[long]$Matches[2];$message=$Matches[3]
 if($message-match'^RESULT_FILE=(\S+)'){$resultFile=$Matches[1]}
 if($message-match'^SNAPSHOT sample=(\d+).*uid=(\d+) pid=(\d+) api=(\d+)'){
  $sample=[ordered]@{sample=[int]$Matches[1];wallMs=$wall;vehicleUtc=[DateTimeOffset]::FromUnixTimeMilliseconds($wall).ToString('o');elapsedMs=$elapsed;uid=[int]$Matches[2];pid=[int]$Matches[3];api=[int]$Matches[4];deviceCount=-1;devices=[Collections.Generic.List[object]]::new()};$samples.Add($sample);$device=$null;$interface=$null
 }elseif($message-match'^deviceCount=(-?\d+)'){$sample.deviceCount=[int]$Matches[1]}
 elseif($message-match'^device=(\S+) vendorId=(\d+) productId=(\d+) class=(\d+) subclass=(\d+) protocol=(\d+) configurationCount=(\d+) interfaceCount=(\d+) hasPermission=(true|false)'){
  $device=[ordered]@{wallMs=$wall;elapsedMs=$elapsed;path=$Matches[1];VID=[int]$Matches[2];PID=[int]$Matches[3];vidPid=('{0:X4}:{1:X4}'-f[int]$Matches[2],[int]$Matches[3]);class=[int]$Matches[4];subclass=[int]$Matches[5];protocol=[int]$Matches[6];configurationCount=[int]$Matches[7];interfaceCount=[int]$Matches[8];hasPermission=($Matches[9]-eq'true');interfaces=[Collections.Generic.List[object]]::new()};$sample.devices.Add($device);$interface=$null
 }elseif($message-match'^interface=(\d+) alternateSetting=(\d+) class=(\d+) subclass=(\d+) protocol=(\d+) endpointCount=(\d+)'){
  $interface=[ordered]@{id=[int]$Matches[1];alternateSetting=[int]$Matches[2];class=[int]$Matches[3];subclass=[int]$Matches[4];protocol=[int]$Matches[5];endpointCount=[int]$Matches[6];endpoints=[Collections.Generic.List[object]]::new()};$device.interfaces.Add($interface)
 }elseif($message-match'^endpoint=(\d+) direction=(\d+) type=(\d+) maxPacketSize=(\d+) interval=(\d+)'){
  $interface.endpoints.Add([ordered]@{address=[int]$Matches[1];direction=[int]$Matches[2];type=[int]$Matches[3];maxPacketSize=[int]$Matches[4];interval=[int]$Matches[5]})
 }elseif($message.StartsWith('END;')){$end=[ordered]@{wallMs=$wall;elapsedMs=$elapsed;message=$message}}
 elseif($message-match'ERROR|interrupted'){$errors+= $line}
}
$rows=@(foreach($s in $samples){foreach($d in $s.devices){[pscustomobject]@{sample=$s.sample;vehicleUtc=$s.vehicleUtc;elapsedMs=$d.elapsedMs;path=$d.path;VID=$d.VID;PID=$d.PID;vidPid=$d.vidPid;class=$d.class;subclass=$d.subclass;protocol=$d.protocol;configurationCount=$d.configurationCount;interfaceCount=$d.interfaceCount;hasPermission=$d.hasPermission}}})
$rows|Export-Csv -LiteralPath ($OutputPrefix+'-devices.csv') -NoTypeInformation
$summary=@(foreach($g in $rows|Group-Object path,vidPid){$first=$g.Group[0];$last=$g.Group[-1];[ordered]@{path=$first.path;vidPid=$first.vidPid;VID=$first.VID;PID=$first.PID;firstSample=$first.sample;lastSample=$last.sample;firstUtc=$first.vehicleUtc;lastUtc=$last.vehicleUtc;hasPermission=@($g.Group.hasPermission|Sort-Object -Unique);interfaceCounts=@($g.Group.interfaceCount|Sort-Object -Unique);observations=$g.Count}})
$out=[ordered]@{input=(Resolve-Path -LiteralPath $InputFile).Path;SHA256=(Get-FileHash -LiteralPath $InputFile).Hash;resultPathReported=$resultFile;sampleCount=$samples.Count;start=if($samples.Count){$samples[0]}else{$null};end=$end;errors=$errors;deviceIdentities=$summary;samples=$samples}
$out|ConvertTo-Json -Depth 14|Set-Content -LiteralPath ($OutputPrefix+'.json')
$summary|ConvertTo-Json -Depth 4
Write-Output "Samples=$($samples.Count), END=$($null-ne$end), Errors=$($errors.Count)"
