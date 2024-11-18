# rotate-active-hours.ps1
# PowerShell script to rotate Active Hours and set up scheduled task

param (
    [switch]$Rotate,
    [switch]$Uninstall
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
    if ($Uninstall) {
        $arguments += " -Uninstall"
    }
    Start-Process -FilePath "PowerShell" -Verb RunAs -ArgumentList $arguments
    exit
}

# Define variables
$taskName = "FWindowsUpdateReboot"
$system32Path = "$env:windir\System32"
$scriptName = "FWindowsUpdateReboot.ps1"
$destinationPath = Join-Path -Path $system32Path -ChildPath $scriptName
$sourceScriptPath = $MyInvocation.MyCommand.Path

if ($Uninstall) {
    # Remove the scheduled task if it exists
    try {
        Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "Scheduled task '$taskName' has been removed."
    } catch {
        Write-Host "Error removing scheduled task: $_"
        Write-Host "Scheduled task '$taskName' does not exist."
    }

    # Prompt user about script removal
    $removeScript = Read-Host "Would you like to remove the script from System32? (Y/N)"
    if ($removeScript -eq 'Y' -or $removeScript -eq 'y') {
        if (Test-Path $destinationPath) {
            Remove-Item -Path $destinationPath -Force
            Write-Host "Script removed from System32."
        } else {
            Write-Host "Script not found in System32."
        }
    }
    Write-Host "Successfully uninstalled $taskName. Press Enter to exit..."
    $null = Read-Host
    exit
}

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
    $scriptPath = Join-Path $system32Path $scriptName
    # Build the action command without inner quotes
    $action = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File $scriptPath -Rotate"

    # Enclose the entire action in double quotes for the /TR parameter
    $actionArgument = "`"$action`""
    # Use SchTasks.exe to create a task that runs every hour indefinitely
    $schtasksArguments = @(
        '/Create'
        '/RU', 'SYSTEM'
        '/SC', 'HOURLY'
        '/TN', $taskName
        '/TR', $actionArgument
        '/F'
    )
    # Execute the command to create the scheduled task
    $result = Start-Process -FilePath "schtasks.exe" -ArgumentList $schtasksArguments -Wait -PassThru -NoNewWindow
    if ($result.ExitCode -ne 0) {
        Write-Error "Failed to create scheduled task. Exit code: $($result.ExitCode)"
        Write-Host "Failed to create scheduled task. See the above error message for details."
    }
    else {
        Write-Host "Scheduled task '$taskName' has been created successfully."
        Write-Host "$taskName has been installed successfully."
        Write-Host "Give Windows Update the finger, you have finally defeated it."

        Write-Host "`n"
        Write-Host "         / \"
        Write-Host "        |\_/|"
        Write-Host "        |---|"
        Write-Host "        |   |" 
        Write-Host "        |   |"
        Write-Host "      _ |=-=| _"
        Write-Host "  _  / \|   |/ \"
        Write-Host " / \|   |   |   ||\"
        Write-Host "|   |   |   |   | \>"
        Write-Host "|   |   |   |   |   \"
        Write-Host "| -   -   -   - |)   )"
        Write-Host "|                   /"
        Write-Host " \                 /"
        Write-Host "  \               /"
        Write-Host "   \             /"
        Write-Host "    \           /"
        Write-Host "F Windows Update Reboot!"
        Write-Host "`n"
    }
    Write-Host "Press Enter to exit..."
    $null = Read-Host
    exit
}