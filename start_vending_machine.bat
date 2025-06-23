@echo off
echo ===================================
echo   D.R.E.W. Vending Machine Startup
echo   Dignity • Respect • Empowerment for Women
echo ===================================
echo.

REM Change to the application directory
cd /d "%~dp0"

echo [INFO] Starting RFID Card Reader Service...
start "RFID Card Reader" cmd /k "python card-reader-file.py"

echo [INFO] Waiting 3 seconds for RFID service to initialize...
timeout /t 3 /nobreak > nul

echo [INFO] Starting Flutter Vending Machine Application...
start "Flutter Vending Machine" cmd /k "flutter run -d windows --release"

echo.
echo [SUCCESS] Both services started!
echo.
echo Services running:
echo   - RFID Card Reader (File-based)
echo   - Flutter Vending Machine App
echo.
echo Press any key to exit this startup script...
echo (Note: Services will continue running in separate windows)
pause > nul