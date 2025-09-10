
# Check if Xwayland is running
if ! pgrep -x "Xwayland" > /dev/null; then
    echo "Xwayland is not running. Attempting to initialize X server..."
    
    # Try to initialize the X server using xrandr
    if xrandr --display :0 > /dev/null 2>&1; then
        echo "X server initialized successfully."
    else
        echo "Failed to initialize X server. Exiting."
        exit 1
    fi
fi

echo "Starting pdpcontrol..."
pdpcontrol start
