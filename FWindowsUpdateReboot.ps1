# rotate-active-hours.ps1
# PowerShell script to rotate Active Hours and set up scheduled task

param (
    [switch]$Rotate
)

# Check if running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Relaunch the script with administrator privileges
    $arguments = "& `"${PSCommandPath}`""
    if ($Rotate) {
        $arguments += " -Rotate"
    }
    Start-Process -FilePath "PowerShell" -Verb RunAs -ArgumentList $arguments
    exit
}

# Define variables
$taskName = "FWindowsUpdateReboot"
$system32Path = "$env:windir\System32"
$scriptName = "rotate-active-hours.ps1"
$destinationPath = Join-Path -Path $system32Path -ChildPath $scriptName
$sourceScriptPath = $MyInvocation.MyCommand.Path

if ($Rotate) {
    # Rotate Active Hours
    $activeHoursDuration = 18  # Maximum allowed active hours duration in hours
    $currentHour = (Get-Date).Hour

    $newActiveHoursStart = $currentHour
    $newActiveHoursEnd = ($currentHour + $activeHoursDuration) % 24

    # Update the registry keys
    $registryPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"

    Set-ItemProperty -Path $registryPath -Name "ActiveHoursStart" -Value $newActiveHoursStart -Type DWord
    Set-ItemProperty -Path $registryPath -Name "ActiveHoursEnd" -Value $newActiveHoursEnd -Type DWord

    Write-Host "Active hours updated: Start=$newActiveHoursStart, End=$newActiveHoursEnd"
} else {
    # Copy the script to System32 if it's not already there
    if ($sourceScriptPath -ieq $destinationPath) {
        Write-Host "Script is already in System32."
    } else {
        Write-Host "Copying script to System32..."
        try {
            Copy-Item -Path $sourceScriptPath -Destination $destinationPath -Force
            Write-Host "Script copied to $destinationPath"
        } catch {
            Write-Error "Failed to copy script to System32."
            exit 1
        }
    }

    # Remove existing scheduled task if it exists and set it up again
    try {
        # Check if the task exists
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop

        # If it exists, remove it
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "Scheduled task '$taskName' existed and has been removed."
    } catch {
        Write-Host "Scheduled task '$taskName' does not exist. Proceeding to create it."
    }

    Write-Host "Creating scheduled task '$taskName'..."

    # Define the action to run the script from System32 with the -Rotate parameter
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptName`" -Rotate"

    # Set the trigger to run every hour indefinitely (RepetitionDuration set to maximum value)
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) `
        -RepetitionInterval (New-TimeSpan -Hours 1) `
        -RepetitionDuration ([TimeSpan]::MaxValue)

    # Create the scheduled task principal to run as SYSTEM
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Define the task settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden

    # Register the scheduled task
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings

    Write-Host "Scheduled task '$taskName' has been created successfully."
}