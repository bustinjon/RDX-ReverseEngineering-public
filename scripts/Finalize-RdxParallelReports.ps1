$ErrorActionPreference='Stop'
$project='./analysis/parallel-aa-receiver'
$matrix='./analysis/AA-PRIVILEGE-DEPENDENCY-MATRIX.md'
$body=Get-Content -LiteralPath $matrix -Raw
$body=$body.Replace('signature|system','signature&#124;system')
# Keep evidence and substitute distinct columns as requested.
if($body.Contains('| EVIDENCE / POSSIBLE SUBSTITUTE |')){
    $lines=$body -split "`r?`n"
    $inTable=$false;$done=$false
    for($i=0;$i-lt$lines.Count;$i++){
        if($lines[$i].StartsWith('| DEPENDENCY |')){$lines[$i]=$lines[$i].Replace('| EVIDENCE / POSSIBLE SUBSTITUTE |','| EVIDENCE | POSSIBLE SUBSTITUTE |');$inTable=$true;continue}
        if($inTable -and $lines[$i].StartsWith('| ---')){$lines[$i]+=' --- |';continue}
        if($inTable -and $lines[$i].StartsWith('| ')){
            $cells=@($lines[$i].Trim('|').Split('|')|ForEach-Object {$_.Trim()})
            if($cells.Count-ne9){throw "Unexpected matrix cell count: $($cells.Count)"}
            $last=$cells[8];$split=$last.IndexOf('. ')
            if($split-ge0){$evidence=$last.Substring(0,$split+1);$substitute=$last.Substring($split+2)}else{$evidence=$last;$substitute='Omit or use the scoped public-SDK design described in this row.'}
            $lines[$i]='| '+(@($cells[0..7])+@($evidence,$substitute)-join' | ')+' |'
        }elseif($inTable){$inTable=$false;$done=$true}
    }
    $body=$lines -join "`n"
}
$permissions=@(Get-Content "$project/evidence/stock-manifest-permissions.json" -Raw|ConvertFrom-Json)
$permissionTable=[Collections.Generic.List[string]]::new()
$permissionTable.Add('| Original permission | Current protection | Ordinary self-signed app | Minimum-video substitute |')
$permissionTable.Add('| --- | --- | --- | --- |')
foreach($permission in $permissions){
    $protection=if($permission.definitionFound){$permission.protection.Replace('|','&#124;')}else{'Definition not found'}
    $access=if(-not$permission.definitionFound){'Unproved; do not assume grant'}elseif($permission.protection-match'signature'){'Not by normal declaration; development exception is not used'}elseif($permission.protection-eq'dangerous'){'Declared install-time grant model on target22, subject to policy'}else{'Normally declarable; API/service checks still apply'}
    $substitute=switch($permission.permission){
        'android.permission.MANAGE_USB' {'Per-device user grant through public UsbManager; no direct grant API'}
        'android.permission.READ_FRAME_BUFFER' {'Render to own Surface; no framebuffer capture'}
        'android.permission.DUMP' {'Collect external read-only ADB logs later, not app dumpsys authority'}
        'android.permission.READ_LOGS' {'App writes own tag; later authorized ADB reads logs'}
        'android.permission.MEDIA_CONTENT_CONTROL' {'Omit Honda source control and media browsing'}
        'android.permission.RECEIVE_BOOT_COMPLETED' {'Manual launch only'}
        'android.permission.WRITE_EXTERNAL_STORAGE' {'Own private assets/data; no external logging needed'}
        'android.permission.INTERNET' {'USB-only native protocol path; no network sockets in app source'}
        default {'Omit from first video/core diagnostics; add only for a specific later feature'}
    }
    $permissionTable.Add("| $($permission.permission) | $protection | $access | $substitute |")
}
$begin='<!-- CURRENT-PERMISSION-TABLE -->';$end='<!-- END-CURRENT-PERMISSION-TABLE -->'
$insert=$begin+"`n`n"+($permissionTable-join"`n")+"`n`n"+$end
if($body.Contains($end)){$body=[regex]::Replace($body,'(?s)'+[regex]::Escape($begin)+'.*?'+[regex]::Escape($end),[Text.RegularExpressions.MatchEvaluator]{param($m)$insert})}else{$body=$body.Replace($begin,$insert)}
Set-Content -LiteralPath $matrix -Value $body
$report=Get-Content "$project/build/build-report.json" -Raw|ConvertFrom-Json
$hashes=@(foreach($path in @("$project/AndroidManifest.xml","$project/build/rdx-parallel-aa-0.1.0-development.apk","$project/build/dex/classes.dex","$project/libs/armeabi-v7a/libautoreceiver_jni.so")+@(Get-ChildItem "$project/src" -Recurse -Filter '*.java'|ForEach-Object {$_.FullName})){
    [pscustomobject]@{path=$path;bytes=(Get-Item -LiteralPath $path).Length;sha256=(Get-FileHash -LiteralPath $path).Hash}
})
[ordered]@{scope='New prototype public source/manifest/build/native integrity; no private key contents';developmentSignerSHA256=$report.developmentSignerSHA256;files=$hashes}|ConvertTo-Json -Depth 5|Set-Content "$project/hashes.json"
Write-Output "Permission rows: $($permissions.Count); prototype integrity records: $($hashes.Count)"
