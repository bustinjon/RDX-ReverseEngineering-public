param([Parameter(Mandatory=$true)][string]$OutputDirectory)
$ErrorActionPreference='Stop'
New-Item -ItemType Directory -Force -Path $OutputDirectory|Out-Null
$errorsList=[Collections.Generic.List[string]]::new();$found=[Collections.Generic.List[object]]::new();$archives=[Collections.Generic.List[object]]::new();$visited=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$known=@("$env:LOCALAPPDATA/Android/Sdk","$env:USERPROFILE/.android","$env:LOCALAPPDATA/Android","$env:APPDATA/Google","$env:LOCALAPPDATA/Google",'C:/Android','C:/android-sdk','C:/SDK',"$env:USERPROFILE/Downloads","$env:USERPROFILE/Documents","$env:USERPROFILE/Desktop","$env:USERPROFILE/.VirtualBox","$env:USERPROFILE/VirtualBox VMs","$env:APPDATA/Docker","$env:LOCALAPPDATA/Docker",'C:/ProgramData/DockerDesktop','C:/Program Files (x86)/Android','C:/Program Files/Android',"$root/tools","$root/adb")
$drives=@([IO.DriveInfo]::GetDrives()|Where-Object {$_.DriveType-eq[IO.DriveType]::Fixed-and$_.IsReady}|ForEach-Object {$_.Name})
foreach($drive in $drives){foreach($name in @('Android','android-sdk','SDK','Tools','Archives','Backup','Backups','VMs','WSL','Docker','Development','Dev')){$known+=Join-Path $drive $name}}
$queue=[Collections.Generic.Queue[object]]::new();$roots=@(foreach($p in ($known|Sort-Object -Unique)){try{$exists=Test-Path -LiteralPath $p;if($exists){$queue.Enqueue([pscustomobject]@{path=(Resolve-Path -LiteralPath $p).Path;depth=0})};[pscustomobject]@{path=$p;exists=$exists}}catch{$errorsList.Add("$p : $($_.Exception.Message)")}})
$entries=0;$limit=90000;$depthLimit=6
while($queue.Count-and$entries-lt$limit){$item=$queue.Dequeue();if(-not$visited.Add($item.path)){continue};try{$children=@(Get-ChildItem -LiteralPath $item.path -Force -ErrorAction Stop)}catch{$errorsList.Add("$($item.path): $($_.Exception.Message)");continue}
 foreach($f in $children){$entries++;if($entries-ge$limit){break};if($f.Attributes-band[IO.FileAttributes]::ReparsePoint){continue}
  if($f.PSIsContainer){
   if($f.Name-match'^(Cache|Code Cache|GPUCache|node_modules|\.git|\.gradle|Service Worker|Crashpad|IndexedDB|Logs|log|build|decompiled|analysis|RDX-Audit|RDX-Audit-full)$'){continue}
   if($f.Name-match'^(android-22|system-images|[^/]*\.avd|android-sdk[^/]*|Android Studio[^/]*)$'){$found.Add([pscustomobject]@{path=$f.FullName;kind='DIRECTORY';classification=if($f.Name-eq'android-22'){'POTENTIALLY_RUNNABLE'}else{'STALE_REFERENCE'};detail='Directory name only; inspect image metadata before use'})}
   if($item.depth-lt$depthLimit-and$f.FullName-ne$root){$queue.Enqueue([pscustomobject]@{path=$f.FullName;depth=$item.depth+1})};continue
  }
  if($f.Name-match'^(system\.img|userdata\.img|ramdisk\.img|kernel-qemu.*|emulator.*\.exe|qemu.*\.exe|build\.prop|source\.properties|package\.xml|repositories\.cfg|config\.ini|.*\.avd\.ini|.*\.vbox|.*\.vmx|.*\.vhdx)$'){
   $text='';if($f.Length-lt262144-and$f.Extension-notin@('.img','.exe','.vhdx')){try{$text=(Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop)}catch{$errorsList.Add($f.FullName)}}
   $api22=$text-match'(ApiLevel\s*=\s*22|sdk\s*=\s*22|android-22|Android 5\.1)'
   $found.Add([pscustomobject]@{path=$f.FullName;kind='METADATA_OR_IMAGE';classification=if($api22-and$f.Name-in@('build.prop','source.properties','package.xml')){'POTENTIALLY_RUNNABLE'}else{'NOT_RELEVANT'};detail=($text-split"`n"|Where-Object {$_-match'ApiLevel|sdk=|release=|image.sysdir|target=|abi|MachineEntry|DistributionName'}|Select-Object -First 12)-join'; '})
  }
  if($f.Extension-in@('.zip','.7z','.rar','.tar','.tgz','.gz')){$archives.Add([pscustomobject]@{path=$f.FullName;bytes=$f.Length;rank=if($f.Name-match'android|sdk|emulator|system|backup|archive|vm'){0}else{1}})}
 }
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archiveRows=@();$budget=150
foreach($a in ($archives|Sort-Object rank,path|Select-Object -First $budget)){
 $matches=@();$status='NOT INSPECTED: no local format reader';try{
  if([IO.Path]::GetExtension($a.path)-eq'.zip'){$z=[IO.Compression.ZipFile]::OpenRead($a.path);try{$matches=@($z.Entries|Where-Object {$_.FullName-match'android-22|system-images|(^|/)(system\.img|ramdisk\.img|kernel-qemu[^/]*|emulator\.exe)$'}|Select-Object -First 100 -ExpandProperty FullName);$status='ZIP central directory only; no extraction'}finally{$z.Dispose()}}
  elseif([IO.Path]::GetExtension($a.path)-in@('.tar','.tgz','.gz')){if(Get-Command tar.exe -ErrorAction SilentlyContinue){$listing=& tar.exe -tf $a.path 2>$null;$matches=@($listing|Where-Object {$_-match'android-22|system-images|system\.img|ramdisk\.img|kernel-qemu'}|Select-Object -First 100);$status='Local tar member listing; no extraction'}}
 }catch{$status='UNREADABLE: '+$_.Exception.Message}
 $archiveRows+=[pscustomobject]@{path=$a.path;bytes=$a.bytes;status=$status;members=$matches;classification=if($matches.Count){'POTENTIALLY_RUNNABLE'}else{'NOT_RELEVANT'}}
}
$wsl=@();$lxss='HKCU:/Software/Microsoft/Windows/CurrentVersion/Lxss';if(Test-Path $lxss){$wsl=@(Get-ChildItem $lxss|ForEach-Object {Get-ItemProperty $_.PSPath|Select-Object DistributionName,BasePath,Version})}
$result=[ordered]@{scope='LOCAL-ONLY staged bounded archaeology; no removable drives scanned; no ADB/downloads';fixedDrives=$drives;roots=$roots;depthLimit=$depthLimit;entryLimit=$limit;entries=$entries;limitReached=($entries-ge$limit);candidateAssets=@($found);archivesFound=$archives.Count;archivesInspected=$archiveRows;archiveBudget=$budget;errors=@($errorsList);wslRegistrations=$wsl;dockerClientPresent=[bool](Get-Command docker.exe -ErrorAction SilentlyContinue);runtimeExecuted=$false;ADBexecuted=$false}
$result|ConvertTo-Json -Depth 9|Set-Content "$OutputDirectory/archaeology.json"
Write-Output "Scanned $entries entries in $($visited.Count) directories; $($archiveRows.Count) archives inventoried; evidence saved, no runtime booted."
