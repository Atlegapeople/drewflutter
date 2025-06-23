# D.R.E.W. Vending Machine Startup Guide

## Quick Start

### Option 1: Batch Script (Simple)
Double-click `start_vending_machine.bat` to start both services.

### Option 2: PowerShell Script (Advanced)
Right-click `start_vending_machine.ps1` → "Run with PowerShell"

## What the Scripts Do

The startup scripts will:

1. **Start RFID Card Reader Service** (`card-reader-file.py`)
   - Connects to RFID reader on COM7
   - Writes card scans to `card_scans/` directory
   - Updates status in `card_reader_status.json`

2. **Start Flutter Vending Machine App**
   - Launches the main UI application
   - Reads card scans from file system
   - Manages inventory and dispensing

## Prerequisites

- **Python 3.x** installed and in PATH
- **Flutter SDK** installed and in PATH
- **RFID reader** connected to COM7 (or update port in script)
- **Windows** with appropriate permissions

## Configuration

### RFID Reader Port
If your RFID reader is on a different port, edit `card-reader-file.py`:
```python
SERIAL_PORT = 'COM7'  # Change this to your port
```

### Flutter Build Mode
Scripts use `--release` mode for best performance. For development:
- Edit scripts and change `--release` to `--debug`

## Stopping Services

### Using Stop Script
Run `stop_vending_machine.ps1` to stop all services.

### Manual Stop
- Close the command windows that opened
- Or use Task Manager to end processes

## Troubleshooting

### Python Not Found
```
[ERROR] Python not found. Please install Python and add it to PATH.
```
**Solution:** Install Python from python.org and ensure it's in your PATH.

### Flutter Not Found
```
[ERROR] Flutter not found. Please install Flutter and add it to PATH.
```
**Solution:** Install Flutter SDK and add to your PATH.

### RFID Reader Connection Issues
```
Error: could not open port 'COM7'
```
**Solutions:**
1. Check Device Manager for correct COM port
2. Ensure RFID reader is connected
3. Update `SERIAL_PORT` in `card-reader-file.py`
4. Check if another program is using the port

### Permission Issues
**Solution:** Run PowerShell as Administrator:
1. Right-click PowerShell
2. Select "Run as Administrator"
3. Run the startup script

## File Structure

```
drew_vending_machine/
├── start_vending_machine.bat    # Simple startup script
├── start_vending_machine.ps1    # Advanced startup script
├── stop_vending_machine.ps1     # Stop all services
├── card-reader-file.py           # RFID service
├── card_scans/                   # Card scan data
├── dispense_commands/            # Dispense commands
└── lib/                          # Flutter app source
```

## Automatic Startup (Optional)

To start the vending machine automatically on boot:

1. **Windows Startup Folder:**
   - Press `Win+R`, type `shell:startup`
   - Copy `start_vending_machine.bat` to this folder

2. **Windows Service:**
   - Use tools like NSSM to convert scripts to services
   - More advanced but provides better control

## Support

If you encounter issues:
1. Check the console output for error messages
2. Verify all prerequisites are installed
3. Test individual components separately
4. Check file permissions and paths

---

**D.R.E.W. - Dignity • Respect • Empowerment for Women**