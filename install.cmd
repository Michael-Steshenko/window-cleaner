:: Installs keyboard-manager.ahk to startup folder by creating a symbolink link

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

echo.
echo Success
pause
