#!/bin/bash

echo "Building Squeak Docker container with multi-platform support..."
echo "This will build for your current platform (ARM64 or AMD64)..."

# Build the Docker image (will auto-detect platform)
docker-compose build

echo "Build complete!"
echo ""
echo "Usage options (works on both Apple Silicon and Intel/AMD64):"
echo ""
echo "1. VNC Access (RECOMMENDED - cross-platform):"
echo "   docker-compose up kestrel-vnc -d"
echo "   # Connect to VNC at localhost:5900 (password: squeak)"
echo "   # Use any VNC client like RealVNC Viewer or macOS Screen Sharing"
echo ""
echo "2. SSH X11 Forwarding (requires X11 server):"
echo "   # macOS: Install XQuartz - brew install --cask xquartz"
echo "   # Linux: Usually pre-installed"
echo "   # Start X11 server and enable network connections"
echo "   docker-compose up kestrel-ssh -d"
echo "   ssh -X -p 2222 squeak@localhost"
echo ""
echo "3. Direct X11 (X11 server required):"
echo "   # macOS: Make sure XQuartz is running with network connections enabled"
echo "   # Linux: Make sure X11 is running"
echo "   xhost +local:docker"
echo "   DISPLAY=host.docker.internal:0 docker-compose up kestrel-x11  # macOS"
echo "   # or"
echo "   DISPLAY=:0 docker-compose up kestrel-x11  # Linux"
echo ""
echo "To stop:"
echo "   docker-compose down"