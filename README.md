# FWindowsUpdateReboot

A Simple PowerShell Script that once ran will prevent windows update from every rebooting your PC again automatically.

## How to install

### Option 1:
1. Download the script
2. Right click the script and select "Run with Powershell"
3. When prompted, click "Yes" to run the script with administrator privileges
4. Give Windows Update the finger, you have finally defeated it.

### Option 2:
1. Download the script
2. Open a PowerShell window with administrator privileges
3. Navigate to the directory where the script is located
4. Run the script with the following command: `powershell -ExecutionPolicy Bypass -File FWindowsUpdateReboot.ps1`
5. Give Windows Update the finger, you have finally defeated it.

## How to uninstall

1. Open a PowerShell window with administrator privileges
2. Run the following command: `FWindowsUpdateReboot -Uninstall`

## How does it get around Windows Update restarting your PC?

Windows Update forces you to reboot your PC to install updates, however it won't do so if the current time is within your Active Hours.
You are limited to 18 hours for Active Hours, and if you are outside of that, you will be rebooted.
The script works by to permanently prevent Windows Update from restarting your PC by continuously rotating your Windows Active Hours every hour so you're never outside of Active Hours.

## What is the script doing?

1. If not run with administrator privileges, the script will request elevation to run as administrator.
2. The script will then:
   - Copy itself to the Windows System32 directory
   - Create a scheduled task called "FWindowsUpdateReboot" that runs every hour
3. The scheduled task runs the script with the -Rotate parameter, which:
   - Sets Active Hours to start at the current hour
   - Sets Active Hours to end 18 hours later (the maximum allowed duration)
   - Updates these settings in the Windows registry

By dynamically adjusting Active Hours every hour, you are never outside of Active Hours, and Windows Update will never find a suitable time outside of Active Hours to restart your computer.

The script runs silently in the background using minimal resources.

For example, if you're using your PC at 2 PM:
- Active Hours will be set to 2 PM - 8 AM
- An hour later at 3 PM, they'll adjust to 3 PM - 9 AM
- This continues as long as your PC is running

The script requires a one-time setup with administrator privileges, but then runs automatically as a system service requiring no further interaction.

## ⚠️ Security Reminder

Before running any PowerShell script downloaded from the internet (including this one), you should always review its contents to ensure it's safe. While this script is open source and safe to use, it's good security practice to verify scripts before executing them with administrator privileges. 

The full source code is available in this repository for transparency and security verification.

Review the script source code to ensure it's safe:

https://github.com/cboileau/FWindowsUpdateReboot/blob/4eeee1f0e29e3bad1fd22c02dbe23ad78f456141/FWindowsUpdateReboot.ps1#L1-L153

## Testing

The project includes unit tests written using Pester, the standard testing framework for PowerShell. Tests can be run locally or through GitHub Actions CI pipeline.

### Running Tests Locally

#### Option 1: Using the Test Runner Script (Recommended)

1. Clone the repository:
```powershell
git clone https://github.com/cboileau/FWindowsUpdateReboot.git
cd FWindowsUpdateReboot
```

You can also run specific test categories from PowerShell:
```powershell
# Run all tests
.\Run-Tests.ps1 -TestType All

# Run only installation tests
.\Run-Tests.ps1 -TestType Installation

# Run only active hours tests
.\Run-Tests.ps1 -TestType ActiveHours

# Run only uninstallation tests
.\Run-Tests.ps1 -TestType Uninstallation
```

### CI/CD

The project uses GitHub Actions to run tests automatically on:
- Every push to the main branch
- Every pull request to the main branch

Test results can be viewed in the Actions tab of the repository.

### Running Individual Test Cases

To run specific test cases, you can use Pester's filtering:

```powershell
# Run only installation tests
$config = New-PesterConfiguration
$config.Filter.Tag = "Installation"
$config.Run.Path = "Tests"
Invoke-Pester -Configuration $config

# Run only active hours tests
$config = New-PesterConfiguration
$config.Filter.Tag = "ActiveHours"
$config.Run.Path = "Tests"
Invoke-Pester -Configuration $config
```

### Troubleshooting Tests

If tests fail, check:
1. Pester is installed correctly
2. You're in the correct directory
3. Your PowerShell execution policy allows running scripts


