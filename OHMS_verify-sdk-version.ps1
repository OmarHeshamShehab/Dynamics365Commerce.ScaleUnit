# ============================================
# Commerce SDK Version Verification Script
# Run from repo root folder
# ============================================

# ===========================================
# CONFIGURATION - MODIFY THESE AS NEEDED
# ===========================================

# Current SDK version to verify
$CurrentVersion = "9.57"

# Old versions to check for (should NOT exist)
$OldVersions = "9.55|9.53|9.54|9.56"

# Expected .NET SDK version
$ExpectedDotNetSdk = "8.0.419"

# Expected target frameworks
$ExpectedFrameworks = "net8.0, netstandard2.0, net472"

# Expected MajorVersion in repo.props
$ExpectedMajorVersion = "9.57"

# Expected PackagesVersion range
$ExpectedPackagesRange = "[9.57.*-*,9.58)"

# Pipeline YAML path
$PipelineYamlPath = ".\Pipeline\YAML_Files\build-pipeline.yml"

# repo.props path
$RepoPropsPath = ".\repo.props"

# global.json path
$GlobalJsonPath = ".\global.json"

# ===========================================
# VERIFICATION SCRIPT - NO CHANGES NEEDED BELOW
# ===========================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "1. COMMERCE SDK VERSIONS IN .CSPROJ FILES" -ForegroundColor Cyan
Write-Host "   Expected: All should show $CurrentVersion.x" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan
Get-ChildItem -Recurse -Filter "*.csproj" | Select-String $CurrentVersion | ForEach-Object { $_.Line.Trim() }

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "2. CHECK FOR OLD VERSION REFERENCES" -ForegroundColor Cyan
Write-Host "   Expected: No output (empty = good)" -ForegroundColor Gray
Write-Host "   Checking for: $OldVersions" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan
$oldRefs = Get-ChildItem -Recurse -Include *.csproj,*.props,global.json | Select-String $OldVersions | Select-Object Filename, Line
if ($oldRefs) { $oldRefs } else { Write-Host "None found - Clean!" -ForegroundColor Green }

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "3. REPO.PROPS CONTENT" -ForegroundColor Cyan
Write-Host "   Expected: MajorVersion=$ExpectedMajorVersion, PackagesVersion=$ExpectedPackagesRange" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan
Get-Content $RepoPropsPath

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "4. GLOBAL.JSON CONTENT" -ForegroundColor Cyan
Write-Host "   Expected: SDK version $ExpectedDotNetSdk or compatible" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan
Get-Content $GlobalJsonPath

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "5. TARGET FRAMEWORKS" -ForegroundColor Cyan
Write-Host "   Expected: $ExpectedFrameworks" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan
Get-ChildItem -Recurse -Filter "*.csproj" | Select-String "TargetFramework" | ForEach-Object { $_.Line.Trim() } | Select-Object -Unique

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "6. INSTALLED .NET SDKs" -ForegroundColor Cyan
Write-Host "   Expected: $ExpectedDotNetSdk or higher" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan
dotnet --list-sdks

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "7. PIPELINE YAML" -ForegroundColor Cyan
Write-Host "   Expected: No hardcoded versions" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan
Get-Content $PipelineYamlPath

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "8. ALL .PROPS FILES (excluding obj folders)" -ForegroundColor Cyan
Write-Host "   Expected: Versions aligned to $CurrentVersion.x" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan
Get-ChildItem -Recurse -Filter "*.props" | Where-Object { $_.FullName -notlike "*\obj\*" } | ForEach-Object { Write-Host "=== $($_.Name) ===" -ForegroundColor Yellow; Get-Content $_.FullName }

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "VERIFICATION COMPLETE" -ForegroundColor Green
Write-Host "Verified for Commerce SDK version: $CurrentVersion" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green