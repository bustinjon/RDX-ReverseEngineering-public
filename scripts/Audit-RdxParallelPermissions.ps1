$ErrorActionPreference='Stop'
$out='./analysis/parallel-aa-receiver/evidence'
[xml]$manifest=Get-Content './decompiled/AndroidAuto-current/resources/AndroidManifest.xml' -Raw
$names=@($manifest.manifest.'uses-permission'|ForEach-Object {$_.GetAttribute('name','http://schemas.android.com/apk/res/android')}|Sort-Object -Unique)
$dump=Get-Content "$out/device/permissions.stdout.txt" -Raw
if($dump-notmatch'Permission \[android.permission.INTERNET\]'){throw 'Expected current permission definitions missing'}
$rows=@(foreach($name in $names){
    $match=[regex]::Match($dump,'(?ms)^  Permission \['+[regex]::Escape($name)+'\].*?(?=^  Permission \[|\z)')
    $definition=$match.Value
    [pscustomobject]@{permission=$name;definitionFound=$match.Success;sourcePackage=[regex]::Match($definition,'sourcePackage=([^\r\n]+)').Groups[1].Value;protection=[regex]::Match($definition,'\bprot=([^\r\n]+)').Groups[1].Value;source='Current D.1.6.4 read-only dumpsys package permissions; definitions are not a custom-app grant test'}
})
$rows|ConvertTo-Json -Depth 4|Set-Content "$out/stock-manifest-permissions.json"
$rows|Select-Object permission,protection|Format-Table -AutoSize
