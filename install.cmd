:: This script:
:: 1. Installs keyboard-manager.ahk to startup folder by creating a symbolic link
:: 2. Creates a config.ini file for the AutoHotkey scripts
:: 3. Installs agyStatusline.py to ~/.gemini/antigravity-cli/ via symbolic link
:: 4. Installs .wezterm.lua to ~/.wezterm.lua via symbolic link
:: 5. Installs Microsoft.PowerShell_profile.ps1 to ~/Documents/PowerShell/ via symbolic link
@echo off
setlocal

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

:: Create cofig.ini or verify it exists 
echo.
echo Checking configuration...
if exist "%CONFIG_FILE%" (
    echo Config file already exists.
) else (
    if exist "%CONFIG_TEMPLATE%" (
        copy "%CONFIG_TEMPLATE%" "%CONFIG_FILE%" >nul
        echo Config file created from template.
    ) else (
        echo Warning: Template config file not found.
    )
)
echo.

:: Create keyboard-manager.ahk symlink in statup apps folder
echo Creating link at: %LINK%

:: Check if link or file already exists
if exist "%LINK%" (
    echo Error: A file or link already exists at %LINK%.
    echo Please remove it first.
    pause
    exit /b 1
)

:: Create the symbolic link
mklink "%LINK%" "%TARGET%" >nul
if %errorLevel% neq 0 (
    echo Failed to create symlink.
    pause
    exit /b 1
)

:: Create agyStatusline.py symlink in Antigravity CLI config folder
if not exist "%AGY_DIR%" mkdir "%AGY_DIR%"
echo Creating link at: %AGY_LINK%

:: Check if link or file already exists
if exist "%AGY_LINK%" (
    echo Error: A file or link already exists at %AGY_LINK%.
    echo Please remove it first.
    pause
    exit /b 1
)

:: Create the symbolic link
mklink "%AGY_LINK%" "%AGY_TARGET%" >nul
if %errorLevel% neq 0 (
    echo Failed to create symlink.
    pause
    exit /b 1
)

:: Create .wezterm.lua symlink in user profile folder
echo Creating link at: %WEZTERM_LINK%

:: Check if link or file already exists
if exist "%WEZTERM_LINK%" (
    echo Error: A file or link already exists at %WEZTERM_LINK%.
    echo Please remove it first.
    pause
    exit /b 1
)

:: Create the symbolic link
mklink "%WEZTERM_LINK%" "%WEZTERM_TARGET%" >nul
if %errorLevel% neq 0 (
    echo Failed to create symlink.
    pause
    exit /b 1
)

:: Create Microsoft.PowerShell_profile.ps1 symlink in PowerShell folder
if not exist "%PS_DIR%" mkdir "%PS_DIR%"
echo Creating link at: %PS_LINK%

:: Check if link or file already exists
if exist "%PS_LINK%" (
    echo Error: A file or link already exists at %PS_LINK%.
    echo Please remove it first.
    pause
    exit /b 1
)

:: Create the symbolic link
mklink "%PS_LINK%" "%PS_TARGET%" >nul
if %errorLevel% neq 0 (
    echo Failed to create symlink.
    pause
    exit /b 1
)

echo.
echo Success
pause

