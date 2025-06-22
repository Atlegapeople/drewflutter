import asyncio
import serial
import websockets

SERIAL_PORT = 'COM7'
BAUD_RATE = 9600
WS_PORT = 8765

connected_clients = set()

async def handle_websocket(websocket, path):
    print(f"🔗 New WebSocket connection from {websocket.remote_address}")
    connected_clients.add(websocket)
    try:
        # Send welcome message
        await websocket.send("SYSTEM:READY")
        print(f"✅ Sent welcome message to {websocket.remote_address}")
        
        # Handle incoming messages (if any)
        async for message in websocket:
            print(f"📨 Received from client: {message}")
            
    except Exception as e:
        print(f"❌ WebSocket error: {e}")
    finally:
        print(f"🔌 WebSocket disconnected: {websocket.remote_address}")
        connected_clients.remove(websocket)

async def serial_reader():
    with serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1) as ser:
        print(f"Serial port {SERIAL_PORT} opened. Waiting for card scans...")
        while True:
            raw = ser.readline()
            try:
                line = raw.decode('utf-8', errors='ignore').strip()
                if line:
                    print(f"Card scanned: {line}")
                    await broadcast(line)
            except Exception as e:
                print(f"❌ Decode error: {e}")
                print(f"Raw bytes: {raw}")

async def broadcast(message):
    if connected_clients:
        print(f"📡 Broadcasting to {len(connected_clients)} clients: {message}")
        disconnected = []
        for client in connected_clients:
            try:
                await client.send(message)
            except Exception as e:
                print(f"❌ Failed to send to client: {e}")
                disconnected.append(client)
        
        # Remove disconnected clients
        for client in disconnected:
            connected_clients.discard(client)

async def main():
    # Start WebSocket server
    server = await websockets.serve(handle_websocket, "0.0.0.0", WS_PORT)
    print(f"🌐 WebSocket server running on ws://localhost:{WS_PORT}")
    print(f"🌐 Also available on ws://192.168.10.230:{WS_PORT}")
    
    # Run both WebSocket server and serial reader in parallel
    await asyncio.gather(
        server.wait_closed(),      # Wait for server shutdown (usually never ends)
        serial_reader()            # Serial port reader loop
    )

if __name__ == '__main__':
    asyncio.run(main())
