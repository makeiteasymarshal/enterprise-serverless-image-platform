$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Build = Join-Path $Root "build\processor"
$Zip = Join-Path $Root "build\processor.zip"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker is required to build Linux-compatible Pillow dependencies for AWS Lambda."
}
if (Test-Path $Build) { Remove-Item $Build -Recurse -Force }
if (Test-Path $Zip) { Remove-Item $Zip -Force }
New-Item -ItemType Directory -Path $Build -Force | Out-Null

# Build native Pillow wheels in a Linux container, not on Windows.
docker run --rm -v "${Root}:/var/task" python:3.11-slim bash -lc "pip install --no-cache-dir -r /var/task/requirements.txt -t /var/task/build/processor && cp -r /var/task/src/image_processor /var/task/build/processor/"
if ($LASTEXITCODE -ne 0) { throw "Docker dependency build failed." }

Compress-Archive -Path (Join-Path $Build "*") -DestinationPath $Zip
Write-Host "Created Lambda artifact: $Zip"
