#!/usr/bin/env python3
"""
Simple WebSocket server for testing Flutter connectivity
"""
import asyncio
import websockets
import json
from datetime import datetime

connected_clients = set()

async def handle_client(websocket, path):
    client_addr = websocket.remote_address
    print(f"🔗 Client connected: {client_addr}")
    connected_clients.add(websocket)
    
    try:
        # Send immediate welcome
        await websocket.send("SYSTEM:READY")
        print(f"📤 Sent SYSTEM:READY to {client_addr}")
        
        # Send test card every 3 seconds
        while True:
            await asyncio.sleep(3)
            if websocket in connected_clients:
                test_message = "CARDUID:955b3900"
                await websocket.send(test_message)
                print(f"📤 Sent {test_message} to {client_addr}")
            
    except websockets.exceptions.ConnectionClosed:
        print(f"🔌 Client disconnected: {client_addr}")
    except Exception as e:
        print(f"❌ Error with {client_addr}: {e}")
    finally:
        connected_clients.discard(websocket)

async def main():
    # Start server on localhost only
    server = await websockets.serve(
        handle_client, 
        "127.0.0.1",  # Only localhost
        8765,
        ping_interval=None,  # Disable ping/pong
        ping_timeout=None,
        close_timeout=10,
    )
    
    print("🚀 Simple WebSocket server started")
    print("🌐 Listening on: ws://127.0.0.1:8765")
    print("📝 Will send test card scans every 3 seconds")
    print("🛑 Press Ctrl+C to stop")
    
    # Keep running
    try:
        await server.wait_closed()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped")

if __name__ == "__main__":
    asyncio.run(main())