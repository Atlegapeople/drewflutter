#!/usr/bin/env powershell
<#
.SYNOPSIS
    D.R.E.W. Vending Machine Startup Script
.DESCRIPTION
    Starts the RFID card reader service and Flutter vending machine application
    Dignity • Respect • Empowerment for Women
#>

Write-Host "===================================" -ForegroundColor Magenta
Write-Host "  D.R.E.W. Vending Machine Startup" -ForegroundColor Magenta
Write-Host "  Dignity • Respect • Empowerment for Women" -ForegroundColor Magenta
Write-Host "===================================" -ForegroundColor Magenta
Write-Host ""

# Change to script directory
Set-Location $PSScriptRoot

# Check if Python is available
try {
    $pythonVersion = python --version 2>$null
    Write-Host "[INFO] Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Python not found. Please install Python and add it to PATH." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if Flutter is available
try {
    $flutterVersion = flutter --version 2>$null | Select-String "Flutter"
    Write-Host "[INFO] Flutter found: $($flutterVersion.Line)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Flutter not found. Please install Flutter and add it to PATH." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create directories if they don't exist
$directories = @("card_scans", "dispense_commands")
foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "[INFO] Created directory: $dir" -ForegroundColor Yellow
    }
}

# Start RFID Card Reader Service
Write-Host "[INFO] Starting RFID Card Reader Service..." -ForegroundColor Cyan
$cardReaderJob = Start-Process -FilePath "python" -ArgumentList "card-reader-file.py" -WindowStyle Normal -PassThru
Write-Host "[SUCCESS] RFID Card Reader started (PID: $($cardReaderJob.Id))" -ForegroundColor Green

# Wait for RFID service to initialize
Write-Host "[INFO] Waiting 3 seconds for RFID service to initialize..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

# Start Flutter Application
Write-Host "[INFO] Starting Flutter Vending Machine Application..." -ForegroundColor Cyan
$flutterJob = Start-Process -FilePath "flutter" -ArgumentList "run", "-d", "windows", "--release" -WindowStyle Normal -PassThru
Write-Host "[SUCCESS] Flutter application started (PID: $($flutterJob.Id))" -ForegroundColor Green

Write-Host ""
Write-Host "[SUCCESS] Both services started successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Services running:" -ForegroundColor Yellow
Write-Host "  - RFID Card Reader (PID: $($cardReaderJob.Id))" -ForegroundColor White
Write-Host "  - Flutter Vending Machine App (PID: $($flutterJob.Id))" -ForegroundColor White
Write-Host ""
Write-Host "To stop services:" -ForegroundColor Yellow
Write-Host "  - Close the application windows, or" -ForegroundColor White
Write-Host "  - Run: Stop-Process -Id $($cardReaderJob.Id),$($flutterJob.Id)" -ForegroundColor White
Write-Host ""

# Monitor services
Write-Host "Monitoring services... Press Ctrl+C to stop monitoring (services will continue)" -ForegroundColor Cyan
try {
    while ($true) {
        Start-Sleep -Seconds 10
        
        # Check if processes are still running
        $cardReaderAlive = Get-Process -Id $cardReaderJob.Id -ErrorAction SilentlyContinue
        $flutterAlive = Get-Process -Id $flutterJob.Id -ErrorAction SilentlyContinue
        
        if (-not $cardReaderAlive) {
            Write-Host "[WARNING] RFID Card Reader service stopped" -ForegroundColor Red
        }
        
        if (-not $flutterAlive) {
            Write-Host "[WARNING] Flutter application stopped" -ForegroundColor Red
        }
        
        if (-not $cardReaderAlive -and -not $flutterAlive) {
            Write-Host "[INFO] All services stopped. Exiting monitor." -ForegroundColor Yellow
            break
        }
    }
} catch [System.Management.Automation.PipelineStoppedException] {
    Write-Host ""
    Write-Host "[INFO] Monitoring stopped. Services are still running." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Startup script completed." -ForegroundColor Green