function Write-ScriptMessage {
  param (
    [String]$Message
  )

  Write-Host "[SETUP SCRIPT] $Message" -ForegroundColor Green
}

Write-ScriptMessage "Installing scoop"
Invoke-RestMethod get.scoop.sh | Invoke-Expression

Write-ScriptMessage "Installing needed packages"
scoop install 7zip
reg import "$env:USERPROFILE\scoop\apps\7zip\current\install-context.reg"
scoop install git
scoop install pwsh
scoop install sudo

Start-Process pwsh -Verb runAs -Args "-ExecutionPolicy Bypass .\setup-pwsh.ps1 $args"
