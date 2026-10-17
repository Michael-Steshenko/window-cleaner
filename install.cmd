:: This script:
:: 1. Installs keyboard-manager.ahk to startup folder by creating a symbolink link
:: 2. Creates a config.ini file for the AutoHotkey scripts
:: 3. Installs agyStatusline.py to ~/.gemini/antigravity-cli/ via symbolic link
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
echo.
echo Setting up Antigravity CLI statusline...
if not exist "%AGY_DIR%" mkdir "%AGY_DIR%"

if exist "%AGY_LINK%" (
    echo Existing agyStatusline.py found, updating symlink...
    del /f /q "%AGY_LINK%" >nul 2>&1
)

mklink "%AGY_LINK%" "%AGY_TARGET%" >nul
if %errorLevel% equ 0 (
    echo Antigravity statusline symlink created: %AGY_LINK% -^> %AGY_TARGET%
) else (
    echo Warning: Failed to create agyStatusline.py symlink.
)

echo.
echo Success
pause

