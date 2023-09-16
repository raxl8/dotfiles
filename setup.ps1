param(
  [switch]$SecondStep,
  [switch]$KeepOneDrive,
  [switch]$GitConfig,
  [string]$SSHFolder,
  [string]$GPGKey,
  [switch]$FirefoxExtensions,
  [switch]$VSCode,
  [switch]$WSL
)

function Write-ScriptMessage {
  param (
      [String]$Message
  )

  Write-Host "[SETUP SCRIPT] $Message" -ForegroundColor Green
}

if (!$SecondStep) {
  Write-ScriptMessage "Installing scoop"
  Invoke-RestMethod get.scoop.sh | Invoke-Expression
  
  Write-ScriptMessage "Installing needed packages"
  scoop install 7zip
  reg import "$env:USERPROFILE\scoop\apps\7zip\current\install-context.reg"
  scoop install git
  scoop install pwsh
  scoop install sudo

  Start-Process pwsh -Verb runAs -Args "-ExecutionPolicy Bypass $($MyInvocation.Line) -SecondStep"
  exit
}

function Set-RegistryValue {
  param (
    [String]$Path,
    [String]$Name,
    $Value,
    [String]$Type
  )

  $key = Get-Item -Path $Path -ErrorAction SilentlyContinue
  if ($null -eq $key) {
    New-Item -Path $Path -ItemType Key -Force
  }

  $reg = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
  if ($null -eq $reg) {
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force
  } else {
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
  }
}

function Remove-PinnedProgram {
  param (
    [String]$Name
  )

  ((New-Object -Com Shell.Application).NameSpace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}").Items() |
    Where-Object { $_.Name -eq $Name }).Verbs() | Where-Object { $_.Name.replace("&","") -match "Unpin from taskbar" } | ForEach-Object { $_.DoIt() }
}

function Remove-Appx {
  param (
    [String]$Name
  )

  powershell.exe -NoProfile { $ProgressPreference = 'SilentlyContinue'; Get-AppxPackage $args[0] | Remove-AppPackage }  -args $Name
}

$ProgressPreference = "SilentlyContinue";

#
# Default apps
#

Write-ScriptMessage "Removing useless Appxs"
$appxsToRemove = @(
  "Microsoft.549981C3F5F10",
  "Microsoft.Getstarted",
  "MicrosoftTeams",
  "microsoft.windowscommunicationsapps",
  "Microsoft.WindowsAlarms",
  "Microsoft.Todos",
  "Microsoft.YourPhone",
  "Microsoft.WindowsSoundRecorder",
  "Microsoft.WindowsMaps",
  "Microsoft.WindowsFeedbackHub",
  "Microsoft.WindowsCamera",
  "Microsoft.PowerAutomateDesktop",
  "Microsoft.People",
  "Microsoft.MicrosoftStickyNotes",
  "Microsoft.MicrosoftSolitaireCollection",
  "Microsoft.MicrosoftOfficeHub",
  "Microsoft.GetHelp",
  "Microsoft.BingWeather",
  "Microsoft.BingNews",
  "Clipchamp.Clipchamp",
  "Microsoft.ZuneVideo",
  "SpotifyAB.SpotifyMusic"
)
foreach ($appxsToRemove in $appxsToRemove) {
  Write-ScriptMessage "Removing Appx $appxsToRemove"
  Remove-Appx $appxsToRemove
}

if (!$KeepOneDrive) {
  Write-ScriptMessage "Removing OneDrive"
  Stop-Process -Name OneDrive -Force
  Start-Process "C:\Windows\SysWOW64\OneDriveSetup.exe" -Args "/uninstall" -Wait
}

Start-Process DISM -Args "/online /disable-feature /featurename:WindowsMediaPlayer"

#
# Settings
#

Write-ScriptMessage "Disabling Mouse acceleration"
Set-RegistryValue -Path "HKCU:Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -Type "String"
Set-RegistryValue -Path "HKCU:Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -Type "String"
Set-RegistryValue -Path "HKCU:Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -Type "String"

