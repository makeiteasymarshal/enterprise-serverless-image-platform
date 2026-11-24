$ErrorActionPreference = "Stop"
$Incoming = terraform -chdir=terraform output -raw incoming_bucket_name
$Processed = terraform -chdir=terraform output -raw processed_bucket_name

Write-Host "Emptying versioned incoming bucket: $Incoming"
$versions = aws s3api list-object-versions --bucket $Incoming --output json | ConvertFrom-Json
$objects = @()
foreach ($item in @($versions.Versions)) {
    if ($null -ne $item) {
        $objects += @{ Key = $item.Key; VersionId = $item.VersionId }
    }
}
foreach ($item in @($versions.DeleteMarkers)) {
    if ($null -ne $item) {
        $objects += @{ Key = $item.Key; VersionId = $item.VersionId }
    }
}

for ($i = 0; $i -lt $objects.Count; $i += 1000) {
    $last = [Math]::Min($i + 999, $objects.Count - 1)
    $batch = @($objects[$i..$last])
    $payload = @{ Objects = $batch; Quiet = $true } | ConvertTo-Json -Depth 5
    $tempFile = Join-Path $env:TEMP ("s3-delete-" + [guid]::NewGuid() + ".json")
    [System.IO.File]::WriteAllText($tempFile, $payload, [System.Text.UTF8Encoding]::new($false))
    aws s3api delete-objects --bucket $Incoming --delete "file://$tempFile"
    Remove-Item $tempFile -Force
    if ($LASTEXITCODE -ne 0) { throw "Failed to delete versions from $Incoming" }
}

Write-Host "Emptying processed bucket: $Processed"
aws s3 rm "s3://$Processed" --recursive
if ($LASTEXITCODE -ne 0) { throw "Failed to empty $Processed" }

Write-Host "Buckets are empty. Review and destroy the Terraform stack manually:"
Write-Host "terraform -chdir=terraform plan -destroy"
Write-Host "terraform -chdir=terraform destroy"
