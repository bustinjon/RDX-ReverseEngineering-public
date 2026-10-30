param([Parameter(Mandatory=$true)][string]$Build,[Parameter(Mandatory=$true)][string]$Credentials,[Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$project=Join-Path $root 'analysis/parallel-aa-receiver/clean-receiver'
$java='C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin/java.exe'
if(-not(Test-Path "$Credentials/TEST-ONLY.txt")-or-not(Test-Path "$Credentials/credential-hashes.json")){throw 'Completed disposable TEST hierarchy required; no other credentials allowed'}
foreach($name in @('root-trust','other-root-trust','client','server','expired','future','other-client')){if(-not(Test-Path "$Credentials/$name.p12")){throw "Missing test fixture $name"}}
foreach($f in (Get-Content "$Credentials/credential-hashes.json" -Raw|ConvertFrom-Json)){if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256){throw 'Generated test credential fixture differs'}}
New-Item -ItemType Directory -Force -Path $Output|Out-Null
& $java -Xmx256m -cp "$Build/tests" com.rdx.fullscreen.clean.TlsLoopbackTests $project $Credentials "$root/analysis/parallel-aa-receiver/decoder-test/assets/clips" $Output *> "$Output/test-results.txt"
if($LASTEXITCODE-ne0){Get-Content "$Output/test-results.txt" -Tail 20;throw 'Real memory TLS host tests failed'}
$rejects=@(Get-Content "$Output/conformance.txt"|Where-Object {$_-like'REJECT *'})
if($rejects.Count-ne7-or @($rejects|Where-Object {$_-notmatch'cause=(SSLHandshakeException|CertificateException)$'}).Count){throw 'Trust negative must fail for certificate/TLS reason, not missing fixture or harness error'}
Get-Content "$Output/test-results.txt" -Tail 1
