#!/usr/bin/env python3
"""
File-based card reader for Flutter vending machine
Writes card scans to JSON files that Flutter can read
"""
import json
import os
import serial
import time
import uuid
from datetime import datetime
from pathlib import Path

# Configuration
SERIAL_PORT = '/dev/ttyUSB0'
BAUD_RATE = 9600
CARD_DIR = 'card_scans'
DISPENSE_DIR = 'dispense_commands'
STATUS_FILE = 'card_reader_status.json'

def setup_directories():
    """Create necessary directories"""
    Path(CARD_DIR).mkdir(exist_ok=True)
    Path(DISPENSE_DIR).mkdir(exist_ok=True)
    print(f"📁 Card scan directory: {os.path.abspath(CARD_DIR)}")
    print(f"📁 Dispense directory: {os.path.abspath(DISPENSE_DIR)}")

def write_status(status, message=""):
    """Write reader status to file"""
    status_data = {
        'status': status,  # 'starting', 'running', 'error', 'stopped'
        'message': message,
        'timestamp': datetime.now().isoformat(),
        'serial_port': SERIAL_PORT
    }
    
    try:
        with open(STATUS_FILE, 'w') as f:
            json.dump(status_data, f, indent=2)
    except Exception as e:
        print(f"❌ Failed to write status: {e}")

def write_card_scan(card_uid):
    """Write card scan to unique file"""
    scan_id = str(uuid.uuid4())[:8]
    filename = f"{CARD_DIR}/card_{scan_id}.json"
    
    card_data = {
        'card_uid': card_uid,
        'timestamp': datetime.now().isoformat(),
        'scan_id': scan_id,
        'status': 'new'
    }
    
    try:
        # Write to temporary file first, then rename (atomic operation)
        temp_file = f"{filename}.tmp"
        with open(temp_file, 'w') as f:
            json.dump(card_data, f, indent=2)
        
        # Atomic rename
        os.rename(temp_file, filename)
        print(f"💳 Card scan written: {filename}")
        return True
        
    except Exception as e:
        print(f"❌ Failed to write card scan: {e}")
        return False

def check_dispense_commands(ser):
    """Check for dispense command files and execute them"""
    try:
        dispense_dir = Path(DISPENSE_DIR)
        
        for file_path in dispense_dir.glob("dispense_*.json"):
            try:
                with open(file_path, 'r') as f:
                    cmd_data = json.load(f)
                
                product_type = cmd_data.get('product_type')
                cmd_id = cmd_data.get('command_id')
                
                if product_type in ['pad', 'tampon']:
                    print(f"🎯 Dispensing {product_type} (ID: {cmd_id})")
                    
                    # Send command to firmware
                    command = f"DISPENSE:{product_type}\n"
                    ser.write(command.encode())
                    print(f"📤 Sent: {command.strip()}")
                    
                    # Wait 5 seconds for motor to complete cycle
                    print(f"⏳ Waiting 5 seconds for {product_type} motor to complete...")
                    time.sleep(5)
                    
                    # Delete the command file after motor completes
                    file_path.unlink()
                    print(f"✅ Motor cycle complete, deleted command: {file_path.name}")
                        
                else:
                    print(f"❌ Invalid product type: {product_type}")
                    file_path.unlink()  # Delete invalid command
                    
            except Exception as e:
                print(f"❌ Error processing dispense command {file_path}: {e}")
                file_path.unlink()  # Delete corrupted file
                
    except Exception as e:
        print(f"❌ Error checking dispense commands: {e}")

def cleanup_old_files():
    """Remove processed files older than 1 minute"""
    try:
        current_time = time.time()
        
        # Clean up old card scans (extended to 2 minutes)
        card_dir = Path(CARD_DIR)
        for file_path in card_dir.glob("card_*.json"):
            if current_time - file_path.stat().st_mtime > 120:
                file_path.unlink()
                print(f"🗑️ Cleaned up old scan: {file_path.name}")
        
        # Clean up old dispense commands (keep for 5 minutes for debugging)
        dispense_dir = Path(DISPENSE_DIR)
        for file_path in dispense_dir.glob("dispense_*.json"):
            if current_time - file_path.stat().st_mtime > 300:  # 5 minutes
                file_path.unlink()
                print(f"🗑️ Cleaned up old dispense: {file_path.name}")
                
    except Exception as e:
        print(f"❌ Cleanup error: {e}")

def main():
    print("🚀 Starting file-based card reader...")
    print(f"📍 Working directory: {os.getcwd()}")
    
    setup_directories()
    write_status('starting', 'Initializing card reader')
    
    try:
        print(f"🔌 Opening serial port {SERIAL_PORT}...")
        with serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1) as ser:
            print(f"✅ Serial port {SERIAL_PORT} opened successfully")
            write_status('running', f'Connected to {SERIAL_PORT}')
            
            last_cleanup = time.time()
            last_dispense_check = time.time()
            
            while True:
                try:
                    # Check for dispense commands every 100ms
                    current_time = time.time()
                    if current_time - last_dispense_check > 0.1:
                        check_dispense_commands(ser)
                        last_dispense_check = current_time
                    
                    # Read from serial
                    raw = ser.readline()
                    
                    if raw:
                        try:
                            line = raw.decode('utf-8', errors='ignore').strip()
                            if line:
                                print(f"📡 Received: {line}")
                                
                                if line.startswith('CARDUID:'):
                                    card_uid = line.replace('CARDUID:', '').strip()
                                    if card_uid:
                                        print(f"💳 Card UID: {card_uid}")
                                        write_card_scan(card_uid)
                                        
                                elif line.startswith('SYSTEM:'):
                                    print(f"🔧 System message: {line}")
                                    
                                elif line.startswith('DISPENSING:'):
                                    product = line.replace('DISPENSING:', '').strip()
                                    print(f"🎯 Firmware dispensing: {product}")
                                    
                                elif line.startswith('COMPLETE:'):
                                    product = line.replace('COMPLETE:', '').strip()
                                    print(f"✅ Dispensing complete: {product}")
                                    
                                elif line.startswith('ERROR:'):
                                    error = line.replace('ERROR:', '').strip()
                                    print(f"❌ Firmware error: {error}")
                                    
                        except UnicodeDecodeError as e:
                            print(f"❌ Decode error: {e}")
                            print(f"Raw bytes: {raw}")
                    
                    # Periodic cleanup (every 30 seconds)
                    if current_time - last_cleanup > 30:
                        cleanup_old_files()
                        last_cleanup = current_time
                        
                except serial.SerialException as e:
                    print(f"❌ Serial error: {e}")
                    write_status('error', f'Serial error: {e}')
                    break
                    
                except KeyboardInterrupt:
                    print("\n🛑 Stopping card reader...")
                    break
                    
                except Exception as e:
                    print(f"❌ Unexpected error: {e}")
                    write_status('error', f'Unexpected error: {e}')
                    time.sleep(1)  # Brief pause before continuing
                    
    except serial.SerialException as e:
        error_msg = f"Failed to open {SERIAL_PORT}: {e}"
        print(f"❌ {error_msg}")
        write_status('error', error_msg)
        
    except Exception as e:
        error_msg = f"Startup error: {e}"
        print(f"❌ {error_msg}")
        write_status('error', error_msg)
        
    finally:
        write_status('stopped', 'Card reader stopped')
        print("🔌 Card reader stopped")

if __name__ == '__main__':
    main()