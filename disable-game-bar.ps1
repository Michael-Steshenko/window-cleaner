## Request Admin privileges automatically if not running as Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

## Uninstall Xbox Game Bar
Get-AppxPackage Microsoft.XboxGamingOverlay | Remove-AppxPackage

## Disable the "Open Xbox Game Bar using this button on a controller" in Windows Settings
reg add HKCU\SOFTWARE\Microsoft\GameBar /v UseNexusForGameBarEnabled /t REG_DWORD /d 0 /f *> $null

## Fix ms-gamebar pop up saying gamebar is missing when reconnecting a controller
reg add HKCR\ms-gamebar /f /ve /d URL:ms-gamebar *> $null
reg add HKCR\ms-gamebar /f /v "URL Protocol" /d "" *> $null
reg add HKCR\ms-gamebar /f /v "NoOpenWith" /d "" *> $null
reg add HKCR\ms-gamebar\shell\open\command /f /ve /d "\`"$env:SystemRoot\System32\systray.exe\`"" *> $null
reg add HKCR\ms-gamebarservices /f /ve /d URL:ms-gamebarservices *> $null
reg add HKCR\ms-gamebarservices /f /v "URL Protocol" /d "" *> $null
reg add HKCR\ms-gamebarservices /f /v "NoOpenWith" /d "" *> $null
reg add HKCR\ms-gamebarservices\shell\open\command /f /ve /d "\`"$env:SystemRoot\System32\systray.exe\`"" *> $null

Pause
