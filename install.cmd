:: This script:
:: 1. Installs keyboard-manager.ahk to startup folder by creating a symbolic link
:: 2. Creates a config.ini file for the AutoHotkey scripts
:: 3. Installs agyStatusline.py to ~/.gemini/antigravity-cli/ via symbolic link
:: 4. Installs .wezterm.lua to ~/.wezterm.lua via symbolic link
:: 5. Installs Microsoft.PowerShell_profile.ps1 to ~/Documents/PowerShell/ via symbolic link
@echo off
setlocal

:: Define ANSI escape sequence for colors
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"

:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

:: Define paths
set "TARGET=%~dp0keyboard-manager.ahk"
set "STARTUP_DIR=%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup"
set "LINK=%STARTUP_DIR%\keyboard-manager.ahk"
set "CONFIG_FILE=%~dp0config.ini"
set "CONFIG_TEMPLATE=%~dp0config.ini.template"
set "AGY_DIR=%USERPROFILE%\.gemini\antigravity-cli"
set "AGY_TARGET=%~dp0agyStatusline.py"
set "AGY_LINK=%AGY_DIR%\agyStatusline.py"
set "WEZTERM_TARGET=%~dp0.wezterm.lua"
set "WEZTERM_LINK=%USERPROFILE%\.wezterm.lua"
set "PS_DIR=%USERPROFILE%\Documents\PowerShell"
set "PS_TARGET=%~dp0Microsoft.PowerShell_profile.ps1"
set "PS_LINK=%PS_DIR%\Microsoft.PowerShell_profile.ps1"

:: Create config.ini or verify it exists 
echo.
echo Checking configuration...
if exist "%CONFIG_FILE%" (
    echo Config file already exists.
) else (
    if exist "%CONFIG_TEMPLATE%" (
        copy "%CONFIG_TEMPLATE%" "%CONFIG_FILE%" >nul
        echo Config file created from template.
    ) else (
        echo %ESC%[93mWarning: Template config file not found.%ESC%[0m
    )
)
echo.

:: Create symlinks
set "ERRORS=0"
call :CreateSymlink "%TARGET%" "%LINK%"
call :CreateSymlink "%AGY_TARGET%" "%AGY_LINK%"
call :CreateSymlink "%WEZTERM_TARGET%" "%WEZTERM_LINK%"
call :CreateSymlink "%PS_TARGET%" "%PS_LINK%"

echo.
if %ERRORS% gtr 0 (
    echo Installation finished with errors.
) else (
    echo Success
)
pause
exit /b 0

:: Helper function to create a symlink with directory creation and collision check
:CreateSymlink
set "SRC=%~1"
set "DST=%~2"
set "DST_DIR=%~dp2"

if not exist "%DST_DIR%" mkdir "%DST_DIR%"
echo Creating link at: %DST%

:: Check if link or file already exists
if exist "%DST%" (
    echo %ESC%[93mWarning: A file or link already exists at %DST%.%ESC%[0m
    exit /b 0
)

:: Create the symbolic link
mklink "%DST%" "%SRC%" >nul
if %errorLevel% neq 0 (
    echo Error: Failed to create symlink at %DST%.
    set /a ERRORS+=1
    exit /b 1
)
exit /b 0
