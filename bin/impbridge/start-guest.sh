#!/bin/bash
# start-guest.sh - Start guest bridge and frpc with clean shutdown

FRPC_PID=""
BRIDGE_PID=""

cleanup() {
    echo ""
    echo "=== Shutting down guest components ==="

    if [ -n "$BRIDGE_PID" ]; then
        echo "Stopping guest-bridge (PID: $BRIDGE_PID)..."
        kill $BRIDGE_PID 2>/dev/null
        wait $BRIDGE_PID 2>/dev/null
    fi

    if [ -n "$FRPC_PID" ]; then
        echo "Stopping frpc (PID: $FRPC_PID)..."
        kill $FRPC_PID 2>/dev/null
        wait $FRPC_PID 2>/dev/null
    fi

    echo "=== Guest components stopped ==="
    exit 0
}

# Trap Ctrl-C and other termination signals
trap cleanup SIGINT SIGTERM

echo "=== Starting Guest Components ==="
echo ""

# Start frpc
echo "Starting frpc..."
./frpc -c frpc-guest.ini &
FRPC_PID=$!
echo "frpc started (PID: $FRPC_PID)"

# Wait a bit for frpc to initialize
sleep 2

# Start guest-bridge
echo "Starting guest-bridge..."
./guest-bridge --verbose &
BRIDGE_PID=$!
echo "guest-bridge started (PID: $BRIDGE_PID)"

echo ""
echo "=== Guest Components Running ==="
echo "frpc PID:    $FRPC_PID"
echo "bridge PID:  $BRIDGE_PID"
echo ""
echo "Press Ctrl+C to stop all components"
echo ""
echo "Now attach IMP with: attach mi1 11198:localhost:11199"
echo "Or test with: python3 test-guest.py"
echo ""

# Wait for processes (keeps script running)
wait
