# Installing Docker on Windows 11 for FQGE

## Prerequisites

Before installing Docker, ensure your system meets these requirements:

- **Windows 11 Pro, Enterprise, or Education** (Home edition requires WSL 2)
- **Hardware**: At least 4GB RAM, 2GB available disk space
- **Virtualization**: Enabled in BIOS/UEFI
- **WSL 2**: Required for Docker Desktop

## Step 1: Enable Virtualization

1. Restart your computer and enter BIOS/UEFI (usually F2, F10, F12, or Del)
2. Find "Virtualization Technology" or "VT-x" and enable it
3. Save changes and exit

## Step 2: Install WSL 2 (if not already installed)

Open PowerShell or Command Prompt as Administrator and run:

```powershell
# Enable WSL feature
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Enable Virtual Machine Platform
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart computer
shutdown /r /t 0
```

After restart, install WSL 2:

```powershell
# Set WSL 2 as default version
wsl --set-default-version 2

# Install Ubuntu (or your preferred distribution)
wsl --install -d Ubuntu
```

## Step 3: Download and Install Docker Desktop

1. **Download Docker Desktop**:
   - Go to https://www.docker.com/products/docker-desktop
   - Download the Windows installer

2. **Install Docker Desktop**:
   - Run the installer as Administrator
   - Follow the installation wizard
   - When prompted, ensure "Enable WSL 2 Windows Features" is checked
   - Complete the installation

3. **Start Docker Desktop**:
   - Launch Docker Desktop from Start menu
   - Sign in with Docker Hub account (optional)
   - Wait for Docker to start (whale icon in system tray should be solid)

## Step 4: Verify Installation

Open PowerShell or Command Prompt and run:

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker-compose --version

# Test Docker with hello-world
docker run hello-world
```

You should see:
```
Docker version 24.x.x, build xxxx
docker-compose version 2.x.x
Hello from Docker!
```

## Step 5: Configure Docker Desktop (Optional)

1. **Resources**: Go to Settings → Resources
   - Allocate at least 4GB RAM
   - Allocate 2+ CPU cores
   - Set disk image size to 20GB+

2. **WSL Integration**: Settings → Resources → WSL Integration
   - Enable integration with your WSL 2 distributions

## Step 6: Test FQGE Environment

Once Docker is installed:

```bash
# Navigate to FQGE project directory
cd c:\Users\user\Work\qualityGate

# Make the test script executable (if needed)
# Run the automated test
.\run_docker_test.sh
```

Or manually:

```bash
# Start services
docker-compose up -d

# Check services
docker-compose ps

# Run FQGE test
docker-compose exec fqge-app ./test_fqge.sh
```

## Troubleshooting

### Common Issues:

1. **"Docker is not recognized"**:
   - Restart PowerShell/Command Prompt
   - Restart Docker Desktop
   - Check PATH environment variable

2. **WSL 2 not working**:
   ```bash
   wsl --list --verbose
   wsl --set-default-version 2
   ```

3. **Virtualization not enabled**:
   - Check BIOS settings
   - Run: `systeminfo | find "Virtualization"`

4. **Port conflicts**:
   - Ensure ports 1521 (Oracle) and 8080 (API) are free
   - Change ports in docker-compose.yml if needed

5. **Memory issues**:
   - Increase Docker Desktop memory allocation
   - Close other applications

### Getting Help:

- **Docker Documentation**: https://docs.docker.com/desktop/windows/
- **FQGE Issues**: Check docker_setup.md for specific troubleshooting
- **WSL Issues**: https://docs.microsoft.com/en-us/windows/wsl/

## Alternative: Docker Engine without Desktop

If you prefer Docker Engine without the GUI:

1. Install Docker Engine using Chocolatey:
   ```powershell
   choco install docker-engine
   ```

2. Install Docker Compose:
   ```powershell
   choco install docker-compose
   ```

Note: This requires more manual configuration and is recommended only for advanced users.

## Next Steps

Once Docker is installed and working:

1. Run the FQGE Docker test environment
2. Verify all services start correctly
3. Execute the full FQGE validation suite
4. Customize configuration for your environment

The FQGE system is now ready for deployment and testing in your Docker environment!