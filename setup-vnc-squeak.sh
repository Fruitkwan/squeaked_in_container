#!/bin/bash

# VNC approach - more reliable than X11 forwarding

# Create VNC Dockerfile
cat > Dockerfile.vnc << 'DOCKER_EOF'
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install VNC server and desktop environment
RUN apt-get update && apt-get install -y \
    tightvncserver \
    xfce4 \
    xfce4-goodies \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libfreetype6 \
    libfontconfig1 \
    libasound2 \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy Squeak files
COPY sqcogspur64linuxht ./sqcogspur64linuxht
COPY *.image ./
COPY *.changes ./
COPY SqueakV50.sources ./

# Make VM executable
RUN chmod +x sqcogspur64linuxht/squeak
RUN chmod 777 /dev/shm

# Set up VNC
RUN mkdir -p ~/.vnc
RUN echo "kestrel123" | vncpasswd -f > ~/.vnc/passwd
RUN chmod 600 ~/.vnc/passwd

# VNC startup script
RUN echo '#!/bin/bash\n\
export DISPLAY=:1\n\
echo "Starting VNC server..."\n\
vncserver :1 -geometry 1200x800 -depth 24 &\n\
sleep 5\n\
echo "VNC server started. Connect to localhost:5901 with password: kestrel123"\n\
echo "Starting KestrelView Squeak..."\n\
IMAGE_FILE=$(ls *.image | head -n 1)\n\
echo "Using image: $IMAGE_FILE"\n\
DISPLAY=:1 ./sqcogspur64linuxht/squeak "$IMAGE_FILE" &\n\
echo "Squeak started. Keeping container alive..."\n\
tail -f ~/.vnc/*.log' > /app/start-vnc.sh && chmod +x /app/start-vnc.sh

# Expose VNC port
EXPOSE 5901 8088

CMD ["/app/start-vnc.sh"]
DOCKER_EOF

# Build VNC container
echo "Building VNC Squeak container..."
docker build -f Dockerfile.vnc -t kestrelview-vnc .

# Run VNC container
echo ""
echo "�� KestrelView is starting with VNC..."
echo ""
echo "📱 To view your Squeak GUI:"
echo "   1. Download VNC Viewer: https://www.realvnc.com/en/connect/download/viewer/"
echo "   2. Connect to: localhost:5901"
echo "   3. Password: kestrel123"
echo ""
echo "💻 Alternative VNC clients:"
echo "   - Screen Sharing (built into macOS): vnc://localhost:5901"
echo "   - TightVNC, RealVNC, or any VNC client"
echo ""

docker run -it --rm \
  --platform linux/amd64 \
  -p 5901:5901 \
  -p 8088:8088 \
  --cap-add=SYS_ADMIN \
  kestrelview-vnc
