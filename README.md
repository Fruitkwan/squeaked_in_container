# KestrelView Squeak/Smalltalk Docker Setup

This setup provides a modern, persistent Dockerized environment to run Squeak Smalltalk (KestrelView) with multi-platform support for both Apple Silicon (ARM64) and Intel/AMD64 systems, with multiple GUI access methods.

## Prerequisites

**Important:** You need to obtain the Squeak image file separately, as it's excluded from this repository due to size constraints.

1. **Obtain the Squeak image file:**
   - Download `TPR-KestrelView-DemoVersion-2023-07-15-64bit.image`
   - Place it in the `/squeak/` directory alongside this README
   - The image file should be at: `/squeak/TPR-KestrelView-DemoVersion-2023-07-15-64bit.image`
   - **Note:** Contact the KestrelView project maintainers or check project documentation for image file availability

2. **Build the container (one-time setup):**

   ```bash
   ./build.sh
   ```

## Persistent Workflow

After the initial build, the container is fully persistent. Simply:

1. **Start your preferred container:**

   ```bash
   # For VNC access (recommended)
   docker-compose up kestrel-vnc -d
   
   # OR for X11 direct access  
   docker-compose up kestrel-x11 -d
   
   # OR for SSH X11 forwarding
   docker-compose up kestrel-ssh -d
   ```

2. **Connect using your chosen method (see below)**

3. **Stop when done:**

   ```bash
   docker-compose down
   ```

**No manual script copying or execution needed!** Everything is built into the container.

## Access Methods

### 1. VNC Access (RECOMMENDED for Mac)

**Easiest method - no additional software needed**

1. **Start the VNC container:**
   ```bash
   docker-compose up kestrel-vnc -d
   ```

2. **Connect to VNC at `localhost:5900`**
   - **Password:** `squeak`

3. **VNC Client Options:**
   - **macOS Screen Sharing (built-in):** 
     - Finder → Go → Connect to Server → `vnc://localhost:5900`
   - **RealVNC Viewer:** Download from realvnc.com
   - **TigerVNC Viewer:** Available via Homebrew

### 2. X11 Direct Access (requires XQuartz)

**Squeak GUI appears directly on your Mac screen**

1. **Install XQuartz (if not already installed):**
   ```bash
   brew install --cask xquartz
   ```

2. **Stop any running containers:**
   ```bash
   docker-compose down
   ```

3. **Start and configure XQuartz:**
   ```bash
   open -a XQuartz
   ```

4. **Configure XQuartz Security (IMPORTANT):**
   - Go to XQuartz → Preferences → Security
   - ✅ Check "Allow connections from network clients"
   - ✅ Check "Authenticate connections"
   - **Restart XQuartz** after changing settings

5. **Allow Docker to connect to X11:**
   ```bash
   xhost +local:docker
   ```

6. **Start the X11 container:**
   ```bash
   DISPLAY=host.docker.internal:0 docker-compose up kestrel-x11
   ```

7. **The Squeak GUI should appear directly on your Mac screen!**

### 3. SSH X11 Forwarding (advanced)

**For users who prefer SSH access**

1. **Ensure XQuartz is running (see steps 3-6 above)**

2. **Start the SSH container:**
   ```bash
   docker-compose up kestrel-ssh -d
   ```

3. **Connect via SSH with X11 forwarding:**
   ```bash
   ssh -X -p 2222 squeak@localhost
   ```
   (No password required - uses key-based auth)

4. **Run Squeak from inside the SSH session:**
   ```bash
   ./start-squeak.sh
   ```

## Troubleshooting X11 Issues

### If Squeak doesn't appear on screen:

1. **Check XQuartz is running:**
   ```bash
   ps aux | grep -i xquartz
   ```

2. **Verify X11 forwarding is working:**
   ```bash
   # Test with a simple X11 app
   docker-compose exec kestrel-x11 xeyes
   ```

3. **Check Docker X11 connection:**
   ```bash
   docker-compose exec kestrel-x11 echo $DISPLAY
   # Should show: host.docker.internal:0
   ```

4. **Reset XQuartz if needed:**
   ```bash
   killall XQuartz
   open -a XQuartz
   xhost +local:docker
   ```

## Container Access

### Accessing the Container Shell

You can access the running container shell for debugging, file management, or manual operations:

```bash
# Access VNC container shell
docker-compose exec kestrel-vnc bash

# Access SSH container shell  
docker-compose exec kestrel-ssh bash

# Access X11 container shell
docker-compose exec kestrel-x11 bash
```

