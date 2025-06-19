#!/bin/bash

echo "Building Squeak Docker container for Apple Silicon..."

# Build the Docker image for ARM64
docker-compose build --build-arg BUILDPLATFORM=linux/arm64

echo "Build complete!"
echo ""
echo "Usage options for Apple Silicon Mac:"
echo ""
echo "1. VNC Access (RECOMMENDED for Mac):"
echo "   docker-compose up kestrel-vnc -d"
echo "   # Connect to VNC at localhost:5900 (password: squeak)"
echo "   # Use any VNC client like RealVNC Viewer or macOS Screen Sharing"
echo ""
echo "2. SSH X11 Forwarding (requires XQuartz):"
echo "   # First install XQuartz: brew install --cask xquartz"
echo "   # Start XQuartz and enable 'Allow connections from network clients'"
echo "   docker-compose up kestrel-ssh -d"
echo "   ssh -X -p 2222 squeak@localhost"
echo ""
echo "3. Direct X11 (XQuartz required):"
echo "   # Make sure XQuartz is running with network connections enabled"
echo "   xhost +local:docker"
echo "   DISPLAY=host.docker.internal:0 docker-compose up kestrel-x11"
echo ""
echo "To stop:"
echo "   docker-compose down"