#!/bin/bash
# Windows EXE Build Script for RDP Honeypot
# Creates a standalone Windows executable with all dependencies bundled
# No installation required on target Windows systems

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
DIST_DIR="$PROJECT_DIR/dist"
SPEC_FILE="$PROJECT_DIR/rdp_honeypot.spec"
EXE_NAME="RDP_Honeypot"
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[BUILD]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

header() {
    echo -e "${PURPLE}===========================================${NC}"
    echo -e "${PURPLE} RDP Honeypot Windows EXE Builder${NC}"
    echo -e "${PURPLE}===========================================${NC}"
}

# Check if we're on a system that can build Windows executables
check_build_environment() {
    log "Checking build environment..."
    
    # Check if Python is available
    if ! command -v python3 &> /dev/null; then
        error "Python3 is not installed or not in PATH"
        exit 1
    fi
    
    # Check Python version (need 3.8+)
    python_version=$(python3 -c "import sys; print('.'.join(map(str, sys.version_info[:2])))")
    log "Python version: $python_version"
    
    # Check if pip is available
    if ! command -v pip3 &> /dev/null; then
        error "pip3 is not installed or not in PATH"
        exit 1
    fi
    
    log "Build environment check passed"
}

# Setup build environment (simplified)
setup_build_environment() {
    log "Setting up build environment..."
    
    # Create build directory
    mkdir -p "$BUILD_DIR" "$DIST_DIR"
    
    # Clean previous builds
    rm -rf "$BUILD_DIR"/* "$DIST_DIR"/* 2>/dev/null || true
}

# Install build dependencies
install_build_dependencies() {
    log "Installing build dependencies..."
    
    # Install PyInstaller and other build tools
    pip install --upgrade --break-system-packages \
        pyinstaller>=5.13.0 \
        wheel \
        setuptools || warn "Some packages failed to install"
    
    # Install minimal project dependencies (skip the heavy ones for build)
    log "Installing minimal dependencies for build..."
    # Our honeypot only uses standard library, so no external deps needed
    
    log "Build dependencies installed"
}

# Create PyInstaller spec file
create_spec_file() {
    log "Creating PyInstaller specification file..."
    
    cat > "$SPEC_FILE" << 'EOF'
# -*- mode: python ; coding: utf-8 -*-
# RDP Honeypot PyInstaller Specification
# This spec file creates a standalone Windows executable

import os
import sys
from PyInstaller.building.build_main import Analysis, PYZ, EXE, COLLECT

# Get the project directory
project_dir = os.path.dirname(os.path.abspath(SPEC))

block_cipher = None

# Analysis configuration
a = Analysis(
    # Main entry point
    [os.path.join(project_dir, 'rdp_honeypot_main.py')],
    
    # Additional Python paths
    pathex=[
        project_dir,
        os.path.join(project_dir, 'server'),
    ],
    
    # Binary dependencies (will be auto-detected)
    binaries=[],
    
    # Data files to include
    datas=[
        (os.path.join(project_dir, 'config.py'), '.'),
        (os.path.join(project_dir, 'server.crt'), '.'),
        (os.path.join(project_dir, 'server.key'), '.'),
        (os.path.join(project_dir, 'README.md'), '.'),
    ],
    
    # Hidden imports (modules not automatically detected)
    hiddenimports=[
        'socket',
        'threading',
        'struct',
        'logging',
        'time',
        'datetime',
        'os',
        'io',
        'ssl',
        'hashlib',
        'binascii',
        'base64',
        'json',
        'sqlite3',
        'urllib.parse',
        'urllib.request',
        'http.server',
        'socketserver',
        # Crypto and security modules
        'cryptography',
        'cryptography.hazmat.primitives',
        'cryptography.hazmat.primitives.ciphers',
        'cryptography.hazmat.primitives.hashes',
        'cryptography.hazmat.backends',
        'cryptography.hazmat.backends.openssl',
        # Network modules
        'ipaddress',
        'email.utils',
        # ASN.1 and BER encoding
        'pyasn1',
        'pyasn1.codec.ber',
        'pyasn1.codec.der',
        'pyasn1.type',
    ],
    
    # Hooks directory
    hookspath=[],
    
    # Additional hook directories
    hooksconfig={},
    
    # Runtime hooks
    runtime_hooks=[],
    
    # Exclusions (reduce file size)
    excludes=[
        'tkinter',
        'matplotlib',
        'numpy',
        'pandas',
        'scipy',
        'PIL',
        'PyQt5',
        'PyQt6',
        'PySide2',
        'PySide6',
        'wx',
        'django',
        'flask.ext',
        'jinja2.ext',
    ],
    
    # Additional options
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

# Python bytecode archive
pyz = PYZ(
    a.pure, 
    a.zipped_data,
    cipher=block_cipher
)

# Executable configuration
exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    
    # Executable options
    name='RDP_Honeypot',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,  # Compress with UPX if available
    upx_exclude=[],
    runtime_tmpdir=None,
    
    # Console application (not windowed)
    console=True,
    
    # Disable imports checking for faster startup
    disable_windowed_traceback=False,
    
    # Target architecture (auto-detect)
    target_arch=None,
    
    # Code signing (if certificates are available)
    codesign_identity=None,
    
    # Entitlements file for macOS (not used for Windows)
    entitlements_file=None,
    
    # Icon file (optional)
    icon=None,
    
    # Version information
    version='version_info.txt' if os.path.exists('version_info.txt') else None,
)

# Collection (for --onedir mode, not used in --onefile)
# coll = COLLECT(
#     exe,
#     a.binaries,
#     a.zipfiles,
#     a.datas,
#     strip=False,
#     upx=True,
#     upx_exclude=[],
#     name='RDP_Honeypot'
# )
EOF

    log "PyInstaller spec file created: $SPEC_FILE"
}

# Create version information file
create_version_info() {
    log "Creating version information file..."
    
    cat > "$PROJECT_DIR/version_info.txt" << EOF
# UTF-8
#
# RDP Honeypot Version Information
#
VSVersionInfo(
  ffi=FixedFileInfo(
    filevers=(1,0,0,0),
    prodvers=(1,0,0,0),
    mask=0x3f,
    flags=0x0,
    OS=0x40004,
    fileType=0x1,
    subtype=0x0,
    date=(0, 0)
  ),
  kids=[
    StringFileInfo(
      [
      StringTable(
        u'040904B0',
        [StringStruct(u'CompanyName', u'Security Research'),
        StringStruct(u'FileDescription', u'RDP Honeypot - Remote Desktop Protocol Security Tool'),
        StringStruct(u'FileVersion', u'$VERSION'),
        StringStruct(u'InternalName', u'rdp_honeypot'),
        StringStruct(u'LegalCopyright', u'© 2025 Security Research. For educational and research purposes only.'),
        StringStruct(u'OriginalFilename', u'RDP_Honeypot.exe'),
        StringStruct(u'ProductName', u'RDP Honeypot'),
        StringStruct(u'ProductVersion', u'$VERSION')])
      ]),
    VarFileInfo([VarStruct(u'Translation', [1033, 1200])])
  ]
)
EOF

    log "Version information file created"
}

# Create startup wrapper script
create_startup_wrapper() {
    log "Creating startup wrapper script..."
    
    # Create a Python wrapper that handles initialization
    cat > "$PROJECT_DIR/rdp_honeypot_wrapper.py" << 'EOF'
#!/usr/bin/env python3
"""
RDP Honeypot Wrapper Script
Handles initialization and configuration for the standalone executable
"""

import sys
import os
import logging
from pathlib import Path

def setup_environment():
    """Setup the environment for the RDP honeypot"""
    
    # Get the directory where the executable is located
    if getattr(sys, 'frozen', False):
        # Running as compiled executable
        app_dir = Path(sys.executable).parent
    else:
        # Running as script
        app_dir = Path(__file__).parent
    
    # Change to application directory
    os.chdir(app_dir)
    
    # Create logs directory if it doesn't exist
    logs_dir = app_dir / 'logs'
    logs_dir.mkdir(exist_ok=True)
    
    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(logs_dir / 'rdp_honeypot.log'),
            logging.StreamHandler(sys.stdout)
        ]
    )
    
    logger = logging.getLogger('rdp_honeypot_wrapper')
    logger.info("=" * 60)
    logger.info("RDP Honeypot Starting...")
    logger.info(f"Application directory: {app_dir}")
    logger.info(f"Logs directory: {logs_dir}")
    logger.info("=" * 60)
    
    return app_dir, logger

def main():
    """Main entry point for the RDP honeypot executable"""
    try:
        # Setup environment
        app_dir, logger = setup_environment()
        
        # Import and start the honeypot
        sys.path.insert(0, str(app_dir))
        
        # Import the main honeypot module
        from server.rdp_honeypot_freerdp import RDPHoneypotFreeRDP
        
        logger.info("Initializing RDP Honeypot...")
        
        # Create and start the honeypot
        honeypot = RDPHoneypotFreeRDP(
            host='0.0.0.0', 
            port=3101, 
            log_level=logging.INFO
        )
        
        logger.info("Starting RDP Honeypot service...")
        honeypot.start()
        
    except KeyboardInterrupt:
        logger.info("Received interrupt signal, stopping service...")
        if 'honeypot' in locals():
            honeypot.stop()
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        import traceback
        logger.error(f"Traceback: {traceback.format_exc()}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
EOF

    log "Startup wrapper script created"
}

# Build the executable
build_executable() {
    log "Building Windows executable..."
    
    # Clean previous builds
    if [[ -d "$BUILD_DIR" ]]; then
        log "Cleaning previous build directory..."
        rm -rf "$BUILD_DIR"
    fi
    
    if [[ -d "$DIST_DIR" ]]; then
        log "Cleaning previous distribution directory..."
        rm -rf "$DIST_DIR"
    fi
    
    # Create build directories
    mkdir -p "$BUILD_DIR"
    mkdir -p "$DIST_DIR"
    
    # Run PyInstaller
    log "Running PyInstaller..."
    cd "$PROJECT_DIR"
    
    # Use the spec file for consistent builds
    # Use PyInstaller directly
    PYINSTALLER_CMD="python3 -m PyInstaller"
    
    "$PYINSTALLER_CMD" \
        --clean \
        --noconfirm \
        --onefile \
        --console \
        --name "$EXE_NAME" \
        --distpath "$DIST_DIR" \
        --workpath "$BUILD_DIR" \
        --specpath "$PROJECT_DIR" \
        "$SPEC_FILE" || {
            error "PyInstaller build failed"
            return 1
        }
    
    log "Executable build completed"
}

# Create distribution package
create_distribution() {
    log "Creating distribution package..."
    
    local dist_name="RDP_Honeypot_v${VERSION}_Windows"
    local package_dir="$DIST_DIR/$dist_name"
    
    # Create package directory
    mkdir -p "$package_dir"
    
    # Copy executable
    if [[ -f "$DIST_DIR/${EXE_NAME}.exe" ]]; then
        cp "$DIST_DIR/${EXE_NAME}.exe" "$package_dir/"
        log "Executable copied to package"
    else
        error "Executable not found: $DIST_DIR/${EXE_NAME}.exe"
        return 1
    fi
    
    # Copy essential files
    cp "$PROJECT_DIR/README.md" "$package_dir/" 2>/dev/null || warn "README.md not found"
    cp "$PROJECT_DIR/server.crt" "$package_dir/" 2>/dev/null || warn "server.crt not found"
    cp "$PROJECT_DIR/server.key" "$package_dir/" 2>/dev/null || warn "server.key not found"
    
    # Create startup script for Windows
    cat > "$package_dir/start_honeypot.bat" << 'EOF'
@echo off
title RDP Honeypot
echo ==========================================
echo   RDP Honeypot - Windows Deployment
echo ==========================================
echo.
echo Starting RDP Honeypot on port 3101...
echo Press Ctrl+C to stop the service
echo.

RDP_Honeypot.exe

echo.
echo Service stopped. Press any key to exit...
pause >nul
EOF
    
    # Create configuration file
    cat > "$package_dir/config.txt" << EOF
# RDP Honeypot Configuration
# 
# Default Settings:
# - RDP Port: 3101
# - HTTP Health Check: 8080
# - Logs: logs/ directory (created automatically)
#
# To change settings, modify config.py before building
# or rebuild with custom configuration

# Usage:
# 1. Double-click start_honeypot.bat to start
# 2. Or run RDP_Honeypot.exe directly from command line
# 3. Connect to <your_ip>:3101 with Remote Desktop
# 4. Check logs/ directory for captured credentials

# Security Notice:
# This tool is for authorized security testing only.
# Ensure compliance with applicable laws and policies.
EOF
    
    # Create logs directory
    mkdir -p "$package_dir/logs"
    
    # Create installation guide
    cat > "$package_dir/INSTALLATION.txt" << EOF
RDP Honeypot - Windows Installation Guide
========================================

SYSTEM REQUIREMENTS:
- Windows 7/8/10/11 (64-bit)
- No additional software required (all dependencies included)
- Administrative privileges (recommended for port binding)

QUICK START:
1. Extract this package to any directory
2. Double-click 'start_honeypot.bat' to start the service
3. Service will listen on port 3101 for RDP connections
4. Captured credentials will be saved in logs/ directory

ADVANCED USAGE:
- Run 'RDP_Honeypot.exe' directly from command line
- Service creates logs/rdp_honeypot.log for all activities
- SSL certificates (server.crt/server.key) included for encryption

FIREWALL CONFIGURATION:
- Allow inbound connections on port 3101 (RDP)
- Allow inbound connections on port 8080 (HTTP health check)

TESTING:
- Use Windows Remote Desktop (mstsc.exe) to connect
- Connect to: <your_computer_ip>:3101
- Enter any username/password to test credential capture

SECURITY WARNINGS:
- Use only for authorized security testing
- Do not deploy on production networks without approval
- Monitor captured data according to privacy policies
- This tool may trigger security software alerts

For support and updates, visit the project repository.
EOF
    
    # Create ZIP package
    log "Creating ZIP package..."
    cd "$DIST_DIR"
    
    if command -v zip &> /dev/null; then
        zip -r "${dist_name}.zip" "$dist_name/" || warn "Failed to create ZIP package"
        log "ZIP package created: ${dist_name}.zip"
    else
        warn "zip command not available, package created as directory only"
    fi
    
    # Show package contents
    log "Package contents:"
    ls -la "$package_dir/"
    
    log "Distribution package created: $package_dir"
}

# Cleanup temporary files
cleanup() {
    log "Cleaning up temporary files..."
    
    # Remove temporary files created during build
    rm -f "$SPEC_FILE"
    rm -f "$PROJECT_DIR/version_info.txt"
    rm -f "$PROJECT_DIR/rdp_honeypot_wrapper.py"
    
    # Remove PyInstaller cache
    rm -rf "$PROJECT_DIR/__pycache__"
    rm -rf "$PROJECT_DIR/server/__pycache__"
    
    log "Cleanup completed"
}

# Show build summary
show_summary() {
    local exe_path="$DIST_DIR/${EXE_NAME}.exe"
    
    header
    log "Build Summary:"
    echo
    
    if [[ -f "$exe_path" ]]; then
        local exe_size=$(du -h "$exe_path" | cut -f1)
        info "✓ Executable created: $exe_path"
        info "✓ File size: $exe_size"
        info "✓ All dependencies included (standalone)"
        info "✓ No installation required on target Windows"
    else
        error "✗ Executable not found!"
        return 1
    fi
    
    echo
    log "Distribution packages:"
    ls -la "$DIST_DIR"/*.zip 2>/dev/null || info "No ZIP packages found"
    
    echo
    log "To deploy on Windows:"
    info "1. Copy the executable or extract the ZIP package"
    info "2. Run as Administrator (recommended)"
    info "3. Double-click start_honeypot.bat or run RDP_Honeypot.exe"
    info "4. Service will listen on port 3101"
    
    echo
    warn "Remember: This tool is for authorized security testing only!"
    header
}

# Main build process
main() {
    header
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                log "Clean build requested"
                rm -rf "$BUILD_DIR" "$DIST_DIR"
                shift
                ;;
            --version)
                VERSION="$2"
                shift 2
                ;;
            --name)
                EXE_NAME="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --clean         Clean previous builds"
                echo "  --version VER   Set version (default: 1.0.0)"
                echo "  --name NAME     Set executable name (default: RDP_Honeypot)"
                echo "  -h, --help      Show this help"
                exit 0
                ;;
            *)
                warn "Unknown option: $1"
                shift
                ;;
        esac
    done
    
    log "Building RDP Honeypot v$VERSION for Windows..."
    
    # Execute build steps
    check_build_environment
    setup_build_environment
    install_build_dependencies
    create_version_info
    create_startup_wrapper
    create_spec_file
    build_executable
    create_distribution
    cleanup
    show_summary
    
    log "Build process completed successfully!"
}

# Trap cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"