### Running Commands in Container

```bash
# Run a single command in the container
docker-compose exec kestrel-vnc ls -la /app

# Check Squeak process status
docker-compose exec kestrel-vnc ps aux | grep squeak

# Manually start Squeak (if needed)
docker-compose exec kestrel-vnc /app/start-squeak.sh

# Check environment variables
docker-compose exec kestrel-vnc env | grep DISPLAY
```

### File Operations

```bash
# Copy files TO the container
docker cp /path/to/local/file kestrel-vnc:/app/

# Copy files FROM the container  
docker cp kestrel-vnc:/app/file.txt /path/to/local/

# Edit files in the container
docker-compose exec kestrel-vnc nano /app/some-file.txt
```

### Container Information

```bash
# Check container status
docker-compose ps

# View container resource usage
docker stats kestrel-vnc

# Inspect container configuration
docker inspect kestrel-vnc
```

## Stopping Services

```bash
# Stop all services
docker-compose down

# Stop specific service
docker-compose stop kestrel-vnc
```

## Architecture Support

The setup automatically detects and supports:
- x86_64 (AMD64)
- ARM64 (Apple Silicon, Raspberry Pi)

## Files Structure

- `Dockerfile` - Main Docker configuration with VNC and X11 support
- `docker-compose.yml` - Multiple service configurations
- `supervisord.conf` - Process management for VNC setup
- `scripts/start-squeak.sh` - Smart Squeak VM launcher
- `scripts/start-ssh.sh` - SSH server with X11 forwarding
- `scripts/start-vnc.sh` - VNC server setup
- `image-data/` - Volume mount point for persistent data

## Checking Container Status and Logs

### Check Running Containers
```bash
docker-compose ps
```

### View Live Logs
```bash
# View logs for VNC service
docker-compose logs -f kestrel-vnc

# View logs for SSH service
docker-compose logs -f kestrel-ssh

# View logs for X11 service
docker-compose logs -f kestrel-x11

# View logs for all services
docker-compose logs -f
```

### Check Squeak Process Status
```bash
# Enter container shell
docker-compose exec kestrel-vnc bash

# Check if Squeak is running
ps aux | grep squeak

# Check X11 display
echo $DISPLAY
xdpyinfo

# Test Squeak startup manually
/app/start-squeak.sh
```

### Debug Container Issues
```bash
# View container resource usage
docker stats

# Inspect container configuration
docker inspect kestrel-vnc

# Check container filesystem
docker-compose exec kestrel-vnc ls -la /app
```

## Troubleshooting

### VNC Connection Issues
- Ensure port 5900 is not blocked by firewall
- Check container logs: `docker-compose logs kestrel-vnc`

### X11 Forwarding Issues
- On macOS: Install XQuartz and enable "Allow connections from network clients"
- On Linux: Run `xhost +local:docker` before starting

### SSH Connection Issues
- Check SSH keys are properly configured
- Verify port 2222 is available
- Check logs: `docker-compose logs kestrel-ssh`

## Stopping Services

```bash
docker-compose down
```

## Development

To modify Squeak images or add custom code:
1. Place files in `image-data/` directory
2. They will be available in `/app/image-data/` inside the container
3. Restart the appropriate service

## Summary

This setup provides a **fully persistent** Docker environment for KestrelView:

- **Multi-platform support:** Works on both Apple Silicon (ARM64) and Intel/AMD64 systems
- **One-time setup:** Build the image with `./build.sh`
- **Daily use:** Simply run `docker-compose up kestrel-vnc -d` and connect
- **No manual steps:** All scripts and configurations are built into the container
- **Persistent data:** The `image-data/` directory preserves your work between sessions
- **Modern VM:** Uses the latest OpenSmalltalk VM with automatic platform detection

The container automatically detects your system architecture and downloads the appropriate OpenSmalltalk VM (ARM64 or x86_64), then runs it directly (bypassing the old system VM) with multiple access methods for maximum compatibility.

## Platform Support

### Supported Platforms:
- **Apple Silicon (ARM64):** MacBook Pro M1/M2/M3, Mac Studio, Mac Mini M1/M2
- **Intel/AMD64:** Traditional Intel Macs, Linux systems, Windows with WSL2

### Platform-Specific Notes:
- **Apple Silicon:** Uses `squeak.cog.spur_linux64ARMv8.tar.gz`
- **Intel/AMD64:** Uses `squeak.cog.spur_linux64x64.tar.gz`
- **Docker:** Automatically builds the correct image for your platform
