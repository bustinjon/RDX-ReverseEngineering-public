param([Parameter(Mandatory=$true)][string]$OutputDirectory)
$ErrorActionPreference='Stop'
$keytool='C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin/keytool.exe'
New-Item -ItemType Directory -Force -Path $OutputDirectory|Out-Null
$OutputDirectory=(Resolve-Path $OutputDirectory).Path
if(Get-ChildItem -LiteralPath $OutputDirectory -Filter *.p12){throw 'Fresh output directory required'}
function Run-Key([string[]]$Arguments){
 & $keytool @Arguments -storepass:env RDX_SIGNING_PASSWORD -keypass:env RDX_SIGNING_PASSWORD *> (Join-Path $OutputDirectory 'keytool-last.log')
 if($LASTEXITCODE-ne0){Get-Content (Join-Path $OutputDirectory 'keytool-last.log');throw 'Test-only credential generation failed'}
}
foreach($root in @('root','other-root')){
 Run-Key @('-genkeypair','-alias',$root,'-dname',"CN=RDX DISPOSABLE TEST $root",'-keyalg','RSA','-keysize','2048','-validity','3650','-ext','bc:c','-ext','ku=keyCertSign,cRLSign','-storetype','PKCS12','-keystore',"$OutputDirectory/$root.p12",'-noprompt')
 Run-Key @('-exportcert','-alias',$root,'-keystore',"$OutputDirectory/$root.p12",'-file',"$OutputDirectory/$root.cer")
 Run-Key @('-importcert','-alias',$root,'-file',"$OutputDirectory/$root.cer",'-keystore',"$OutputDirectory/$root-trust.p12",'-storetype','PKCS12','-noprompt')
}
foreach($leaf in @('server','client','expired','future','other-client')){
 $role=if($leaf -in @('client','other-client')){'clientAuth'}else{'serverAuth'}
 $name=if($role-eq'clientAuth'){'rdx-client.invalid'}else{'rdx-test.invalid'}
 $issuer=if($leaf-eq'other-client'){'other-root'}else{'root'}
 Run-Key @('-genkeypair','-alias','leaf','-dname',"CN=$name,OU=DISPOSABLE HOST TEST",'-keyalg','RSA','-keysize','2048','-validity','365','-keystore',"$OutputDirectory/$leaf.p12",'-storetype','PKCS12','-noprompt')
 Run-Key @('-certreq','-alias','leaf','-keystore',"$OutputDirectory/$leaf.p12",'-file',"$OutputDirectory/$leaf.csr")
 $extra=@();if($leaf-eq'expired'){$extra=@('-startdate','2020/01/01 00:00:00','-validity','1')}elseif($leaf-eq'future'){$extra=@('-startdate','2035/01/01 00:00:00','-validity','1')}else{$extra=@('-validity','365')}
 Run-Key (@('-gencert','-alias',$issuer,'-keystore',"$OutputDirectory/$issuer.p12",'-infile',"$OutputDirectory/$leaf.csr",'-outfile',"$OutputDirectory/$leaf.cer",'-ext',"SAN=dns:$name",'-ext',"eku=$role",'-ext','ku=digitalSignature,keyEncipherment')+$extra)
 Run-Key @('-importcert','-alias',$issuer,'-file',"$OutputDirectory/$issuer.cer",'-keystore',"$OutputDirectory/$leaf.p12",'-noprompt')
 Run-Key @('-importcert','-alias','leaf','-file',"$OutputDirectory/$leaf.cer",'-keystore',"$OutputDirectory/$leaf.p12",'-noprompt')
}
Get-ChildItem -LiteralPath $OutputDirectory -File|Where-Object Extension -in @('.p12','.cer','.csr')|ForEach-Object {[pscustomobject]@{path=$_.FullName;bytes=$_.Length;sha256=(Get-FileHash $_.FullName).Hash;privateKeyContainer=($_.Extension-eq'.p12'-and $_.BaseName-notlike'*-trust')}}|ConvertTo-Json|Set-Content "$OutputDirectory/credential-hashes.json"
Set-Content "$OutputDirectory/TEST-ONLY.txt" 'Disposable generated host-memory TLS credentials. Never Honda/phone credentials. Password is public test-only. Private-key containers will be deleted after validation; hashes retained.'
Write-Output "Disposable test credentials generated at $OutputDirectory"
