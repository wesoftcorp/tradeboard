script = r"""#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Tradeboard Installation Banner
echo -e "${BLUE}"
echo " ████████╗██████╗  █████╗ ██████╗ ███████╗██████╗  ██████╗  █████╗ ██████╗ ██████╗ "
echo "    ██╔══╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔══██╗"
echo "    ██║   ██████╔╝███████║██║  ██║█████╗  ██████╔╝██║   ██║███████║██████╔╝██║  ██║"
echo "    ██║   ██╔══██╗██╔══██║██║  ██║██╔══╝  ██╔══██╗██║   ██║██╔══██║██╔══██╗██║  ██║"
echo "    ██║   ██║  ██║██║  ██║██████╔╝███████╗██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝"
echo "    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ "
echo "                                                                                      "
echo "                  Tradeboard -- Installation & Configuration Script                  "
echo "                       Repository: wesoftcorp/tradeboard                             "
echo -e "${NC}"

# ---------------------------------------------------------------------------
# Log setup
# ---------------------------------------------------------------------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGS_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOGS_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOGS_DIR/install_${TIMESTAMP}.log"

log_message() {
    local message="$1"
    local color="$2"
    echo -e "${color}${message}${NC}" | tee -a "$LOG_FILE"
}

check_status() {
    if [ $? -ne 0 ]; then
        log_message "Error: $1" "$RED"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Timezone helper
# ---------------------------------------------------------------------------
check_timezone() {
    current_tz=$(timedatectl | grep "Time zone" | awk '{print $3}')
    log_message "Current timezone: $current_tz" "$BLUE"

    if [[ "$current_tz" == "Asia/Kolkata" ]]; then
        log_message "Server is already set to IST timezone." "$GREEN"
        return 0
    fi

    log_message "Server is not set to IST timezone." "$YELLOW"
    read -p "Would you like to change the timezone to IST? (y/n): " change_tz
    if [[ $change_tz =~ ^[Yy]$ ]]; then
        log_message "Changing timezone to IST..." "$BLUE"
        sudo timedatectl set-timezone Asia/Kolkata
        check_status "Failed to change timezone"
        log_message "Timezone successfully changed to IST" "$GREEN"
    else
        log_message "Keeping current timezone: $current_tz" "$YELLOW"
    fi
}

# ---------------------------------------------------------------------------
# dpkg lock helper (Ubuntu/Debian)
# ---------------------------------------------------------------------------
wait_for_dpkg_lock() {
    local max_wait=300
    local waited=0

    while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
          sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
          sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do

        if [ $waited -eq 0 ]; then
            log_message "Package manager is locked (unattended-upgrades running)" "$YELLOW"
            log_message "Waiting for it to complete... (max 5 minutes)" "$YELLOW"
        fi

        if [ $waited -ge $max_wait ]; then
            log_message "Timeout waiting for package manager lock" "$RED"
            log_message "Please run: sudo killall unattended-upgr && sudo rm /var/lib/dpkg/lock*" "$YELLOW"
            exit 1
        fi

        printf "."
        sleep 5
        waited=$((waited + 5))
    done

    if [ $waited -gt 0 ]; then
        echo ""
        log_message "Package manager is now available" "$GREEN"
    fi
}

# ---------------------------------------------------------------------------
# Random token generator
# ---------------------------------------------------------------------------
generate_hex() {
    $PYTHON_CMD -c "import secrets; print(secrets.token_hex(32))"
}

# ---------------------------------------------------------------------------
# Handle existing file/directory (backup or remove)
# ---------------------------------------------------------------------------
handle_existing() {
    local path=$1
    local type=$2
    local name=$3

    if [ -e "$path" ]; then
        log_message "Warning: $name already exists at $path" "$YELLOW"
        read -p "Would you like to backup the existing $type? (y/n): " backup_choice
        if [[ $backup_choice =~ ^[Yy]$ ]]; then
            backup_path="${path}_backup_$(date +%Y%m%d_%H%M%S)"
            log_message "Creating backup at $backup_path" "$BLUE"
            sudo mv "$path" "$backup_path"
            check_status "Failed to create backup of $name"
            return 0
        else
            read -p "Would you like to remove the existing $type? (y/n): " remove_choice
            if [[ $remove_choice =~ ^[Yy]$ ]]; then
                log_message "Removing existing $type..." "$BLUE"
                if [ -d "$path" ]; then
                    sudo rm -rf "$path"
                else
                    sudo rm -f "$path"
                fi
                check_status "Failed to remove existing $type"
                return 0
            else
                log_message "Installation cannot proceed without handling existing $type" "$RED"
                exit 1
            fi
        fi
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Swap memory check / creation
# ---------------------------------------------------------------------------
check_and_configure_swap() {
    # Get total RAM in MB
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
    TOTAL_RAM_GB=$((TOTAL_RAM_MB / 1024))

    log_message "System RAM: ${TOTAL_RAM_MB}MB (${TOTAL_RAM_GB}GB)" "$BLUE"

    # Check if RAM is less than 2GB
    if [ $TOTAL_RAM_MB -lt 2048 ]; then
        log_message "System has less than 2GB RAM. Checking swap configuration..." "$YELLOW"

        # Check current swap
        SWAP_TOTAL=$(free -m | grep Swap | awk '{print $2}')
        log_message "Current swap: ${SWAP_TOTAL}MB" "$BLUE"

        if [ $SWAP_TOTAL -lt 3072 ]; then
            log_message "Insufficient swap memory. Creating 3GB swap file..." "$YELLOW"

            # Check available disk space
            AVAILABLE_SPACE=$(df / | tail -1 | awk '{print $4}')
            REQUIRED_SPACE=3145728  # 3GB in KB

            if [ $AVAILABLE_SPACE -lt $REQUIRED_SPACE ]; then
                log_message "Error: Not enough disk space for swap file" "$RED"
                log_message "Available: ${AVAILABLE_SPACE}KB, Required: ${REQUIRED_SPACE}KB" "$RED"
                exit 1
            fi

            # Create swap file
            log_message "Creating 3GB swap file at /swapfile..." "$BLUE"
            sudo fallocate -l 3G /swapfile
            if [ $? -ne 0 ]; then
                # Fallback to dd if fallocate fails
                log_message "fallocate failed, using dd instead..." "$YELLOW"
                sudo dd if=/dev/zero of=/swapfile bs=1M count=3072 status=progress
            fi
            check_status "Failed to create swap file"

            # Set permissions
            sudo chmod 600 /swapfile
            check_status "Failed to set swap file permissions"

            # Setup swap
            sudo mkswap /swapfile
            check_status "Failed to setup swap"

            # Enable swap
            sudo swapon /swapfile
            check_status "Failed to enable swap"

            # Make swap permanent
            if ! grep -q "/swapfile" /etc/fstab; then
                echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
                log_message "Swap file added to /etc/fstab for persistence" "$GREEN"
            fi

            # Verify swap is active
            NEW_SWAP=$(free -m | grep Swap | awk '{print $2}')
            log_message "Swap configured successfully. Total swap: ${NEW_SWAP}MB" "$GREEN"

            # Configure swappiness for better performance
            sudo sysctl vm.swappiness=10
            echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
            log_message "Swappiness set to 10 for better performance" "$GREEN"
        else
            log_message "Sufficient swap already exists: ${SWAP_TOTAL}MB" "$GREEN"
        fi
    else
        log_message "System has sufficient RAM (${TOTAL_RAM_GB}GB)" "$GREEN"

        # Still check swap for optimal performance
        SWAP_TOTAL=$(free -m | grep Swap | awk '{print $2}')
        if [ $SWAP_TOTAL -eq 0 ]; then
            log_message "No swap configured. Consider adding swap for optimal performance." "$YELLOW"
        else
            log_message "Swap configured: ${SWAP_TOTAL}MB" "$GREEN"
        fi
    fi
}

# ===========================================================================
# START
# ===========================================================================
log_message "Starting Tradeboard installation log at: $LOG_FILE" "$BLUE"
log_message "----------------------------------------" "$BLUE"

# ---------------------------------------------------------------------------
# Detect OS
# ---------------------------------------------------------------------------
OS_TYPE=$(grep -w "ID" /etc/os-release | cut -d "=" -f 2 | tr -d '"')

# Handle OS variants
case "$OS_TYPE" in
    "pop")
        OS_TYPE="ubuntu"
        log_message "Detected Pop!_OS, using Ubuntu packages" "$BLUE"
        ;;
    "linuxmint")
        OS_TYPE="ubuntu"
        log_message "Detected Linux Mint, using Ubuntu packages" "$BLUE"
        ;;
    "zorin")
        OS_TYPE="ubuntu"
        log_message "Detected Zorin OS, using Ubuntu packages" "$BLUE"
        ;;
    "manjaro" | "manjaro-arm" | "endeavouros" | "cachyos")
        OS_TYPE="arch"
        log_message "Detected $OS_TYPE, using Arch Linux packages" "$BLUE"
        ;;
    "rocky" | "almalinux" | "ol")
        OS_TYPE="rhel"
        log_message "Detected $OS_TYPE, using RHEL-compatible packages" "$BLUE"
        ;;
esac

# Get OS version
if [ "$OS_TYPE" = "arch" ]; then
    OS_VERSION="rolling"
else
    OS_VERSION=$(grep -w "VERSION_ID" /etc/os-release | cut -d "=" -f 2 | tr -d '"')
fi

# Validate supported OS
case "$OS_TYPE" in
    arch | ubuntu | debian | raspbian | centos | fedora | rhel | rocky | almalinux | amzn)
        log_message "Detected OS: $OS_TYPE $OS_VERSION" "$GREEN"
        ;;
    *)
        log_message "Error: Unsupported operating system: $OS_TYPE" "$RED"
        log_message "Supported: Ubuntu, Debian, Raspbian, CentOS, Fedora, RHEL, Rocky, AlmaLinux, Amazon Linux, Arch Linux" "$YELLOW"
        exit 1
        ;;
esac

# ---------------------------------------------------------------------------
# OS-specific defaults
# ---------------------------------------------------------------------------
case "$OS_TYPE" in
    ubuntu | debian | raspbian)
        WEB_USER="www-data"
        WEB_GROUP="www-data"
        PYTHON_CMD="python3"
        ;;
    centos | fedora | rhel | amzn)
        WEB_USER="nginx"
        WEB_GROUP="nginx"
        PYTHON_CMD="python3"
        ;;
    arch)
        WEB_USER="http"
        WEB_GROUP="http"
        PYTHON_CMD="python"
        ;;
esac

log_message "Web server user: $WEB_USER:$WEB_GROUP" "$BLUE"
log_message "Python command: $PYTHON_CMD" "$BLUE"

# ---------------------------------------------------------------------------
# System checks
# ---------------------------------------------------------------------------
log_message "Checking system requirements..." "$BLUE"
check_and_configure_swap
check_timezone

# ---------------------------------------------------------------------------
# Collect installation parameters
# ---------------------------------------------------------------------------
log_message "Tradeboard Installation Configuration" "$BLUE"
log_message "----------------------------------------" "$BLUE"

# Get domain name
while true; do
    read -p "Enter your domain name (e.g., yourdomain.com or sub.yourdomain.com): " DOMAIN
    if [ -z "$DOMAIN" ]; then
        log_message "Error: Domain name is required" "$RED"
        continue
    fi
    # Domain validation that accepts subdomains
    if [[ ! $DOMAIN =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]]; then
        log_message "Error: Invalid domain format. Please enter a valid domain name" "$RED"
        continue
    fi

    # Check if it's a subdomain
    if [[ $DOMAIN =~ ^[^.]+\.[^.]+\.[^.]+$ ]]; then
        IS_SUBDOMAIN=true
    else
        IS_SUBDOMAIN=false
    fi
    break
done

# Generate random secret keys
APP_KEY=$(generate_hex)
SECRET_KEY=$(generate_hex)

log_message "" "$NC"
log_message "Optional: Configure environment variables now, or edit .env manually after installation." "$YELLOW"

# Optional: Database URL
read -p "Enter your database URL (leave blank to use default SQLite): " DB_URL

# Admin credentials
read -p "Enter admin username (default: admin): " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-admin}

read -s -p "Enter admin password (leave blank to auto-generate): " ADMIN_PASS
echo ""
if [ -z "$ADMIN_PASS" ]; then
    ADMIN_PASS=$(generate_hex | cut -c1-16)
    log_message "Auto-generated admin password: $ADMIN_PASS  (save this now!)" "$YELLOW"
fi

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
DEPLOY_NAME="${DOMAIN/./-}"
BASE_PATH="/var/python/tradeboard/$DEPLOY_NAME"
APP_PATH="$BASE_PATH/tradeboard"
VENV_PATH="$BASE_PATH/venv"
SOCKET_PATH="$BASE_PATH"
SOCKET_FILE="$SOCKET_PATH/tradeboard.sock"
SERVICE_NAME="tradeboard-$DEPLOY_NAME"

# Set Nginx configuration paths based on OS
case "$OS_TYPE" in
    ubuntu | debian | raspbian)
        NGINX_AVAILABLE="/etc/nginx/sites-available"
        NGINX_ENABLED="/etc/nginx/sites-enabled"
        NGINX_CONFIG_MODE="sites"
        ;;
    centos | fedora | rhel | amzn | arch)
        NGINX_AVAILABLE="/etc/nginx/conf.d"
        NGINX_ENABLED="/etc/nginx/conf.d"
        NGINX_CONFIG_MODE="confd"
        sudo mkdir -p "$NGINX_AVAILABLE"
        ;;
esac
NGINX_CONFIG_FILE="$NGINX_AVAILABLE/$DOMAIN.conf"

log_message "\nStarting Tradeboard installation for $DEPLOY_NAME..." "$YELLOW"

# ---------------------------------------------------------------------------
# System packages update
# ---------------------------------------------------------------------------
log_message "\nUpdating system packages..." "$BLUE"
case "$OS_TYPE" in
    ubuntu | debian | raspbian)
        wait_for_dpkg_lock
        sudo apt-get update && sudo apt-get upgrade -y
        check_status "Failed to update system packages"
        ;;
    centos | fedora | rhel | amzn)
        if ! command -v dnf >/dev/null 2>&1; then
            sudo yum update -y
        else
            sudo dnf update -y
        fi
        check_status "Failed to update system packages"
        ;;
    arch)
        sudo pacman -Syu --noconfirm
        check_status "Failed to update system packages"
        ;;
esac

# ---------------------------------------------------------------------------
# Install required packages
# ---------------------------------------------------------------------------
log_message "\nInstalling required packages..." "$BLUE"
case "$OS_TYPE" in
    ubuntu | debian | raspbian)
        wait_for_dpkg_lock
        sudo apt-get install -y python3 python3-venv python3-pip nginx git \
            software-properties-common curl build-essential libssl-dev libffi-dev
        # Try to install python3-full if available (Ubuntu 23.04+)
        sudo apt-get install -y python3-full 2>/dev/null || log_message "python3-full not available, skipping" "$YELLOW"
        # Try to install snapd, but don't fail if unavailable
        sudo apt-get install -y snapd 2>/dev/null || log_message "snapd not available, will use pip for uv installation" "$YELLOW"
        check_status "Failed to install required packages"
        ;;
    centos | fedora | rhel | amzn)
        if ! command -v dnf >/dev/null 2>&1; then
            sudo yum install -y python3 python3-pip nginx git epel-release \
                curl openssl-devel libffi-devel gcc
            sudo yum install -y policycoreutils-python-utils 2>/dev/null || log_message "SELinux tools already installed or unavailable" "$YELLOW"
            sudo yum install -y snapd 2>/dev/null || log_message "snapd not available, will use pip for uv installation" "$YELLOW"
        else
            sudo dnf install -y epel-release 2>/dev/null || log_message "EPEL already installed or not available" "$YELLOW"
            sudo dnf install -y python3 python3-pip nginx git \
                curl openssl-devel libffi-devel gcc
            sudo dnf install -y policycoreutils-python-utils 2>/dev/null || log_message "SELinux tools already installed or unavailable" "$YELLOW"
            sudo dnf install -y snapd 2>/dev/null || log_message "snapd not available, will use pip for uv installation" "$YELLOW"
        fi
        check_status "Failed to install required packages"
        # Enable and start snapd if it was successfully installed
        if command -v snap >/dev/null 2>&1; then
            sudo systemctl enable --now snapd.socket
        fi
        ;;
    arch)
        sudo pacman -Sy --noconfirm --needed python python-pip nginx git \
            curl openssl libffi gcc base-devel
        sudo pacman -Sy --noconfirm --needed snapd 2>/dev/null || log_message "snapd not available, will use pip for uv installation" "$YELLOW"
        check_status "Failed to install required packages"
        if command -v snap >/dev/null 2>&1; then
            sudo systemctl enable --now snapd.socket
        fi
        ;;
esac

# ---------------------------------------------------------------------------
# Install uv package installer
# ---------------------------------------------------------------------------
log_message "\nInstalling uv package installer..." "$BLUE"
case "$OS_TYPE" in
    ubuntu | debian | raspbian)
        # Use snap for Ubuntu/Debian (native support)
        if command -v snap >/dev/null 2>&1; then
            if [ ! -e /snap ] && [ -d /var/lib/snapd/snap ]; then
                sudo ln -s /var/lib/snapd/snap /snap
            fi
            sleep 2
            if sudo snap install astral-uv --classic 2>/dev/null; then
                log_message "uv installed via snap" "$GREEN"
            else
                log_message "Snap installation failed, using pip fallback" "$YELLOW"
                sudo $PYTHON_CMD -m pip install uv
            fi
        else
            sudo $PYTHON_CMD -m pip install uv
        fi
        check_status "Failed to install uv"
        ;;
    centos | fedora | rhel | amzn)
        log_message "Installing uv via pip for better compatibility..." "$BLUE"
        sudo $PYTHON_CMD -m pip install uv
        check_status "Failed to install uv"
        ;;
    arch)
        log_message "Installing uv for Arch Linux..." "$BLUE"
        if sudo pacman -Sy --noconfirm --needed python-uv 2>/dev/null; then
            log_message "uv installed via pacman" "$GREEN"
        else
            log_message "uv not available in pacman, using pip..." "$YELLOW"
            sudo $PYTHON_CMD -m pip install --break-system-packages uv
            check_status "Failed to install uv"
        fi
        ;;
esac

# ---------------------------------------------------------------------------
# Install Certbot
# ---------------------------------------------------------------------------
log_message "\nInstalling Certbot..." "$BLUE"
case "$OS_TYPE" in
    ubuntu | debian | raspbian)
        wait_for_dpkg_lock
        sudo apt-get install -y certbot python3-certbot-nginx
        check_status "Failed to install Certbot"
        ;;
    centos | fedora | rhel | amzn)
        CERTBOT_INSTALLED=false
        if ! command -v dnf >/dev/null 2>&1; then
            if sudo yum install -y certbot python3-certbot-nginx >/dev/null 2>&1; then
                CERTBOT_INSTALLED=true
                log_message "Certbot installed via yum" "$GREEN"
            fi
        else
            if sudo dnf install -y certbot python3-certbot-nginx >/dev/null 2>&1; then
                CERTBOT_INSTALLED=true
                log_message "Certbot installed via dnf" "$GREEN"
            fi
        fi

        # If package manager installation failed, try snap
        if [ "$CERTBOT_INSTALLED" = false ]; then
            log_message "Certbot not available in repositories, trying snap installation..." "$YELLOW"
            if command -v snap >/dev/null 2>&1; then
                if sudo snap install --classic certbot >/dev/null 2>&1; then
                    CERTBOT_INSTALLED=true
                    sudo ln -sf /snap/bin/certbot /usr/bin/certbot 2>/dev/null || true
                    log_message "Certbot installed via snap" "$GREEN"
                fi
            fi
        fi

        # If still not installed, use pip as last resort
        if [ "$CERTBOT_INSTALLED" = false ]; then
            log_message "Installing Certbot via pip..." "$YELLOW"
            sudo $PYTHON_CMD -m pip install certbot certbot-nginx >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                CERTBOT_INSTALLED=true
                log_message "Certbot installed via pip" "$GREEN"
            fi
        fi

        if [ "$CERTBOT_INSTALLED" = false ]; then
            log_message "Failed to install Certbot via all methods" "$RED"
            exit 1
        fi
        ;;
    arch)
        sudo pacman -Sy --noconfirm --needed certbot certbot-nginx
        check_status "Failed to install Certbot"
        ;;
esac

# Verify certbot is accessible
if ! command -v certbot >/dev/null 2>&1; then
    log_message "Error: Certbot installation failed - command not found" "$RED"
    exit 1
fi
log_message "Certbot installed successfully" "$GREEN"

# ---------------------------------------------------------------------------
# Clone repository
# ---------------------------------------------------------------------------
handle_existing "$BASE_PATH" "installation directory" "Tradeboard directory for $DEPLOY_NAME"

log_message "\nCreating base directory..." "$BLUE"
sudo mkdir -p $BASE_PATH
check_status "Failed to create base directory"

log_message "\nCloning Tradeboard repository..." "$BLUE"
sudo git clone https://github.com/wesoftcorp/tradeboard.git $APP_PATH
check_status "Failed to clone Tradeboard repository"

# ---------------------------------------------------------------------------
# Python virtual environment
# ---------------------------------------------------------------------------
log_message "\nSetting up Python virtual environment with uv..." "$BLUE"
if [ -d "$VENV_PATH" ]; then
    log_message "Warning: Virtual environment already exists, removing..." "$YELLOW"
    sudo rm -rf "$VENV_PATH"
fi
sudo mkdir -p $(dirname $VENV_PATH)

# Detect how uv is installed and set the appropriate command
if command -v uv >/dev/null 2>&1; then
    UV_CMD="uv"
    log_message "Using standalone uv command" "$GREEN"
elif $PYTHON_CMD -m uv --version >/dev/null 2>&1; then
    UV_CMD="$PYTHON_CMD -m uv"
    log_message "Using uv as Python module" "$GREEN"
else
    log_message "Error: uv is not available" "$RED"
    exit 1
fi

# Create virtual environment using uv
sudo $UV_CMD venv $VENV_PATH
check_status "Failed to create virtual environment with uv"

# ---------------------------------------------------------------------------
# Install Python dependencies
# ---------------------------------------------------------------------------
log_message "\nInstalling Python dependencies with uv..." "$BLUE"
ACTIVATE_CMD="source $VENV_PATH/bin/activate"

# Detect which requirements file to use
if [ -f "$APP_PATH/requirements-nginx.txt" ]; then
    REQ_FILE="$APP_PATH/requirements-nginx.txt"
    log_message "Using requirements-nginx.txt" "$GREEN"
elif [ -f "$APP_PATH/requirements.txt" ]; then
    REQ_FILE="$APP_PATH/requirements.txt"
    log_message "Using requirements.txt" "$GREEN"
else
    log_message "No requirements file found. Skipping pip install -- install manually after deployment." "$YELLOW"
    REQ_FILE=""
fi

if [ -n "$REQ_FILE" ]; then
    sudo $UV_CMD pip install --python $VENV_PATH/bin/python -r $REQ_FILE
    check_status "Failed to install Python dependencies"
fi

# Ensure gunicorn is installed
log_message "\nVerifying gunicorn installation..." "$BLUE"
if ! sudo bash -c "$ACTIVATE_CMD && pip show gunicorn" >/dev/null 2>&1; then
    log_message "Installing gunicorn..." "$YELLOW"
    sudo $UV_CMD pip install --python $VENV_PATH/bin/python "gunicorn>=25.0,<26"
    check_status "Failed to install gunicorn"
else
    log_message "gunicorn already installed" "$GREEN"
fi

# Ensure eventlet is installed
log_message "\nVerifying eventlet installation..." "$BLUE"
if ! sudo bash -c "$ACTIVATE_CMD && pip show eventlet" >/dev/null 2>&1; then
    log_message "Installing eventlet..." "$YELLOW"
    sudo $UV_CMD pip install --python $VENV_PATH/bin/python eventlet
    check_status "Failed to install eventlet"
else
    log_message "eventlet already installed" "$GREEN"
fi

# ---------------------------------------------------------------------------
# Configure .env file
# ---------------------------------------------------------------------------
log_message "\nConfiguring environment file..." "$BLUE"
handle_existing "$APP_PATH/.env" "environment file" ".env file"

# Use .sample.env as template if it exists, otherwise try .env.example
if [ -f "$APP_PATH/.sample.env" ]; then
    sudo cp $APP_PATH/.sample.env $APP_PATH/.env
    log_message "Copied .sample.env as base for .env" "$GREEN"
elif [ -f "$APP_PATH/.env.example" ]; then
    sudo cp $APP_PATH/.env.example $APP_PATH/.env
    log_message "Copied .env.example as base for .env" "$GREEN"
else
    log_message "No sample .env found -- creating a minimal .env from scratch" "$YELLOW"
    sudo tee $APP_PATH/.env > /dev/null << ENVEOF
# Tradeboard Environment Configuration
# Generated by install-tradeboard.sh on $(date)

# Application Settings
APP_NAME=Tradeboard
SECRET_KEY=${APP_KEY}
APP_KEY=${SECRET_KEY}

# Host Configuration
HOST=0.0.0.0
PORT=5000
HOST_SERVER=https://${DOMAIN}

# Database
DATABASE_URL=${DB_URL:-sqlite:///tradeboard.db}

# Admin Credentials
ADMIN_USERNAME=${ADMIN_USER}
ADMIN_PASSWORD=${ADMIN_PASS}

# Proxy Settings (nginx reverse proxy)
TRUST_PROXY_HEADERS=TRUE

# WebSocket Configuration
WEBSOCKET_URL=wss://${DOMAIN}/ws
WEBSOCKET_HOST=127.0.0.1
WEBSOCKET_PORT=8765
ENVEOF
    check_status "Failed to create .env file"
fi

# Patch known placeholder patterns in the .env file
sudo sed -i "s|http://127.0.0.1:5000|https://$DOMAIN|g"                    $APP_PATH/.env
sudo sed -i "s|HOST_SERVER\s*=\s*'.*'|HOST_SERVER = 'https://$DOMAIN'|g"   $APP_PATH/.env
sudo sed -i "s|TRUST_PROXY_HEADERS\s*=\s*'FALSE'|TRUST_PROXY_HEADERS = 'TRUE'|g" $APP_PATH/.env
sudo sed -i "s|WEBSOCKET_URL='.*'|WEBSOCKET_URL='wss://$DOMAIN/ws'|g"      $APP_PATH/.env
[ -n "$DB_URL" ] && sudo sed -i "s|DATABASE_URL=.*|DATABASE_URL=$DB_URL|g"  $APP_PATH/.env
sudo sed -i "s|ADMIN_USERNAME=.*|ADMIN_USERNAME=$ADMIN_USER|g"              $APP_PATH/.env
sudo sed -i "s|ADMIN_PASSWORD=.*|ADMIN_PASSWORD=$ADMIN_PASS|g"              $APP_PATH/.env

log_message "Environment file configured at $APP_PATH/.env" "$GREEN"

# ---------------------------------------------------------------------------
# Check and handle existing Nginx configuration
# ---------------------------------------------------------------------------
handle_existing "$NGINX_CONFIG_FILE" "Nginx configuration" "Nginx config file"

# Fix Arch Linux nginx.conf to include conf.d directory
if [ "$OS_TYPE" = "arch" ]; then
    if ! grep -q "include.*conf.d/\*.conf" /etc/nginx/nginx.conf; then
        log_message "Adding conf.d include to nginx.conf for Arch Linux..." "$YELLOW"
        sudo sed -i '/http {/a\    include /etc/nginx/conf.d/*.conf;' /etc/nginx/nginx.conf
        log_message "conf.d include added to nginx.conf" "$GREEN"
    fi
fi

# ---------------------------------------------------------------------------
# Configure initial Nginx for SSL certificate obtention (HTTP only)
# ---------------------------------------------------------------------------
log_message "\nConfiguring initial Nginx setup for Certbot..." "$BLUE"
sudo tee $NGINX_CONFIG_FILE > /dev/null << EOL
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    root /var/www/html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

# Enable site and remove default configuration
if [ "$NGINX_CONFIG_MODE" = "sites" ]; then
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo ln -sf $NGINX_CONFIG_FILE /etc/nginx/sites-enabled/
    check_status "Failed to enable Nginx site"
else
    sudo rm -f /etc/nginx/conf.d/default.conf
fi

# Test and start/reload Nginx
log_message "\nTesting and starting Nginx..." "$BLUE"
sudo nginx -t
check_status "Failed to validate Nginx configuration"

if sudo systemctl is-active --quiet nginx; then
    sudo systemctl reload nginx
    log_message "Nginx reloaded successfully" "$GREEN"
else
    sudo systemctl enable nginx
    sudo systemctl start nginx
    log_message "Nginx started successfully" "$GREEN"
fi
check_status "Failed to start/reload Nginx"

# ---------------------------------------------------------------------------
# Configure Firewall
# ---------------------------------------------------------------------------
log_message "\nConfiguring firewall rules..." "$BLUE"
case "$OS_TYPE" in
    ubuntu | debian | raspbian)
        wait_for_dpkg_lock
        sudo apt-get install -y ufw
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw allow ssh
        sudo ufw allow 'Nginx Full'
        sudo ufw --force enable
        check_status "Failed to configure UFW firewall"
        ;;
    centos | fedora | rhel | amzn)
        if ! command -v firewall-cmd >/dev/null 2>&1; then
            if ! command -v dnf >/dev/null 2>&1; then
                sudo yum install -y firewalld
            else
                sudo dnf install -y firewalld
            fi
        fi
        sudo systemctl enable firewalld
        sudo systemctl start firewalld
        sudo firewall-cmd --permanent --add-service=ssh
        sudo firewall-cmd --permanent --add-service=http
        sudo firewall-cmd --permanent --add-service=https
        sudo firewall-cmd --reload
        check_status "Failed to configure firewalld"
        ;;
    arch)
        if ! command -v ufw >/dev/null 2>&1; then
            sudo pacman -Sy --noconfirm --needed ufw
        fi
        sudo systemctl enable ufw
        sudo systemctl start ufw
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw allow ssh
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw --force enable
        check_status "Failed to configure UFW firewall"
        ;;
esac

# ---------------------------------------------------------------------------
# Obtain SSL certificate via Certbot
# ---------------------------------------------------------------------------
log_message "\nObtaining SSL certificate..." "$BLUE"
if [ "$IS_SUBDOMAIN" = true ]; then
    sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@${DOMAIN#*.}
else
    sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN
fi

# Check if certificate was obtained
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    log_message "Failed to obtain SSL certificate" "$RED"
    exit 1
else
    log_message "SSL certificate obtained successfully" "$GREEN"
fi

# ---------------------------------------------------------------------------
# Configure final Nginx setup with SSL and Unix socket proxy
# ---------------------------------------------------------------------------
log_message "\nConfiguring final Nginx setup (HTTPS + Unix socket)..." "$BLUE"

# Remove old config files to ensure clean write
sudo rm -f $NGINX_CONFIG_FILE
sudo rm -f ${NGINX_AVAILABLE}/${DOMAIN}
if [ "$NGINX_CONFIG_MODE" = "sites" ]; then
    sudo rm -f /etc/nginx/sites-enabled/${DOMAIN}
    sudo rm -f /etc/nginx/sites-enabled/${DOMAIN}.conf
fi

# Write the new full HTTPS configuration
sudo tee $NGINX_CONFIG_FILE > /dev/null << EOL
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    # Redirect WebSocket paths to HTTPS
    location = /ws {
        return 301 https://\$host\$request_uri;
    }
    location /ws/ {
        return 301 https://\$host\$request_uri;
    }

    # Redirect all other HTTP requests to HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name $DOMAIN;

    ssl_certificate     /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers EECDH+AESGCM:EDH+AESGCM;
    ssl_ecdh_curve secp384r1;
    ssl_session_timeout 10m;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=63072000" always;

    # WebSocket proxy -- without trailing slash
    location = /ws {
        proxy_pass http://127.0.0.1:8765;
        proxy_http_version 1.1;

        # Extended timeouts for long-running WebSocket connections (up to 24 hours)
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;

        # Disable proxy buffering for real-time data
        proxy_buffering off;

        # WebSocket upgrade headers
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # Standard proxy headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
    }

    # WebSocket proxy -- with trailing slash
    location /ws/ {
        proxy_pass http://127.0.0.1:8765/;
        proxy_http_version 1.1;

        # Extended timeouts for long-running WebSocket connections (up to 24 hours)
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;

        # Disable proxy buffering for real-time data
        proxy_buffering off;

        # WebSocket upgrade headers
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # Standard proxy headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
    }

    # Socket.IO (Flask-SocketIO real-time events)
    location /socket.io/ {
        proxy_pass http://unix:$SOCKET_FILE;
        proxy_http_version 1.1;

        # Extended timeouts for long-lived Socket.IO sessions
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;

        # Disable proxy buffering for real-time events
        proxy_buffering off;

        # WebSocket upgrade headers
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # Standard proxy headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
    }

    # Main Tradeboard application (Gunicorn Unix domain socket)
    location / {
        proxy_pass http://unix:$SOCKET_FILE;
        proxy_http_version 1.1;

        # Timeouts
        proxy_read_timeout 300s;
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;

        # Buffer settings
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;

        # WebSocket upgrade headers (for any inline WS on main path)
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # Standard proxy headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
    }
}
EOL

# Re-enable site symlink if using sites-available/sites-enabled mode
if [ "$NGINX_CONFIG_MODE" = "sites" ]; then
    sudo ln -sf $NGINX_CONFIG_FILE /etc/nginx/sites-enabled/
    log_message "Nginx site symlink recreated" "$GREEN"
fi

# Validate final Nginx configuration
sudo nginx -t
check_status "Failed to validate final Nginx configuration"

# ---------------------------------------------------------------------------
# Create systemd service
# ---------------------------------------------------------------------------
handle_existing "/etc/systemd/system/$SERVICE_NAME.service" "systemd service" "Tradeboard systemd service"

log_message "\nCreating systemd service ($SERVICE_NAME)..." "$BLUE"
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOL
[Unit]
Description=Tradeboard Gunicorn Daemon ($DEPLOY_NAME)
After=network.target

[Service]
User=$WEB_USER
Group=$WEB_GROUP
WorkingDirectory=$APP_PATH
Environment="HOME=$APP_PATH/tmp"
Environment="TMPDIR=$APP_PATH/tmp"
Environment="MPLCONFIGDIR=$APP_PATH/tmp/matplotlib"
ExecStart=/bin/bash -c 'source $VENV_PATH/bin/activate && $VENV_PATH/bin/gunicorn \
    --worker-class eventlet \
    -w 1 \
    --bind unix:$SOCKET_FILE \
    --timeout 300 \
    --log-level info \
    app:app'
Restart=always
RestartSec=5
TimeoutSec=300

[Install]
WantedBy=multi-user.target
EOL
check_status "Failed to create systemd service file"

# ---------------------------------------------------------------------------
# Set permissions
# ---------------------------------------------------------------------------
log_message "\nSetting file permissions..." "$BLUE"

# Create required subdirectories
sudo mkdir -p $APP_PATH/db
sudo mkdir -p $APP_PATH/tmp/matplotlib
sudo mkdir -p $APP_PATH/log
sudo mkdir -p $APP_PATH/keys

# Set ownership
sudo chown -R $WEB_USER:$WEB_GROUP $BASE_PATH
check_status "Failed to set ownership on $BASE_PATH"

# Set directory permissions
sudo chmod -R 755 $BASE_PATH

# Restrict sensitive directories/files
sudo chmod 700 $APP_PATH/keys           # keys directory -- owner only
sudo chmod 600 $APP_PATH/.env           # .env file -- owner read/write only

# Remove stale socket file if it exists
[ -S "$SOCKET_FILE" ] && sudo rm -f $SOCKET_FILE

# Ensure socket directory is accessible by nginx
sudo chmod 755 $SOCKET_PATH

log_message "\nVerifying permissions..." "$BLUE"
ls -la $APP_PATH
check_status "Failed to verify permissions"

# ---------------------------------------------------------------------------
# Enable and start services
# ---------------------------------------------------------------------------
log_message "\nEnabling and starting services..." "$BLUE"
sudo systemctl daemon-reload
check_status "Failed to reload systemd daemon"

sudo systemctl enable $SERVICE_NAME
check_status "Failed to enable $SERVICE_NAME service"

sudo systemctl start $SERVICE_NAME
check_status "Failed to start $SERVICE_NAME service"

sudo systemctl restart nginx
check_status "Failed to restart Nginx"

log_message "Services started successfully" "$GREEN"

# ---------------------------------------------------------------------------
# SELinux configuration (RHEL-based systems only)
# ---------------------------------------------------------------------------
if [[ "$OS_TYPE" =~ ^(centos|fedora|rhel|amzn)$ ]]; then
    if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" != "Disabled" ]; then
        log_message "\nConfiguring SELinux permissions for Tradeboard..." "$BLUE"

        # Set correct SELinux context for the application directory
        sudo semanage fcontext -a -t httpd_sys_rw_content_t "$BASE_PATH(/.*)?" 2>/dev/null || true
        sudo restorecon -Rv $BASE_PATH >/dev/null 2>&1

        # Allow nginx to connect to the upstream gunicorn process
        sudo setsebool -P httpd_can_network_connect on 2>/dev/null || true

        # Check for and resolve any AVC denials from nginx/gunicorn socket communication
        if sudo ausearch -m avc -ts recent 2>/dev/null | grep -q "httpd_t.*initrc_t.*unix_stream_socket"; then
            log_message "Creating custom SELinux policy for nginx-gunicorn socket..." "$YELLOW"
            sudo ausearch -m avc -ts recent 2>/dev/null | sudo audit2allow -M httpd_tradeboard 2>/dev/null || true
            if [ -f httpd_tradeboard.pp ]; then
                sudo semodule -i httpd_tradeboard.pp 2>/dev/null || true
                sudo rm -f httpd_tradeboard.pp httpd_tradeboard.te 2>/dev/null || true
                log_message "SELinux custom policy installed" "$GREEN"
                sudo systemctl restart nginx
            fi
        fi

        log_message "SELinux configuration completed" "$GREEN"
    fi
fi

# ---------------------------------------------------------------------------
# Verify service status
# ---------------------------------------------------------------------------
log_message "\nVerifying service status..." "$BLUE"

sleep 3  # Wait a moment for services to fully start

if sudo systemctl is-active --quiet $SERVICE_NAME; then
    log_message "Tradeboard service is running" "$GREEN"
else
    log_message "Warning: Tradeboard service may not be running correctly" "$YELLOW"
    log_message "Check logs with: sudo journalctl -u $SERVICE_NAME -n 50" "$YELLOW"
fi

if sudo systemctl is-active --quiet nginx; then
    log_message "Nginx is running" "$GREEN"
else
    log_message "Warning: Nginx may not be running correctly" "$YELLOW"
    log_message "Check logs with: sudo journalctl -u nginx -n 50" "$YELLOW"
fi

# ===========================================================================
# INSTALLATION SUMMARY
# ===========================================================================
log_message "\n========================================" "$GREEN"
log_message "   Tradeboard Installation Complete!    " "$GREEN"
log_message "========================================" "$GREEN"

log_message "\nInstallation Summary:" "$YELLOW"
log_message "  Operating System   : $OS_TYPE $OS_VERSION"          "$BLUE"
log_message "  Deployment Name    : $DEPLOY_NAME"                   "$BLUE"
log_message "  Application URL    : https://$DOMAIN"                "$BLUE"
log_message "  Install Directory  : $APP_PATH"                      "$BLUE"
log_message "  Virtual Env        : $VENV_PATH"                     "$BLUE"
log_message "  Environment File   : $APP_PATH/.env"                 "$BLUE"
log_message "  Unix Socket        : $SOCKET_FILE"                   "$BLUE"
log_message "  systemd Service    : $SERVICE_NAME"                  "$BLUE"
log_message "  Nginx Config       : $NGINX_CONFIG_FILE"             "$BLUE"
log_message "  SSL Certificate    : /etc/letsencrypt/live/$DOMAIN"  "$BLUE"
log_message "  Admin Username     : $ADMIN_USER"                    "$BLUE"
log_message "  Installation Log   : $LOG_FILE"                      "$BLUE"

log_message "\nNext Steps:" "$YELLOW"
log_message "  1. Visit https://$DOMAIN to access Tradeboard"                        "$GREEN"
log_message "  2. Log in with admin user: $ADMIN_USER"                               "$GREEN"
log_message "  3. Review and update $APP_PATH/.env for any remaining config"         "$GREEN"
log_message "  4. Monitor startup logs: sudo journalctl -u $SERVICE_NAME -f"         "$GREEN"
log_message "  5. SSL auto-renewal is handled by Certbot (runs via cron/systemd)"    "$GREEN"

log_message "\nUseful Commands:" "$YELLOW"
log_message "  Restart Tradeboard  : sudo systemctl restart $SERVICE_NAME"   "$BLUE"
log_message "  Stop Tradeboard     : sudo systemctl stop $SERVICE_NAME"      "$BLUE"
log_message "  Start Tradeboard    : sudo systemctl start $SERVICE_NAME"     "$BLUE"
log_message "  Service Status      : sudo systemctl status $SERVICE_NAME"    "$BLUE"
log_message "  View App Logs       : sudo journalctl -u $SERVICE_NAME -f"    "$BLUE"
log_message "  View Nginx Logs     : sudo tail -f /var/log/nginx/error.log"  "$BLUE"
log_message "  Reload Nginx        : sudo systemctl reload nginx"            "$BLUE"
log_message "  Test SSL Renewal    : sudo certbot renew --dry-run"           "$BLUE"
log_message "  Edit Config         : sudo nano $APP_PATH/.env"               "$BLUE"
log_message "  View Install Log    : cat $LOG_FILE"                          "$BLUE"

log_message "\n----------------------------------------" "$GREEN"
log_message "  Thank you for using Tradeboard!       " "$GREEN"
log_message "  SoftCorp Group -- wesoftcorp          " "$GREEN"
log_message "----------------------------------------" "$GREEN"
