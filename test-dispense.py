#!/usr/bin/env python3
"""
Test script to simulate dispense commands
"""
import json
import os
import time
from datetime import datetime
from pathlib import Path

DISPENSE_DIR = 'dispense_commands'

def setup_directories():
    """Create necessary directories"""
    Path(DISPENSE_DIR).mkdir(exist_ok=True)
    print(f"📁 Dispense directory: {os.path.abspath(DISPENSE_DIR)}")

def create_dispense_command(product_type):
    """Create a test dispense command"""
    command_id = str(int(time.time() * 1000))
    filename = f"{DISPENSE_DIR}/dispense_{command_id}.json"
    
    command_data = {
        'command_id': command_id,
        'product_type': product_type,
        'timestamp': datetime.now().isoformat(),
        'status': 'pending'
    }
    
    # Write to temporary file first, then rename (atomic operation)
    temp_file = f"{filename}.tmp"
    with open(temp_file, 'w') as f:
        json.dump(command_data, f, indent=2)
    
    # Atomic rename
    os.rename(temp_file, filename)
    print(f"📝 Created dispense command: {filename}")
    print(f"🎯 Product: {product_type}")

def list_commands():
    """List all pending commands"""
    try:
        files = list(Path(DISPENSE_DIR).glob("dispense_*.json"))
        if not files:
            print("📄 No pending dispense commands")
            return
            
        print(f"📄 Found {len(files)} pending commands:")
        for file_path in files:
            try:
                with open(file_path, 'r') as f:
                    data = json.load(f)
                print(f"  - {file_path.name}: {data.get('product_type')} ({data.get('status')})")
            except Exception as e:
                print(f"  - {file_path.name}: Error reading file ({e})")
                
    except Exception as e:
        print(f"❌ Error listing commands: {e}")

def main():
    print("🧪 Dispense command simulator")
    print("📍 Working directory:", os.getcwd())
    
    setup_directories()
    
    print("\n📋 Available commands:")
    print("  1 - Dispense pad")
    print("  2 - Dispense tampon")
    print("  3 - List pending commands")
    print("  q - Quit")
    
    try:
        while True:
            cmd = input("\n🎮 Enter command: ").strip().lower()
            
            if cmd == '1':
                create_dispense_command('pad')
            elif cmd == '2':
                create_dispense_command('tampon')
            elif cmd == '3':
                list_commands()
            elif cmd == 'q':
                break
            else:
                print("❌ Unknown command")
                
    except KeyboardInterrupt:
        print("\n🛑 Stopping simulator...")

if __name__ == '__main__':
    main()