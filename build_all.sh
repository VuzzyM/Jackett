#!/bin/bash

# Directory where final archives will be saved
DIR="jackett_binaries"
mkdir -p "$DIR"

# Function to compile and archive with an internal "Jackett" folder
build_jackett() {
    FILE=$1
    RID=$2
    
    echo "------------------------------------------------"
    echo "Building $FILE (RID: $RID)..."
    
    # 1. Clean start for the temp directory
    rm -rf "./temp_build"
    mkdir -p "./temp_build/Jackett"
    
    # 2. Publish Main Components
    # Jackett.Common and Jackett.Service are automatically included as dependencies
    echo "Compiling Server (Core)..."
    dotnet publish src/Jackett.Server -f net9.0 -c Release -r "$RID" --self-contained -o "./temp_build/Jackett"
    
    echo "Compiling Updater..."
    dotnet publish src/Jackett.Updater -f net9.0 -c Release -r "$RID" --self-contained -o "./temp_build/Jackett"

    # 3. Add Support Scripts based on Platform
    if [[ $RID == win* ]]; then
        # Windows-specific files
        [ -f "jackett_launcher.bat" ] && cp jackett_launcher.bat "./temp_build/Jackett/"
    
    elif [[ $RID == osx* ]]; then
        # macOS-specific files (launchd)
        [ -f "jackett_launcher.sh" ] && cp jackett_launcher.sh "./temp_build/Jackett/"
        [ -f "install_service_macos" ] && cp install_service_macos "./temp_build/Jackett/"
        [ -f "uninstall_jackett_macos" ] && cp uninstall_jackett_macos "./temp_build/Jackett/"
        [ -f "uninstall_service_macos" ] && cp uninstall_service_macos "./temp_build/Jackett/" 2>/dev/null
    
    else
        # Linux-specific files (systemd)
        [ -f "jackett_launcher.sh" ] && cp jackett_launcher.sh "./temp_build/Jackett/"
        [ -f "install_service_systemd.sh" ] && cp install_service_systemd.sh "./temp_build/Jackett/"
        [ -f "uninstall_service_systemd.sh" ] && cp uninstall_service_systemd.sh "./temp_build/Jackett/"
    fi

    # 4. Copy General Metadata
    [ -f "LICENSE" ] && cp LICENSE "./temp_build/Jackett/"
    [ -f "README.md" ] && cp README.md "./temp_build/Jackett/"
    
    # 5. Set permissions for scripts (Linux and macOS)
    if [[ $RID != win* ]]; then
        chmod +x ./temp_build/Jackett/*.sh 2>/dev/null
        chmod +x ./temp_build/Jackett/install_service_macos 2>/dev/null
        chmod +x ./temp_build/Jackett/uninstall_jackett_macos 2>/dev/null
    fi
    
    # 6. Archive the build
    if [[ $FILE == *.zip ]]; then
        (cd ./temp_build && zip -r -q "../$DIR/$FILE" "Jackett")
    else
        tar -czf "./$DIR/$FILE" -C "./temp_build" "Jackett"
    fi
    
    # 7. Cleanup
    rm -rf "./temp_build"
}

# --- Execution List ---

# Linux Standard Builds
build_jackett "Jackett.Binaries.LinuxAMDx64.tar.gz" "linux-x64"
build_jackett "Jackett.Binaries.LinuxARM32.tar.gz" "linux-arm"
build_jackett "Jackett.Binaries.LinuxARM64.tar.gz" "linux-arm64"

# Linux Musl Builds (for Alpine, etc.)
build_jackett "Jackett.Binaries.LinuxMuslAMDx64.tar.gz" "linux-musl-x64"
build_jackett "Jackett.Binaries.LinuxMuslARM32.tar.gz" "linux-musl-arm"
build_jackett "Jackett.Binaries.LinuxMuslARM64.tar.gz" "linux-musl-arm64"

# macOS Builds
build_jackett "Jackett.Binaries.macOS.tar.gz" "osx-x64"
build_jackett "Jackett.Binaries.macOSARM64.tar.gz" "osx-arm64"

# Windows Build
build_jackett "Jackett.Binaries.Windows.zip" "win-x64"

echo "------------------------------------------------"
echo "Done! All builds. Check: $DIR"
