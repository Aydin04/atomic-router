# =================================================================
#    ⚡ AtomicRouter Windows 1-Line Automated Installer
#    Usage in PowerShell (Run as Administrator or Normal User):
#    irm https://raw.githubusercontent.com/Aydin04/atomic-router/main/install.ps1 | iex
# =================================================================

$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   ⚡ AtomicRouter | Ultra-Lightweight Universal AI Gateway" -ForegroundColor Cyan
Write-Host "   (Pre-Compiled Standalone Release - Windows 1-Line Installer)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$INSTALL_DIR = "$env:USERPROFILE\.atomic-router"
$REPO = "Aydin04/atomic-router"
$ZIP_URL = "https://github.com/$REPO/releases/latest/download/atomic-router-windows-x64.zip"
$TEMP_ZIP = "$env:TEMP\atomic-router-windows-x64.zip"

# 1. Check & Auto-Install Portable Node.js if missing
Write-Host "[1/4] Checking Node.js runtime..." -ForegroundColor Blue
$hasNode = $false
try {
    $nodeVer = & node -v 2>$null
    if ($nodeVer) {
        Write-Host "[✓] Node.js $nodeVer detected." -ForegroundColor Green
        $hasNode = $true
    }
} catch {}

if (-not $hasNode) {
    Write-Host "[!] Node.js not detected in PATH. Auto-downloading portable Node.js 22 LTS..." -ForegroundColor Yellow
    $NODE_ZIP = "$env:TEMP\node-v22-win-x64.zip"
    $NODE_URL = "https://nodejs.org/dist/v22.22.2/node-v22.22.2-win-x64.zip"
    $NODE_DIR = "$env:USERPROFILE\.nodejs"
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $NODE_URL -OutFile $NODE_ZIP -UseBasicParsing
    Expand-Archive -Path $NODE_ZIP -DestinationPath "$env:TEMP\node_extract" -Force
    
    if (!(Test-Path $NODE_DIR)) {
        New-Item -ItemType Directory -Path $NODE_DIR -Force | Out-Null
    }
    Copy-Item "$env:TEMP\node_extract\node-v22.22.2-win-x64\*" $NODE_DIR -Recurse -Force
    Remove-Item $NODE_ZIP -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\node_extract" -Recurse -Force -ErrorAction SilentlyContinue

    # Add to persistent User PATH and current session
    $oldPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($oldPath -notmatch [regex]::Escape($NODE_DIR)) {
        [System.Environment]::SetEnvironmentVariable("Path", "$oldPath;$NODE_DIR", "User")
    }
    $env:Path = "$env:Path;$NODE_DIR"
    Write-Host "[✓] Portable Node.js v22 installed to $NODE_DIR" -ForegroundColor Green
}

# 2. Create Destination Directory
if (!(Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
}

# 3. Download Release Package
Write-Host "[2/4] Downloading AtomicRouter pre-built standalone package..." -ForegroundColor Blue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try {
    Invoke-WebRequest -Uri $ZIP_URL -OutFile $TEMP_ZIP -UseBasicParsing
    Write-Host "[✓] Download complete." -ForegroundColor Green
} catch {
    Write-Host "[!] Downloading from v3.8.50 tag fallback..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://github.com/$REPO/releases/download/v3.8.50/atomic-router-windows-x64.zip" -OutFile $TEMP_ZIP -UseBasicParsing
    Write-Host "[✓] Download complete." -ForegroundColor Green
}

# 4. Extract Package
Write-Host "[3/4] Extracting package to $INSTALL_DIR..." -ForegroundColor Blue
Expand-Archive -Path $TEMP_ZIP -DestinationPath $INSTALL_DIR -Force
Remove-Item $TEMP_ZIP -Force -ErrorAction SilentlyContinue

# 5. Setup Configuration
if (!(Test-Path "$INSTALL_DIR\.env")) {
    if (Test-Path "$INSTALL_DIR\.env.example") {
        Copy-Item "$INSTALL_DIR\.env.example" "$INSTALL_DIR\.env"
    } else {
        Set-Content -Path "$INSTALL_DIR\.env" -Value "PORT=20128`nINITIAL_PASSWORD=CHANGEME"
    }
}

# 6. Create atomic-router alias / command runner
$CLI_SCRIPT = "$INSTALL_DIR\atomic-router.cmd"
$CLI_CONTENT = @"
@echo off
if "%1"=="update" (
    powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/$REPO/main/install.ps1 | iex"
) else if "%1"=="start" (
    start http://localhost:20128/
    cd /d "$INSTALL_DIR" && node server.js
) else if "%1"=="status" (
    curl -s http://localhost:20128/api/health
) else (
    echo   ⚡ AtomicRouter Windows CLI:
    echo     atomic-router start   - Start gateway server
    echo     atomic-router update  - Update to latest version
    echo     atomic-router status  - Check health
)
"@
Set-Content -Path $CLI_SCRIPT -Value $CLI_CONTENT

# Add INSTALL_DIR to user PATH
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notmatch [regex]::Escape($INSTALL_DIR)) {
    [System.Environment]::SetEnvironmentVariable("Path", "$userPath;$INSTALL_DIR", "User")
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "   🎉 AtomicRouter Successfully Installed!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  🌐 Dashboard URL:    http://localhost:20128/" -ForegroundColor Cyan
Write-Host "  📁 Installed to:     $INSTALL_DIR" -ForegroundColor Cyan
Write-Host "  🔑 Default Key:      sk-atomic-gateway-master" -ForegroundColor Cyan
Write-Host ""
