# collect_sh.ps1
$files = Get-ChildItem -Path "." -Filter "*.sh" -File
if ($files.Count -eq 0) { Write-Host "No .sh files found" -ForegroundColor Red; exit 1 }
$zipName = "sh_prgr.zip"
$tempDir = Join-Path $env:TEMP "sh_temp_$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
foreach ($file in $files) { Copy-Item $file.FullName -Destination $tempDir }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $zipName)
Remove-Item $tempDir -Recurse -Force
Write-Host "Created: $zipName ($($files.Count) files)" -ForegroundColor Green