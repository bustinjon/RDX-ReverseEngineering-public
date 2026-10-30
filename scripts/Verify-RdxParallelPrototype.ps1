$ErrorActionPreference='Stop'
$project='./analysis/parallel-aa-receiver'
Add-Type -Path './scripts/RdxDex.cs'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$original=[IO.Compression.ZipFile]::OpenRead((Resolve-Path './apks/AndroidAuto-current-2026-10-22.apk'))
try{$stream=$original.GetEntry('classes.dex').Open();$memory=[IO.MemoryStream]::new();try{$stream.CopyTo($memory);$stock=[RdxOffline.Dex]::new($memory.ToArray())}finally{$stream.Dispose();$memory.Dispose()}}finally{$original.Dispose()}
$custom=[RdxOffline.Dex]::new([IO.File]::ReadAllBytes((Resolve-Path "$project/build/dex/classes.dex")))
$defs=@($custom.DefinedClasses())
if(@($defs|Where-Object {$_-like'Lcom/honda/*'}).Count){throw 'Honda app/component classes unexpectedly included'}
$apiClasses=@('Lcom/google/android/projection/protocol/GalReceiver;','Lcom/google/android/projection/protocol/VideoSink;')
$nativeMethods=@($custom.Methods|Where-Object {$_.Class-in$apiClasses -and $_.Name-like'native*'})
$abi=@(foreach($method in $nativeMethods){
    $match=@($stock.Methods|Where-Object {$_.Class-eq$method.Class -and $_.Name-eq$method.Name -and $_.Prototype-eq$method.Prototype})
    if($match.Count-ne1){throw "JNI ABI mismatch: $($method.Class)$($method.Name)$($method.Prototype)"}
    [pscustomobject]@{class=$method.Class;method=$method.Name;prototype=$method.Prototype;matchesStock=$true}
})
$callbackNames=@('audioFocusRequestCallback','batteryStatusNotificationCallback','bugreportRequestCallback','byeByeRequestCallback','byeByeResponseCallback','carConnectedDevicesRequestCallback','navigationFocusCallback','pingResponseCallback','serviceDiscoveryRequestCallback','unrecoverableErrorCallback','userSwitchRequestCallback','voiceSessionNotificationCallback','dataAvailableCallback','codecConfigCallback','setupCallback','playbackStartCallback','playbackStopCallback','sourceVideoConfigCallback','videoFocusCallback')
$callbacks=@(foreach($method in $stock.Methods|Where-Object {$_.Class-in$apiClasses -and $_.Name-in$callbackNames -and $_.CodeOffset-gt0}){
    $match=@($custom.Methods|Where-Object {$_.Class-eq$method.Class -and $_.Name-eq$method.Name -and $_.Prototype-eq$method.Prototype -and $_.CodeOffset-gt0})
    if($match.Count-ne1){throw "Callback ABI missing: $($method.Name)$($method.Prototype)"}
    [pscustomobject]@{class=$method.Class;method=$method.Name;prototype=$method.Prototype;matchesStock=$true}
})
function Get-Fields($dex){$count=[BitConverter]::ToUInt32($dex.Bytes,80);for($i=0;$i-lt$count;$i++){$dex.FieldName($i)}}
$stockFields=@(Get-Fields $stock);$customFields=@(Get-Fields $custom)
$requiredFields=@($stockFields|Where-Object {$_-match'^Lcom/google/android/projection/protocol/GalReceiver\$(CarInfo|ConnectedDevice);->|^Lcom/google/android/projection/protocol/(GalReceiver;->mNativeGalReceiver|VideoSink;->mNativeVideoSink):'})
foreach($field in $requiredFields){if($field-notin$customFields){throw "Native-relevant field missing: $field"}}
foreach($name in 'getBuffer','returnBuffer'){
    $method=$stock.Methods|Where-Object {$_.Class-eq'Lcom/google/android/projection/common/BufferPool;' -and $_.Name-eq$name}|Select-Object -First 1
    if(-not($custom.Methods|Where-Object {$_.Class-eq$method.Class -and $_.Name-eq$name -and $_.Prototype-eq$method.Prototype})){throw 'Buffer pool ABI mismatch'}
}
[xml]$manifest=Get-Content "$project/AndroidManifest.xml" -Raw
if($manifest.manifest.package-ne'com.rdx.fullscreen.projection' -or $manifest.manifest.HasAttribute('sharedUserId','http://schemas.android.com/apk/res/android')){throw 'Package/shared UID mismatch'}
if(@($manifest.SelectNodes('/manifest/uses-permission|/manifest/application/receiver|/manifest/application/service|/manifest/application/provider')).Count){throw 'Unexpected permission/autostart/service/provider in prototype'}
$report=Get-Content "$project/build/build-report.json" -Raw|ConvertFrom-Json
$apk=Join-Path $project $report.output
if((Get-FileHash -LiteralPath $apk).Hash-ne$report.outputSHA256){throw 'APK build report hash mismatch'}
$zip=[IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $apk))
try{
    $native=$zip.GetEntry('lib/armeabi-v7a/libautoreceiver_jni.so')
    $s=$native.Open();$sha=[Security.Cryptography.SHA256]::Create()
    try{$nativeHash=[Convert]::ToHexString($sha.ComputeHash($s))}finally{$s.Dispose();$sha.Dispose()}
    if($nativeHash-ne$report.nativeSHA256){throw 'Packaged native library changed'}
    $dexEntry=$zip.GetEntry('classes.dex');$s=$dexEntry.Open();$sha=[Security.Cryptography.SHA256]::Create()
    try{$packagedDexHash=[Convert]::ToHexString($sha.ComputeHash($s))}finally{$s.Dispose();$sha.Dispose()}
    if($packagedDexHash-ne$report.dexSHA256 -or $packagedDexHash-ne[RdxOffline.Dex]::HexHash($custom.Bytes)){throw 'Packaged DEX differs from verified build output'}
    $entries=@($zip.Entries.FullName)
}finally{$zip.Dispose()}
$baseline=Get-Content './analysis/current-update-stack/final-validation.json' -Raw|ConvertFrom-Json
foreach($item in @($baseline.preservedNotes)+@($baseline.preservedAAArtifacts)){
    if((Get-FileHash -LiteralPath $item.path).Hash-ne$item.sha256){throw 'Original source note or AA artifact changed'}
}
$commands=@(Get-Content "$project/evidence/device/commands.json" -Raw|ConvertFrom-Json)
foreach($record in $commands){
    $a=@($record.arguments)
    if($a[0]-ne'-s' -or $a[1]-ne'00000000' -or ($a[2]-ne'pull' -and -not($a[2]-eq'shell' -and $a[3]-in'getprop','dumpsys','ps','cat','ls'))){throw 'Unexpected vehicle command in new observation log'}
}
$result=[ordered]@{utc=[DateTime]::UtcNow.ToString('o');status='HOST STATIC VALIDATION ONLY; no APK installation/launch, ARM execution or phone negotiation';definedClasses=$defs.Count;dexVersion=[Text.Encoding]::ASCII.GetString($custom.Bytes,0,8);JNIEntrypoints=$abi;callbacks=$callbacks;requiredFields=$requiredFields;bufferPoolABI=$true;manifestHasNoSharedUIDOrPermissionsOrAutoComponents=$true;nativeBytesUnchanged=$true;packagedDexMatchesVerifiedOutput=$true;APKEntries=$entries;APK_SHA256=$report.outputSHA256;sourceNotesAndFactoryAndCandidatesPreserved=$true;loggedReadOnlyObservations=$commands.Count;limitations='Descriptor/name/field checks do not prove dynamic JNI success, callback threading, all native ABI assumptions, MediaCodec playback or USB permission/ownership. No vehicle runtime milestone demonstrated.'}
$result|ConvertTo-Json -Depth 7|Set-Content "$project/evidence/prototype-static-validation.json"
[pscustomobject]@{classes=$defs.Count;nativeSignaturesChecked=$abi.Count;callbackSignaturesChecked=$callbacks.Count;fieldsChecked=$requiredFields.Count;nativeUnchanged=$true;readOnlyObservations=$commands.Count;APK_SHA256=$report.outputSHA256}|ConvertTo-Json
