[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet('All', 'Installation', 'ActiveHours', 'Uninstallation')]
    [string]$TestType = 'All'
)

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Tests must be run as Administrator. Restarting with elevation..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -TestType $TestType" -Verb RunAs
    exit
}

# Ensure Pester is installed
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Pester not found. Installing Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Configure Pester
$config = New-PesterConfiguration
$config.Run.Path = $PSScriptRoot
$config.Output.Verbosity = "Detailed"

# Apply test filter if specified
if ($TestType -ne 'All') {
    $config.Filter.Tag = $TestType
}

# Run tests
Write-Host "Running $TestType tests..." -ForegroundColor Cyan
Invoke-Pester -Configuration $config

Write-Host "`nPress Enter to exit..." -ForegroundColor Green
$null = Read-Host 