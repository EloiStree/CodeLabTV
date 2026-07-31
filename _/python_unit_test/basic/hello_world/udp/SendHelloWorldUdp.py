import socket
import struct
import time

HOST = "192.168.178.163"
PORT_BYTE = 3615
PORT_TEXT = 3614

while True:
    try:
        # Create UDP socket
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            # Send the string
            s.sendto(b"Hello World", (HOST, PORT_TEXT))
            print("Sent text: Hello World")
            
            # Wait 2 seconds
            time.sleep(2)
            
            # Send a 32-bit little-endian integer
            s.sendto(struct.pack("<I", 42), (HOST, PORT_BYTE))
            print("Sent integer: 42")
            
            print("---")

    except OSError as e:
        print(f"Socket error: {e}")

    time.sleep(1)