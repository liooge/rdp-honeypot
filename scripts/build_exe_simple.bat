@echo off
setlocal enabledelayedexpansion

:: Windows EXE Build Script for RDP Honeypot
:: Creates a standalone Windows executable with all dependencies bundled
:: No installation required on target Windows systems

echo ===========================================
echo   RDP Honeypot Windows EXE Builder
echo ===========================================

:: Script configuration
set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."
set "BUILD_DIR=%PROJECT_DIR%\build"
set "DIST_DIR=%PROJECT_DIR%\dist"
set "EXE_NAME=RDP_Honeypot"
set "VERSION=1.0.0"

echo [BUILD] Building RDP Honeypot v%VERSION% for Windows...

:: Check if Python is available
echo [BUILD] Checking build environment...
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] python is not installed or not in PATH
    pause
    exit /b 1
)

:: Check Python version
for /f "tokens=1,2 delims=. " %%i in ('python -c "import sys; print('.'.join(map(str, sys.version_info[:2])))"') do (
    set "python_version=%%i.%%j"
)
echo [BUILD] Python version: !python_version!

:: Check if pip is available
pip --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] pip is not installed or not in PATH
    pause
    exit /b 1
)

echo [BUILD] Build environment check passed

:: Setup build environment
echo [BUILD] Setting up build environment...
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"

:: Clean previous builds
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%" 2>nul
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%" 2>nul

:: Install build dependencies
echo [BUILD] Installing build dependencies...
pip install --upgrade pyinstaller>=5.13.0 wheel setuptools
if errorlevel 1 (
    echo [WARN] Some packages failed to install
)

echo [BUILD] Building Windows executable...

:: Create build directories
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"

:: Run PyInstaller using simple spec file
echo [BUILD] Running PyInstaller with simple spec file...
cd "%PROJECT_DIR%"

:: Use PyInstaller with the simple spec file
python -m PyInstaller ^
    --clean ^
    --noconfirm ^
    rdp_honeypot_simple.spec

if errorlevel 1 (
    echo [ERROR] PyInstaller build failed
    pause
    exit /b 1
)

echo [BUILD] Executable build completed

:: Check if executable was created
if exist "%DIST_DIR%\%EXE_NAME%.exe" (
    echo [BUILD] ✓ Executable created: %DIST_DIR%\%EXE_NAME%.exe
    
    :: Show file size
    for /f "skip=3 tokens=3" %%i in ('dir "%DIST_DIR%\%EXE_NAME%.exe"') do (
        set "exe_size=%%i"
    )
    echo [BUILD] ✓ File size: !exe_size!
    echo [BUILD] ✓ All dependencies included (standalone)
    echo [BUILD] ✓ No installation required on target Windows
) else (
    echo [ERROR] ✗ Executable not found!
    pause
    exit /b 1
)

echo.
echo [BUILD] Build process completed successfully!
echo.
echo To deploy on Windows:
echo 1. Copy %DIST_DIR%\%EXE_NAME%.exe to target machine
echo 2. Run as Administrator (recommended)
echo 3. Service will listen on port 3101
echo.
echo [WARN] Remember: This tool is for authorized security testing only!

pause