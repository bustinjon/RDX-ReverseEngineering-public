$ErrorActionPreference='Stop'
$out='./analysis/parallel-aa-receiver/evidence/device'
[IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($out))|Out-Null
$adb=(Resolve-Path './adb/adb.exe').Path
$deviceOutput=& $adb devices 2>&1
$deviceOutput|Set-Content "$out/devices.txt"
if($LASTEXITCODE-ne0){throw 'Read-only connectivity check failed'}
if(($deviceOutput-join"`n")-notmatch'(?m)^00000000\s+device\s*$'){Write-Output 'Target not connected; no further device observations made.';return}
$serial='00000000'
$observations=@(
    @{name='firmware';arguments=@('shell','getprop','ro.build.fwversion')},
    @{name='usb';arguments=@('shell','dumpsys','usb')},
    @{name='processes';arguments=@('shell','ps')},
    @{name='unix-sockets';arguments=@('shell','cat','/proc/net/unix')},
    @{name='socket-modes';arguments=@('shell','ls','-ldZ','/data/misc/gal','/data/misc/gal/socket')},
    @{name='receiver-library-paths';arguments=@('shell','ls','-lZ','/system/app/AndroidAuto/lib/arm/libautoreceiver_jni.so','/system/lib/libautoreceiver_jni.so')},
    @{name='stock-package';arguments=@('shell','dumpsys','package','com.honda.androidauto.projection.sink')}
)
$records=@(foreach($observation in $observations){
    $args=@('-s',$serial)+$observation.arguments
    & $adb @args > "$out/$($observation.name).stdout.txt" 2> "$out/$($observation.name).stderr.txt"
    $code=$LASTEXITCODE
    [pscustomobject]@{utc=[DateTime]::UtcNow.ToString('o');arguments=$args;exitCode=$code;name=$observation.name}
    if($observation.name-eq'firmware' -and ($code-ne0 -or (Get-Content "$out/firmware.stdout.txt" -Raw).Trim()-ne'D.1.6.4')){throw 'Unexpected target firmware; collection stopped'}
})
$nativeSource='/system/app/AndroidAuto/lib/arm/libautoreceiver_jni.so'
$nativeDestination="$out/libautoreceiver_jni.so"
& $adb -s $serial pull $nativeSource $nativeDestination > "$out/native-pull.stdout.txt" 2> "$out/native-pull.stderr.txt"
$pullExit=$LASTEXITCODE
$records+=[pscustomobject]@{utc=[DateTime]::UtcNow.ToString('o');arguments=@('-s',$serial,'pull',$nativeSource,$nativeDestination);exitCode=$pullExit;name='native-pull'}
$records|ConvertTo-Json -Depth 4|Set-Content "$out/commands.json"
if($pullExit-eq0){[pscustomobject]@{devicePath=$nativeSource;bytes=(Get-Item -LiteralPath $nativeDestination).Length;sha256=(Get-FileHash -LiteralPath $nativeDestination).Hash;utc=[DateTime]::UtcNow.ToString('o')}|ConvertTo-Json|Set-Content "$out/native-provenance.json"}
$records|Select-Object name,exitCode|Format-Table
