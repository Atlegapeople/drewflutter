#!/usr/bin/env powershell
<#
.SYNOPSIS
    D.R.E.W. Vending Machine Stop Script
.DESCRIPTION
    Stops all running vending machine services
#>

Write-Host "===================================" -ForegroundColor Red
Write-Host "  D.R.E.W. Vending Machine Shutdown" -ForegroundColor Red
Write-Host "===================================" -ForegroundColor Red
Write-Host ""

# Find and stop Python card reader processes
$pythonProcesses = Get-Process | Where-Object { $_.ProcessName -eq "python" -and $_.CommandLine -like "*card-reader*" }
if ($pythonProcesses) {
    Write-Host "[INFO] Stopping RFID Card Reader services..." -ForegroundColor Cyan
    foreach ($process in $pythonProcesses) {
        Stop-Process -Id $process.Id -Force
        Write-Host "[SUCCESS] Stopped RFID service (PID: $($process.Id))" -ForegroundColor Green
    }
} else {
    Write-Host "[INFO] No RFID Card Reader services found" -ForegroundColor Yellow
}

# Find and stop Flutter processes
$flutterProcesses = Get-Process | Where-Object { $_.ProcessName -eq "flutter" -or $_.ProcessName -eq "drew_vending_machine" }
if ($flutterProcesses) {
    Write-Host "[INFO] Stopping Flutter application..." -ForegroundColor Cyan
    foreach ($process in $flutterProcesses) {
        Stop-Process -Id $process.Id -Force
        Write-Host "[SUCCESS] Stopped Flutter app (PID: $($process.Id))" -ForegroundColor Green
    }
} else {
    Write-Host "[INFO] No Flutter applications found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[SUCCESS] All vending machine services stopped" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to exit"