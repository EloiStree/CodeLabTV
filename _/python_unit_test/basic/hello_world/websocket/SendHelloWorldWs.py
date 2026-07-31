import asyncio
import websockets
import struct


ip_address = "ws://192.168.178.139:3616"


class GodotMultiplayerClient:
    def __init__(self, uri=ip_address):
        self.uri = uri
        self.websocket = None
        self.peer_id = 1  # Godot multiplayer peer ID
    
    def encode_multiplayer_packet(self, data, packet_type=0, channel=0):
        """
        Encode a packet in Godot's multiplayer format
        Godot format: [target_peer (4 bytes)][source_peer (4 bytes)][packet_type (4 bytes)][channel (4 bytes)][data]
        """
        # For broadcast, target_peer is 0
        target_peer = 0
        source_peer = self.peer_id
        
        header = struct.pack('!iiii', target_peer, source_peer, packet_type, channel)
        if isinstance(data, str):
            data = data.encode('utf-8')
        
        return header + data
    
    def decode_multiplayer_packet(self, packet):
        """
        Decode a Godot multiplayer packet
        Returns (target_peer, source_peer, packet_type, channel, data)
        """
        if len(packet) < 16:  # Minimum header size
            return None
        
        target_peer, source_peer, packet_type, channel = struct.unpack('!iiii', packet[:16])
        data = packet[16:]
        
        # Try to decode as UTF-8 string
        try:
            data = data.decode('utf-8')
        except UnicodeDecodeError:
            pass  # Keep as bytes
        
        return target_peer, source_peer, packet_type, channel, data
    
    async def connect(self):
        """Connect to the Godot WebSocket server"""
        try:
            self.websocket = await websockets.connect(self.uri)
            print(f"Connected to {self.uri}")
            return True
        except Exception as e:
            print(f"Connection failed: {e}")
            return False
    
    async def send_raw_text(self, message):
        """Send raw text without Godot multiplayer wrapper"""
        if self.websocket:
            await self.websocket.send(message)
            print(f"Sent raw text: {message}")
    
    async def send_raw_bytes(self, data):
        """Send raw bytes without Godot multiplayer wrapper"""
        if self.websocket:
            await self.websocket.send(data)
            print(f"Sent raw bytes: {len(data)} bytes")
    
    async def send_multiplayer_text(self, message):
        """Send text wrapped in Godot multiplayer format"""
        if self.websocket:
            packet = self.encode_multiplayer_packet(message)
            await self.websocket.send(packet)
            print(f"Sent multiplayer text: {message}")
    
    async def receive_raw(self):
        """Receive raw WebSocket message"""
        if self.websocket:
            try:
                message = await self.websocket.recv()
                
                # Try to decode as Godot multiplayer packet
                decoded = self.decode_multiplayer_packet(message)
                if decoded:
                    target, source, ptype, channel, data = decoded
                    print(f"Received multiplayer packet - From: {source}, Type: {ptype}, Data: {data}")
                    return data
                else:
                    # Raw message
                    if isinstance(message, str):
                        print(f"Received raw text: {message}")
                    else:
                        print(f"Received raw bytes: {message.hex()}")
                    return message
            except websockets.exceptions.ConnectionClosed:
                print("Connection closed")
                return None
    
    async def close(self):
        """Close the connection"""
        if self.websocket:
            await self.websocket.close()
            print("Connection closed")

# Example usage
async def main():
    # Use the raw WebSocket approach (Option 1)
    client = GodotMultiplayerClient(ip_address)
    
    if await client.connect():
        # Send raw text (this will work with Option 1 server)
        await client.send_raw_text("Hello World")
        await asyncio.sleep(0.1)
        
        # Send raw bytes
        await client.send_raw_bytes(b'\x00\x01\x02\x03')
        await asyncio.sleep(0.1)
        
        # Try to receive response
        response = await client.receive_raw()
        
        # Keep listening
        while True:
            msg = await client.receive_raw()
            if msg is None:
                break

asyncio.run(main())