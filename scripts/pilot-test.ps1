param(
  [Parameter(Mandatory = $true)][string]$ImagePath,
  [Parameter(Mandatory = $true)][string]$JwtToken
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Api = terraform -chdir="$Root\terraform" output -raw upload_api_url
if (-not (Test-Path $ImagePath)) { throw "Image not found: $ImagePath" }
$Extension = [IO.Path]::GetExtension($ImagePath).ToLowerInvariant()
$ContentType = switch ($Extension) {
  ".jpg" { "image/jpeg" }
  ".jpeg" { "image/jpeg" }
  ".png" { "image/png" }
  ".webp" { "image/webp" }
  default { throw "Supported extensions: .jpg, .jpeg, .png, .webp" }
}
$Payload = @{ filename = [IO.Path]::GetFileName($ImagePath); content_type = $ContentType } | ConvertTo-Json
$Headers = @{ Authorization = "Bearer $JwtToken" }
$Ticket = Invoke-RestMethod -Method Post -Uri "$Api/uploads" -Headers $Headers -ContentType "application/json" -Body $Payload
Invoke-WebRequest -Method Put -Uri $Ticket.upload_url -InFile $ImagePath -ContentType $ContentType | Out-Null
Write-Host "Uploaded object: $($Ticket.object_key)"
Write-Host "Wait for SQS/Lambda processing, then inspect the processed bucket and DynamoDB table."
