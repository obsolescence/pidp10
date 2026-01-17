#!/usr/bin/env python3
"""
test-guest.py - Test guest bridge
Mimics guest IMP behavior without connected sockets

Sends to: localhost:11199 (where guest-bridge expects IMP to send)
Receives on: localhost:11198 (where guest-bridge sends to IMP)
"""

import socket
import time

# Match guest IMP ports
RECEIVE_PORT = 11198   # guest-bridge sends to IMP here
SEND_PORT = 11199      # guest-bridge receives from IMP here

def main():
    """Main loop: receive and respond"""
    # Create receive socket
    receive_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    receive_sock.bind(('127.0.0.1', RECEIVE_PORT))

    # Create send socket
    send_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    print("=" * 60)
    print("GUEST BRIDGE TEST PROGRAM")
    print("=" * 60)
    print(f"Tests guest-bridge by receiving/sending on IMP ports")
    print(f"Receive on:  localhost:{RECEIVE_PORT}")
    print(f"Send to:     localhost:{SEND_PORT}")
    print("=" * 60)
    print()

    counter = 0
    while True:
        try:
            # Receive message
            data, addr = receive_sock.recvfrom(1024)
            message = data.decode('utf-8')
            timestamp = time.strftime('%H:%M:%S')
            print(f"[GUEST-TEST {timestamp}] ✓ RECEIVED: '{message}' from {addr}")

            # Send response
            counter += 1
            response = f"hi from guest #{counter}"
            send_sock.sendto(response.encode('utf-8'), ('127.0.0.1', SEND_PORT))
            print(f"[GUEST-TEST {timestamp}] → SENT: '{response}'")
            print()

        except KeyboardInterrupt:
            print("\n[GUEST-TEST] Shutting down...")
            break
        except Exception as e:
            print(f"[GUEST-TEST] Error: {e}")

if __name__ == '__main__':
    main()
