$ErrorActionPreference='Stop'
Add-Type -Path './scripts/RdxElf.cs'
$output='./analysis/deployment-evidence'
[IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($output)) | Out-Null
$nativeNames=@('libsmm_release.so','libsmm_debug.so','libdevelupdate.so','libswupdate.so','libtransport.so')
foreach($name in $nativeNames){
    $file="./adb/RDX-Audit/full-system/lib/$name"
    $elf=[RdxOffline.Elf32]::new([IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $file)))
    $elf.Sections | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath "$output/$name.sections.json"
    $elf.Symbols | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath "$output/$name.symbols.json"
    $strings=$elf.Strings(5)
    $strings | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath "$output/$name.strings.json"
    $hits=@($strings | Where-Object {$_.Value -match '(?i)verify|signature|certificate|root.?ca|public.?key|sw_update|authent|delta|delivery|rollback|revert|\.pem|\.crt|\.bks|\.dp\b|/data/|/persistdata/|BEGIN .*KEY|BEGIN CERTIFICATE|execCommand|copyFiles'})
    $hits | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath "$output/$name.security-strings.json"
    [pscustomobject]@{file=$name;sha256=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash;symbols=$elf.Symbols.Count;functions=@($elf.Symbols | Where-Object {($_.Info-band15)-eq2 -and $_.Section-ne0}).Count;securityStrings=$hits.Count}
}
# Static source queries preserve all hits instead of truncating to the console.
$queries=[ordered]@{
 'dynamic-loaders'='DexClassLoader|PathClassLoader|DexFile\.loadDex|addDexPath|dexElements|BaseDexClassLoader|URLClassLoader|createPackageContext\('
 'code-paths'='(/data/|/persistdata/).*(\.jar|\.dex|\.apk|\.so)|System\.load\(|System\.loadLibrary\('
 'test-harnesses'='(?i)instrumentation|validation|engineering|test.?harness|debug.?loader|plugin|plug-in'
 'persist-staging'='persistdata/app|persistdata_app|sw_update_root|removeOldApk|scanPackageDirtyLI|Signature mismatch for shared user'
}
foreach($query in $queries.GetEnumerator()){
    & rg -n --glob '*.java' --glob '*.xml' --glob '*.txt' --glob '*.conf' -- $query.Value ./decompiled ./adb/RDX-Audit/logs > "$output/$($query.Key).txt"
    if($LASTEXITCODE-gt1){throw "rg failed: $($query.Key)"}
}
'Saved ELF symbol/string inventories and complete static-source query evidence. No device or network commands.'