Write-ScriptMessage "Disabling Recycle bin shortcut on Desktop"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value 1 -Type "DWord"

Write-ScriptMessage "Disabling Recycle bin on all drives"
Get-ChildItem "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\BitBucket\Volume" |
Foreach-Object { Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\BitBucket\Volume\$(Split-Path $_ -Leaf)" -Name "NukeOnDelete" -Value 1 -Type "DWord" }
  
Write-ScriptMessage "Removing Taskbar default icons"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type "DWord"

Write-ScriptMessage "Enabling dark mode"
Get-ChildItem "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops\Desktops" |
Foreach-Object { Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops\Desktops\$(Split-Path $_ -Leaf)" -Name "Wallpaper" -Value "C:\Windows\web\wallpaper\Windows\img19.jpg" -Type "String" }

Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" -Name "BackgroundHistoryPath0" -Value "C:\Windows\web\wallpaper\Windows\img19.jpg" -Type "String"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" -Name "BackgroundHistoryPath1" -Value "C:\Windows\web\wallpaper\Windows\img0.jpg" -Type "String"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Themes" -Name "CurrentTheme" -Value "C:\Windows\resources\Themes\dark.theme" -Type "String"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Themes" -Name "CurreThemeMRUntTheme" -Value "C:\Windows\resources\Themes\dark.theme;C:\Windows\resources\Themes\aero.theme;" -Type "String"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Themes\HighContrast" -Name "Pre-High Contrast Scheme" -Value "C:\Windows\resources\Themes\dark.theme" -Type "String"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type "DWord"

$setwallpapersrc = @"
using System.Runtime.InteropServices;

public class Wallpaper
{
  public const int SetDesktopWallpaper = 20;
  public const int UpdateIniFile = 0x01;
  public const int SendWinIniChange = 0x02;
  [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
  private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
  public static void SetWallpaper(string path)
  {
    SystemParametersInfo(SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange);
  }
}
"@
Add-Type -TypeDefinition $setwallpapersrc

[Wallpaper]::SetWallpaper("C:\Windows\web\wallpaper\Windows\img19.jpg")

Write-ScriptMessage "Disabling settings from the Settings app"
# Personalization -> Start
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_Layout" -Value 1 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Value 0 -Type "DWord"

# Apps -> Offline maps
Set-RegistryValue -Path "HKLM:System\Maps" -Name "AutoUpdateEnabled" -Value 0 -Type "DWord"

# Privacy & security -> General
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Control Panel\International\User Profile" -Name "HttpAcceptLanguageOptOut" -Value 1 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353694Enabled" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353696Enabled" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338393Enabled" -Value 0 -Type "DWord"

# Privacy & security -> Inked & typing personalization
Set-RegistryValue -Path "HKCU:Software\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Value 1 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value 1 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\CPSS\Store\InkingAndTypingPersonalization" -Name "Value" -Value 0 -Type "DWord"
# Privacy & security -> Diagnostics & feedback
Set-RegistryValue -Path "HKCU:Software\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Value 0 -Type "DWord"

# Privacy & security -> Search permission
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "SafeSearchMode" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsMSACloudSearchEnabled" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsAADCloudSearchEnabled" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsDeviceSearchHistoryEnabled" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsDynamicSearchBoxEnabled" -Value 0 -Type "DWord"

# Windows Update -> Advanced options -> Delivery Optimization
Set-RegistryValue -Path "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Value 1 -Type "DWord"

Write-ScriptMessage "Disabling Telemetry"
Set-RegistryValue -Path "HKLM:SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKLM:SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -Type "DWord"

Write-ScriptMessage "Disabling Applications suggestions"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OemPreInstalledAppsEnabled" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEverEnabled" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353698Enabled" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKLM:SOFTWARE\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type "DWord"

Write-ScriptMessage "Disabling Activity History"
Set-RegistryValue -Path "HKLM:SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKLM:SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKLM:SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0 -Type "DWord"

Write-ScriptMessage "Disabling Location Tracking"
Set-RegistryValue -Path "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Type "String"
Set-RegistryValue -Path "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKLM:SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value 0 -Type "DWord"

Write-ScriptMessage "Removing taskbar pinned programs"
Remove-PinnedProgram "Microsoft Edge"
Remove-PinnedProgram "Microsoft Store"

# Use WinSetView to remove Downloads folder Grouped by Date modified setting
# Also restarts explorer.exe
Write-ScriptMessage "Setting up Explorer"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -Value 0 -Type "DWord"
Set-RegistryValue -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowCloudFilesInQuickAccess" -Value 0 -Type "DWord"
PowerShell -ExecutionPolicy Bypass .\WinSetView\WinSetView.ps1 .\AppData\Win10.ini # Path is relative to script location

Write-ScriptMessage "Disabling Windows 11 Context Menu"
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
Stop-Process -Name explorer -Force
Start-Process explorer

Write-ScriptMessage "Adding Ultimate Performance power plan"
$power_scheme_guid = powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Select-String -Pattern "[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}" |
Select-Object -ExpandProperty Matches -First 1
powercfg /s $power_scheme_guid.Value

if ($GitConfig) {
  Write-ScriptMessage "Copying Git config"
  Copy-Item -Force .\.gitconfig $env:USERPROFILE
}

if ($SSHFolder) {
  Write-ScriptMessage "Copying SSH folder $SSHFolder"
  Copy-Item -Force -Recurse $SSHFolder $env:USERPROFILE
}

if ($GPGKey) {
  Write-ScriptMessage "Copying GPG Key"
  & $env:USERPROFILE\scoop\apps\git\current\usr\bin\gpg --import $GPGKey
}

Write-ScriptMessage "Setting up Powershell Core"
Write-ScriptMessage "Copying profile"
Copy-Item -Force -Recurse .\.config\powershell $env:USERPROFILE\.config
New-Item -Force -ItemType Directory -Path $env:USERPROFILE\Documents\PowerShell
Write-Output ". `$env:USERPROFILE\.config\powershell\user_profile.ps1" | Out-File -FilePath $env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 -Encoding ASCII -Append
Write-ScriptMessage "Installing Starship"
winget install --accept-source-agreements --id Starship.Starship
Write-ScriptMessage "Installing fzf"
scoop install fzf
Install-Module -Scope CurrentUser PSFzf -Force
Write-ScriptMessage "Installing PSFzf"
Write-ScriptMessage "Installing Terminal-Icons"
Install-Module -Scope CurrentUser Terminal-Icons -Force

Write-ScriptMessage "Setting up Windows Terminal"
Write-ScriptMessage "Downloading Font"
scoop bucket add nerd-fonts
sudo scoop install -g CascadiaCode-NF-Mono
Write-ScriptMessage "Copying Windows Terminal settings"
Copy-Item -Force .\windows_terminal\settings.json $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState
Write-ScriptMessage "Setting Windows Terminal as default terminal application"
Set-RegistryValue -Path "HKCU:Console\%%Startup" -Name "DelegationConsole" -Value "{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}" -Type "String"
Set-RegistryValue -Path "HKCU:Console\%%Startup" -Name "DelegationTerminal" -Value "{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}" -Type "String"

#
# Firefox
#

Write-ScriptMessage "Installing firefox"
scoop bucket add extras
scoop install firefox
# Set firefox to use profile Scoop
firefox -P "Scoop"

Write-ScriptMessage "Copying Firefox settings"
Copy-Item -Force .\firefox\user.js $env:USERPROFILE\scoop\persist\firefox\profile\

if ($FirefoxExtensions) {
  Write-ScriptMessage "Installing Firefox extensions"
  Add-Type -assembly "System.IO.Compression.FileSystem"
  New-Item -Force -ItemType Directory -Path "$env:USERPROFILE\scoop\persist\firefox\distribution\extensions"
  Push-Location .\firefox\extensions
  $firefox_extensions = @(
    "https://addons.mozilla.org/firefox/downloads/file/4132587/mal_sync-0.9.5.xpi",
    "https://addons.mozilla.org/firefox/downloads/file/4149786/nordvpn_proxy_extension-3.3.0.xpi",
    "https://addons.mozilla.org/firefox/downloads/file/4156117/proton_pass-1.5.4.xpi",
    "https://addons.mozilla.org/firefox/downloads/file/4164297/coupert-6.1.48.xpi",
    "https://addons.mozilla.org/firefox/downloads/file/4138833/adguard_adblocker-4.1.57.xpi",
    "https://addons.mozilla.org/firefox/downloads/file/4163966/sponsorblock-5.4.19.xpi"
  )
  foreach ($extension in $firefox_extensions) {
    Write-ScriptMessage "Installing Firefox extension $extension"
    $filename = $(Split-Path $extension -Leaf)
    Invoke-WebRequest -Uri "$extension" -OutFile $filename
    $extensionArchive = [System.IO.Compression.ZipFile]::OpenRead("$(Get-Location)\$filename")
    $manifestEntry = $extensionArchive.Entries | Where-Object { $_.FullName -eq "manifest.json" }
    $manifestStream = $manifestEntry.Open()
    $manifestReader = New-Object System.IO.StreamReader($manifestStream)
    $manifest = $manifestReader.ReadToEnd() | ConvertFrom-Json
    $manifestStream.Close()
    $extensionArchive.Dispose()
    if ($null -ne $manifest.browser_specific_settings) {
      $extensionId = $manifest.browser_specific_settings.gecko.id
    } elseif ($null -ne $manifest.applications) {
        $extensionId = $manifest.applications.gecko.id
    }
    Copy-Item -Force $filename "$env:USERPROFILE\scoop\persist\firefox\distribution\extensions\$extensionId.xpi"
  }
  Pop-Location
}

#
# Discord
#

Push-Location $env:TEMP
Invoke-WebRequest -Uri "https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x86" -OutFile DiscordSetup.exe
Start-Process .\DiscordSetup.exe -Wait
Pop-Location

Invoke-WebRequest "https://raw.githubusercontent.com/Vencord/Installer/main/install.ps1" -UseBasicParsing | Invoke-Expression

#
# VSCode
#

if ($VSCode) {
  Write-ScriptMessage "Installing VSCode"
  scoop install vscode
  reg import "$env:USERPROFILE\scoop\apps\vscode\current\install-associations.reg"
  Write-ScriptMessage "Copying up VSCode settings"
  New-Item -Force -ItemType Directory -Path $env:USERPROFILE\scoop\persist\vscode\data\user-data\User\
  Copy-Item -Force .\vscode\settings.json $env:USERPROFILE\scoop\persist\vscode\data\user-data\User\
  Copy-Item -Force .\vscode\keybindings.json $env:USERPROFILE\scoop\persist\vscode\data\user-data\User\

  Write-ScriptMessage "Installing VSCode extensions"
  $code_extensions = @(
    "jeff-hykin.better-cpp-syntax",
    "ms-vscode.cpptools-extension-pack",
    "leonardssh.vscord",
    "dbaeumer.vscode-eslint",
    "github.copilot",
    "esbenp.prettier-vscode",
    "ms-python.python",
    "ms-vscode-remote.vscode-remote-extensionpack",
    "rust-lang.rust-analyzer",
    "shardulm94.trailing-spaces"
  )
  foreach ($extension in $code_extensions) {
    Write-ScriptMessage "Installing VSCode extension $extension"
    code --install-extension $extension
  }
}

Write-ScriptMessage "Removing desktop shortcuts"
Get-ChildItem $env:USERPROFILE\Desktop\*.lnk | ForEach-Object {
  Write-ScriptMessage "Removing desktop shortcut $_.FullName"
  Remove-Item -Path $_.FullName
}

Remove-Appx "MicrosoftWindows.Client.WebExperience"

if ($WSL) {
  Write-ScriptMessage "Installing WSL"
  wsl.exe --install
}

Write-ScriptMessage "You can now reboot, press any key to continue"
Read-Host
