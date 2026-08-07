Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Equal {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Actual,
        [Parameter(Mandatory = $true)]
        [object]$Expected,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if ($Actual -ne $Expected) {
        throw "$Message`: expected '$Expected', got '$Actual'"
    }
}

$root = Join-Path ([System.IO.Path]::GetTempPath()) "herdr-terminal-profile-$([guid]::NewGuid().ToString('N'))"
$settingsPath = Join-Path $root "settings.json"
$herdrExe = Join-Path $root "herdr.exe"
$iconPath = Join-Path $root "herdr.png"
$firstDirectory = Join-Path $root "first"
$secondDirectory = Join-Path $root "second"
$installer = Join-Path $PSScriptRoot "install_windows_terminal_profile.ps1"
$profileGuid = "{e507d62a-bb8f-44b0-9c69-22625383acf3}"

try {
    New-Item -ItemType Directory -Path $root, $firstDirectory, $secondDirectory | Out-Null
    [System.IO.File]::WriteAllBytes($herdrExe, [byte[]](0x48, 0x45, 0x52, 0x44, 0x52))
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "..\website\assets\favicon.png") -Destination $iconPath
    @'
{
  "defaultProfile": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
  "profiles": {
    "defaults": {
      "elevate": true
    },
    "list": [
      {
        "guid": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
        "name": "PowerShell",
        "commandline": "pwsh.exe"
      }
    ]
  }
}
'@ | Set-Content -LiteralPath $settingsPath -Encoding UTF8

    & $installer `
        -HerdrExe $herdrExe `
        -IconPath $iconPath `
        -StartingDirectory $firstDirectory `
        -SettingsPath $settingsPath `
        -SetDefault | Out-Null

    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    Assert-Equal $settings.defaultProfile $profileGuid "default profile"
    Assert-Equal $settings.firstWindowPreference "defaultProfile" "single-window startup"
    Assert-Equal $settings.windowingBehavior "useAnyExisting" "new instance window reuse"
    Assert-Equal @($settings.profiles.list).Count 2 "profile count after first install"
    $profile = @($settings.profiles.list | Where-Object { $_.guid -eq $profileGuid })
    Assert-Equal $profile.Count 1 "Herdr profile count after first install"
    Assert-Equal $profile[0].commandline ('"' + (Resolve-Path $herdrExe).Path + '"') "Herdr commandline"
    Assert-Equal $profile[0].startingDirectory (Resolve-Path $firstDirectory).Path "Herdr starting directory"
    Assert-Equal $profile[0].icon (Resolve-Path $iconPath).Path "Herdr icon"
    Assert-Equal $profile[0].elevate $true "Herdr default elevation"
    Assert-Equal $profile[0].suppressApplicationTitle $true "Herdr title suppression"

    & $installer `
        -HerdrExe $herdrExe `
        -IconPath $iconPath `
        -StartingDirectory $secondDirectory `
        -SettingsPath $settingsPath `
        -SetDefault | Out-Null

    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    Assert-Equal @($settings.profiles.list).Count 2 "profile count after idempotent install"
    $profile = @($settings.profiles.list | Where-Object { $_.guid -eq $profileGuid })
    Assert-Equal $profile.Count 1 "Herdr profile count after idempotent install"
    Assert-Equal $profile[0].startingDirectory (Resolve-Path $secondDirectory).Path "updated starting directory"
    Assert-Equal $profile[0].elevate $true "Herdr elevation after idempotent install"
    Assert-Equal @($settings.profiles.list | Where-Object { $_.name -eq "PowerShell" }).Count 1 "existing profile preservation"
    Assert-Equal @(Get-ChildItem -LiteralPath $root -Filter "settings.json.herdr.tmp.*").Count 0 "temporary file cleanup"

    & $installer `
        -HerdrExe $herdrExe `
        -IconPath $iconPath `
        -StartingDirectory $secondDirectory `
        -SettingsPath $settingsPath `
        -Elevate | Out-Null
    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    $profile = @($settings.profiles.list | Where-Object { $_.guid -eq $profileGuid })
    Assert-Equal $profile[0].elevate $true "Herdr explicit elevation opt-in"

    & $installer `
        -HerdrExe $herdrExe `
        -IconPath $iconPath `
        -StartingDirectory $secondDirectory `
        -SettingsPath $settingsPath `
        -NoElevate | Out-Null
    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    $profile = @($settings.profiles.list | Where-Object { $_.guid -eq $profileGuid })
    Assert-Equal $profile[0].elevate $false "Herdr non-elevated opt-out"

    $conflictingElevationRejected = $false
    try {
        & $installer `
            -HerdrExe $herdrExe `
            -IconPath $iconPath `
            -StartingDirectory $secondDirectory `
            -SettingsPath $settingsPath `
            -Elevate `
            -NoElevate | Out-Null
    } catch {
        $conflictingElevationRejected = $true
    }
    Assert-Equal $conflictingElevationRejected $true "conflicting elevation switches"

    $settings.firstWindowPreference = "persistedLayoutAndContent"
    $settings.windowingBehavior = "useNew"
    $settings | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $settingsPath -Encoding UTF8
    & $installer `
        -HerdrExe $herdrExe `
        -IconPath $iconPath `
        -StartingDirectory $secondDirectory `
        -SettingsPath $settingsPath | Out-Null
    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    Assert-Equal $settings.firstWindowPreference "defaultProfile" "all-window restoration disabled"
    Assert-Equal $settings.windowingBehavior "useAnyExisting" "new instance reuse restored"

    Write-Host "Windows Terminal profile installer test passed"
} finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
