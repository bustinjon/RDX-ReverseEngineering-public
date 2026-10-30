$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$out=Join-Path $root 'analysis/parallel-aa-receiver/warning-evidence'
New-Item -ItemType Directory -Path $out -Force|Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
$patterns=@('non[- ]?authorized','not authorized by honda','unauthori[sz]ed application','application\(s\) detected','authorized by honda','MD_PackageLocalRepository','com[./]honda[./]maliciousdetector')
$results=@(foreach($path in Get-ChildItem "$root/adb","$root/apks" -Recurse -File | Where-Object {$_.Extension-in'.apk','.jar'}) {
 $hits=@();$err=$null;$zip=$null
 try {
  $zip=[IO.Compression.ZipFile]::OpenRead($path.FullName)
  foreach($entry in $zip.Entries|Where-Object {$_.FullName-match'\.(dex|arsc|xml)$'}) {
   $stream=$entry.Open();$memory=[IO.MemoryStream]::new()
   try{$stream.CopyTo($memory);$bytes=$memory.ToArray()}finally{$stream.Dispose();$memory.Dispose()}
   foreach($encoding in @([Text.Encoding]::UTF8,[Text.Encoding]::Unicode)) {
    $text=$encoding.GetString($bytes)
    foreach($pattern in $patterns){foreach($match in [regex]::Matches($text,$pattern,'IgnoreCase')){$hits+=@{entry=$entry.FullName;encoding=$encoding.WebName;pattern=$pattern;match=$match.Value}}}
   }
  }
 }catch{$err=$_.Exception.Message}finally{if($zip){$zip.Dispose()}}
 [ordered]@{path=$path.FullName;sha256=(Get-FileHash $path.FullName).Hash;hits=$hits;error=$err}
})
$results|ConvertTo-Json -Depth 7|Set-Content "$out/archive-search.json"
[ordered]@{archives=$results.Count;archivesWithHits=@($results|Where-Object {$_.hits.Count});errors=@($results|Where-Object {$_.error})}|ConvertTo-Json -Depth 7
