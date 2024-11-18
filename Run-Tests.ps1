[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet('All', 'Installation', 'ActiveHours', 'Uninstallation')]
    [string]$TestType = 'All'
)

# Ensure Pester is installed
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Pester not found. Installing Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Write-Host "Starting test run..." -ForegroundColor Cyan
Write-Host "Test type: $TestType" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan

# Configure Pester
$config = New-PesterConfiguration
$config.Run.Path = Join-Path $PSScriptRoot "Tests"
$config.Output.Verbosity = "Detailed"
$config.Run.PassThru = $true

# Apply test filter if specified
if ($TestType -ne 'All') {
    Write-Host "Running only $TestType tests..." -ForegroundColor Yellow
    $config.Filter.Tag = @($TestType)
} else {
    Write-Host "Running all tests..." -ForegroundColor Yellow
    $config.Filter.Tag = @()
}

# Run tests
$testResults = Invoke-Pester -Configuration $config

# Display results summary
Write-Host "`nTest Results Summary:" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Passed: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Failed: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Cyan

if ($testResults.FailedCount -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    $testResults.Failed | ForEach-Object {
        Write-Host "- $($_.Name)" -ForegroundColor Red
        Write-Host "  $($_.ErrorRecord)" -ForegroundColor Red
    }
}

Write-Host "`nPress Enter to exit..." -ForegroundColor Green
$null = Read-Host 