# Import Pester module for mocking
Import-Module Pester

BeforeAll {
    # Import the script content into a scriptblock
    $scriptPath = "$PSScriptRoot\..\FWindowsUpdateReboot.ps1"
}

Describe "FWindowsUpdateReboot Script Tests" {
    BeforeEach {
        # Mock functions that interact with the system
        Mock Set-ItemProperty { }
        Mock Get-ScheduledTask { throw "Task does not exist" }
        Mock Unregister-ScheduledTask { }
        Mock Copy-Item { }
        Mock Start-Process { 
            return [PSCustomObject]@{
                ExitCode = 0
            }
        }
        Mock Write-Host { }
        Mock Write-Error { }
        Mock Read-Host { return "Y" }
        Mock Get-Date { return [DateTime]::Parse("2024-03-20 14:00:00") }
        
        # Mock admin check properly
        Mock New-Object {
            if ($TypeName -eq 'Security.Principal.WindowsPrincipal') {
                $mockPrincipal = New-Object PSObject
                $mockPrincipal | Add-Member -MemberType ScriptMethod -Name IsInRole -Value { param($role) $true }
                return $mockPrincipal
            }
            return $null
        } -ParameterFilter { $TypeName -eq 'Security.Principal.WindowsPrincipal' }
    }

    Context "Active Hours Rotation" -Tag "ActiveHours" {
        It "Should calculate correct active hours" {
            # Execute the script with Rotate parameter
            $global:PSCommandPath = $scriptPath
            . $scriptPath -Rotate
            
            # Check if Set-ItemProperty was called with correct values
            Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
                $Path -eq "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -and
                $Name -eq "ActiveHoursStart" -and
                $Value -eq 14
            }
            
            Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
                $Path -eq "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -and
                $Name -eq "ActiveHoursEnd" -and
                $Value -eq 8  # (14 + 18) % 24 = 8
            }
        }
    }
    
    Context "Installation" -Tag "Installation" {
        It "Should create scheduled task correctly" {
            # Execute the script
            $global:PSCommandPath = $scriptPath
            . $scriptPath
            
            # Verify Start-Process was called with correct schtasks.exe parameters
            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
                $FilePath -eq "schtasks.exe" -and
                $ArgumentList -contains "/Create" -and
                $ArgumentList -contains "/SC" -and
                $ArgumentList -contains "HOURLY"
            }
        }
    }
    
    Context "Uninstallation" -Tag "Uninstallation" {
        It "Should remove scheduled task and script" {
            # Mock Get-ScheduledTask to return a task this time
            Mock Get-ScheduledTask { return [PSCustomObject]@{} }
            
            # Execute the script with Uninstall parameter
            $global:PSCommandPath = $scriptPath
            . $scriptPath -Uninstall
            
            # Verify task removal was attempted
            Should -Invoke Unregister-ScheduledTask -Times 1 -Exactly
        }
    }
} 