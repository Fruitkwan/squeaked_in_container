#!/bin/bash

echo "Starting VNC server..."

# Kill any existing VNC sessions
vncserver -kill :1 2>/dev/null || true

# Start VNC server
vncserver :1 -geometry 1024x768 -depth 24

echo "VNC server started on display :1"
echo "Connect to VNC at localhost:5900"
