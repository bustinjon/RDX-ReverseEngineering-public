$ErrorActionPreference='Stop'
$out='./analysis/recovery-root-evidence'
Add-Type -Path './scripts/RdxElf.cs'
$wanted='(?i)root|setuid|setgid|capabil|capget|capset|ptrace|run-as|setenforce|permissive|selinux|remount|mount|namespace|chroot|pivot_root|verity|fastboot|recovery|bootloader|execve|fork|popen|system|chmod|chown|unshare|setns|preload|JNI_CreateJavaVM|dlopen|mprotect|OpenDex|OpenZip|Checksum|DexOpt|OatFile|GetOat|GetDex'
$rows=foreach($name in @('libart.so','libart-compiler.so','libc.so','libcutils.so','libselinux.so','libswupdate.so','libdevelupdate.so')){
    $path="./adb/RDX-Audit/full-system/lib/$name"
    if(-not(Test-Path -LiteralPath $path)){$path="./adb/RDX-Audit/pulls/$name"}
    if(-not(Test-Path -LiteralPath $path)){[pscustomobject]@{name=$name;available=$false};continue}
    try{
        $elf=[RdxOffline.Elf32]::new([IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $path)))
        $symbols=@($elf.Symbols|Where-Object {$_.Name-match$wanted})
        $strings=@($elf.Strings(5)|Where-Object {$_.Value-match'(?i)LD_PRELOAD|CLASSPATH|debuggable|ro.secure|service.adb.root|root|setuid|setenforce|verity|by-name|recovery|sys.boot|system[12]|boot[12]|environment[12]|manifest|oat.*checksum|checksum.*oat|cap_sys'})
        $symbols|ConvertTo-Json -Depth 4|Set-Content "$out/$name.symbols.json"
        $strings|ConvertTo-Json -Depth 4|Set-Content "$out/$name.strings.json"
        [pscustomobject]@{name=$name;available=$true;path=$path;bytes=(Get-Item -LiteralPath $path).Length;sha256=(Get-FileHash -LiteralPath $path).Hash;matchedSymbols=$symbols.Count;matchedStrings=$strings.Count;status='ELF32 ARM parsed; symbols/strings only, not vulnerability or caller reachability proof'}
    }catch{[pscustomobject]@{name=$name;available=$true;path=$path;status=$_.Exception.Message}}
}
$rows|ConvertTo-Json -Depth 4|Set-Content "$out/native-summary.json"
$rows|Select-Object name,available,matchedSymbols,matchedStrings,status|Format-Table -Wrap
