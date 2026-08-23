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

# 1. Check Node.js
Write-Host "[1/4] Checking Node.js runtime..." -ForegroundColor Blue
try {
    $nodeVer = & node -v 2>$null
    if ($nodeVer) {
        Write-Host "[✓] Node.js $nodeVer detected." -ForegroundColor Green
    } else {
        throw "Node.js not found"
    }
} catch {
    Write-Host "[!] Node.js 20+ LTS is required. Attempting install via winget..." -ForegroundColor Yellow
    try {
        winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements -e
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Host "[✓] Node.js installed successfully." -ForegroundColor Green
    } catch {
        Write-Host "[X] Please install Node.js 20+ from https://nodejs.org/ and run this installer again." -ForegroundColor Red
        return
    }
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

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "   🎉 AtomicRouter Successfully Installed!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  🌐 Dashboard URL:    http://localhost:20128/" -ForegroundColor Cyan
Write-Host "  📁 Installed to:     $INSTALL_DIR" -ForegroundColor Cyan
Write-Host "  🔑 Default Password: CHANGEME" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting AtomicRouter Gateway server..." -ForegroundColor Green
Start-Process "http://localhost:20128/"
Set-Location $INSTALL_DIR
& node server.js
