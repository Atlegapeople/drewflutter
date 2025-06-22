#!/usr/bin/env python3
"""
HTTP-based card reader server as WebSocket alternative
"""
import asyncio
import serial
from aiohttp import web
import json
from datetime import datetime
import threading
import queue

# Global variables
last_card = None
card_queue = queue.Queue()

def serial_reader():
    """Run serial reader in separate thread"""
    global last_card
    try:
        with serial.Serial('COM7', 9600, timeout=1) as ser:
            print(f"Serial port COM7 opened. Waiting for card scans...")
            while True:
                raw = ser.readline()
                try:
                    line = raw.decode('utf-8', errors='ignore').strip()
                    if line:
                        print(f"Card scanned: {line}")
                        if line.startswith('CARDUID:'):
                            uid = line.replace('CARDUID:', '').strip()
                            last_card = uid
                            card_queue.put(uid)
                            print(f"✅ Card UID: {uid}")
                except Exception as e:
                    print(f"❌ Decode error: {e}")
    except Exception as e:
        print(f"❌ Serial error: {e}")

async def get_card(request):
    """HTTP endpoint to get last scanned card"""
    global last_card
    response = {
        'status': 'ok',
        'card_uid': last_card,
        'timestamp': datetime.now().isoformat()
    }
    return web.json_response(response)

async def poll_card(request):
    """HTTP endpoint that waits for next card scan"""
    try:
        # Wait up to 30 seconds for a card
        await asyncio.sleep(0.1)  # Small delay
        if not card_queue.empty():
            card_uid = card_queue.get()
            response = {
                'status': 'card_scanned',
                'card_uid': card_uid,
                'timestamp': datetime.now().isoformat()
            }
        else:
            response = {
                'status': 'no_card',
                'card_uid': None,
                'timestamp': datetime.now().isoformat()
            }
        return web.json_response(response)
    except Exception as e:
        return web.json_response({
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        })

async def simulate_card(request):
    """Simulate a card scan for testing"""
    global last_card
    test_uid = "955b3900"
    last_card = test_uid
    card_queue.put(test_uid)
    print(f"🧪 Simulated card scan: {test_uid}")
    
    response = {
        'status': 'simulated',
        'card_uid': test_uid,
        'timestamp': datetime.now().isoformat()
    }
    return web.json_response(response)

async def status(request):
    """Status endpoint"""
    response = {
        'status': 'running',
        'server': 'HTTP Card Reader',
        'last_card': last_card,
        'timestamp': datetime.now().isoformat()
    }
    return web.json_response(response)

def main():
    # Start serial reader in background thread
    serial_thread = threading.Thread(target=serial_reader, daemon=True)
    serial_thread.start()
    print("🔌 Serial reader started in background")
    
    # Set up HTTP server
    app = web.Application()
    app.router.add_get('/card', get_card)
    app.router.add_get('/poll', poll_card)
    app.router.add_post('/simulate', simulate_card)
    app.router.add_get('/status', status)
    
    # Add CORS headers for Flutter
    async def add_cors(request, handler):
        response = await handler(request)
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
        return response
    
    app.middlewares.append(add_cors)
    
    print("🚀 HTTP Card Reader Server starting...")
    print("🌐 Endpoints:")
    print("   GET  http://127.0.0.1:8766/status   - Server status")
    print("   GET  http://127.0.0.1:8766/card     - Get last card")
    print("   GET  http://127.0.0.1:8766/poll     - Poll for next card")
    print("   POST http://127.0.0.1:8766/simulate - Simulate card scan")
    print("🛑 Press Ctrl+C to stop")
    
    web.run_app(app, host='127.0.0.1', port=8766)

if __name__ == '__main__':
    main()