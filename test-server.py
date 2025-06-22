import asyncio
import websockets
import threading
import time

connected_clients = set()

async def handle_websocket(websocket, path):
    print(f"🔗 New WebSocket connection from {websocket.remote_address}")
    connected_clients.add(websocket)
    try:
        # Send immediate welcome message
        await websocket.send("SYSTEM:READY")
        print(f"✅ Sent SYSTEM:READY to {websocket.remote_address}")
        
        # Send periodic test messages
        while True:
            await asyncio.sleep(5)
            if websocket in connected_clients:
                await websocket.send("CARDUID:955b3900")
                print(f"📡 Sent test card to {websocket.remote_address}")
            
    except websockets.exceptions.ConnectionClosed:
        print(f"🔌 Client disconnected: {websocket.remote_address}")
    except Exception as e:
        print(f"❌ WebSocket error: {e}")
    finally:
        connected_clients.discard(websocket)

async def main():
    print("🚀 Starting test WebSocket server...")
    server = await websockets.serve(handle_websocket, "127.0.0.1", 8765)
    print("🌐 Test WebSocket server running on ws://127.0.0.1:8765")
    print("📝 This server will send test card scans every 5 seconds")
    
    # Keep server running
    await server.wait_closed()

if __name__ == '__main__':
    asyncio.run(main())