$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Build = Join-Path $Root "build\processor"
if (Test-Path $Build) { Remove-Item $Build -Recurse -Force }
New-Item -ItemType Directory -Path $Build -Force | Out-Null
Copy-Item (Join-Path $Root "src\image_processor") $Build -Recurse
python -m pip install -r (Join-Path $Root "requirements.txt") --target $Build
$Zip = Join-Path $Root "build\processor.zip"
if (Test-Path $Zip) { Remove-Item $Zip -Force }
Compress-Archive -Path (Join-Path $Build "*") -DestinationPath $Zip
Write-Host "Created $Zip"
