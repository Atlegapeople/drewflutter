#!/usr/bin/env python3
"""
Test script to simulate card scans using file-based communication
"""
import json
import os
import time
import uuid
from datetime import datetime
from pathlib import Path

CARD_DIR = 'card_scans'
STATUS_FILE = 'card_reader_status.json'

def setup_directories():
    """Create necessary directories"""
    Path(CARD_DIR).mkdir(exist_ok=True)
    print(f"📁 Card scan directory: {os.path.abspath(CARD_DIR)}")

def write_status(status, message=""):
    """Write reader status to file"""
    status_data = {
        'status': status,
        'message': message,
        'timestamp': datetime.now().isoformat(),
        'serial_port': 'SIMULATED'
    }
    
    with open(STATUS_FILE, 'w') as f:
        json.dump(status_data, f, indent=2)
    print(f"📊 Status: {status} - {message}")

def simulate_card_scan(card_uid):
    """Simulate a card scan"""
    scan_id = str(uuid.uuid4())[:8]
    filename = f"{CARD_DIR}/card_{scan_id}.json"
    
    card_data = {
        'card_uid': card_uid,
        'timestamp': datetime.now().isoformat(),
        'scan_id': scan_id,
        'status': 'new'
    }
    
    # Write to temporary file first, then rename (atomic operation)
    temp_file = f"{filename}.tmp"
    with open(temp_file, 'w') as f:
        json.dump(card_data, f, indent=2)
    
    # Atomic rename
    os.rename(temp_file, filename)
    print(f"💳 Simulated card scan: {card_uid} -> {filename}")

def main():
    print("🧪 File-based card scan simulator")
    print("📍 Working directory:", os.getcwd())
    
    setup_directories()
    write_status('running', 'Simulator ready')
    
    print("\n📋 Available commands:")
    print("  1 - Scan your test card (955b3900)")
    print("  2 - Scan demo admin card (A955AF02)")
    print("  3 - Scan demo user card (B7621C45)")
    print("  4 - Scan custom card")
    print("  s - Show status")
    print("  q - Quit")
    
    try:
        while True:
            cmd = input("\n🎮 Enter command: ").strip().lower()
            
            if cmd == '1':
                simulate_card_scan('955b3900')
            elif cmd == '2':
                simulate_card_scan('A955AF02')
            elif cmd == '3':
                simulate_card_scan('B7621C45')
            elif cmd == '4':
                card_uid = input("Enter card UID: ").strip()
                if card_uid:
                    simulate_card_scan(card_uid)
                else:
                    print("❌ Invalid card UID")
            elif cmd == 's':
                print(f"📁 Directory: {os.path.abspath(CARD_DIR)}")
                files = list(Path(CARD_DIR).glob("card_*.json"))
                print(f"📄 Pending scans: {len(files)}")
                for f in files:
                    print(f"  - {f.name}")
            elif cmd == 'q':
                break
            else:
                print("❌ Unknown command")
                
    except KeyboardInterrupt:
        print("\n🛑 Stopping simulator...")
    finally:
        write_status('stopped', 'Simulator stopped')

if __name__ == '__main__':
    main()