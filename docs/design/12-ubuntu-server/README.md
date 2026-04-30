# 12 - Ubuntu Server Installation

## Overview

This guide covers deploying Tradeboard on an Ubuntu server (20.04/22.04 LTS) with Nginx reverse proxy, systemd services, and SSL configuration for production use.

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        Ubuntu Server Architecture                            │
└──────────────────────────────────────────────────────────────────────────────┘

                         Internet
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Nginx (Reverse Proxy)                               │
│                          Port 80/443                                         │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  - SSL termination (Let's Encrypt)                                   │   │
│  │  - HTTP → HTTPS redirect                                             │   │
│  │  - WebSocket upgrade support                                         │   │
│  │  - Static file serving                                               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                    │                       │
                    ▼                       ▼
┌─────────────────────────────────────────────────────┐
│           Tradeboard (Gunicorn + WebSocket)           │
│                                                     │
│  Flask App ─────────── localhost:5000               │
│  WebSocket Thread ──── localhost:8765               │
│                                                     │
│  systemd: Tradeboard                                  │
└─────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          File System                                         │
│                                                                              │
│  /opt/Tradeboard/                                                             │
│  ├── .venv/              # Virtual environment                              │
│  ├── db/                 # SQLite databases                                 │
│  ├── log/                # Application logs                                 │
│  ├── strategies/         # User strategies                                  │
│  ├── .env                # Configuration                                    │
│  └── app.py              # Main application                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y python3.12 python3.12-venv python3-pip \
                    nginx certbot python3-certbot-nginx \
                    git curl build-essential

# Install Node.js (for frontend build)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

## Installation Steps

### 1. Clone Repository

```bash
# Create application directory
sudo mkdir -p /opt/Tradeboard
sudo chown $USER:$USER /opt/Tradeboard

# Clone repository
cd /opt/Tradeboard
git clone https://github.com/marketcalls/Tradeboard.git .
```

### 2. Setup Python Environment

```bash
# Install uv package manager
pip install uv

# Create virtual environment and install dependencies
uv venv .venv
source .venv/bin/activate
uv sync

# Install production dependencies
uv pip install gunicorn eventlet==0.35.2
```

### 3. Configure Environment

```bash
# Copy sample environment file
cp .sample.env .env

# Generate secure keys
python -c "import secrets; print(secrets.token_hex(32))"
# Copy output to APP_KEY and API_KEY_PEPPER in .env

# Edit configuration
nano .env
```

### 4. Build Frontend

```bash
cd frontend
npm install
npm run build
cd ..
```

### 5. Create Systemd Service

**Note:** The WebSocket server runs as a thread inside the main app (port 8765), so only ONE systemd service is needed.

```bash
sudo nano /etc/systemd/system/Tradeboard.service
```

```ini
[Unit]
Description=Tradeboard Trading Platform
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/Tradeboard
Environment="PATH=/opt/Tradeboard/.venv/bin"
ExecStart=/opt/Tradeboard/.venv/bin/gunicorn \
    --worker-class eventlet \
    -w 1 \
    --bind 127.0.0.1:5000 \
    --timeout 120 \
    app:app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Important:** Use `-w 1` (single worker) for WebSocket compatibility.

### 6. Set Permissions

```bash
# Set ownership
sudo chown -R www-data:www-data /opt/Tradeboard

# Set permissions
sudo chmod -R 755 /opt/Tradeboard
sudo chmod 700 /opt/Tradeboard/keys
sudo chmod 600 /opt/Tradeboard/.env
```

### 7. Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/Tradeboard
```

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    # SSL certificates (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;

    # Main application
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support for Socket.IO
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
    }

    # WebSocket proxy
    location /ws {
        proxy_pass http://127.0.0.1:8765;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }

    # Static files
    location /static {
        alias /opt/Tradeboard/static;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

### 8. Enable Service

```bash
# Enable Nginx site
sudo ln -s /etc/nginx/sites-available/Tradeboard /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Enable and start Tradeboard service
sudo systemctl daemon-reload
sudo systemctl enable Tradeboard
sudo systemctl start Tradeboard
```

### 9. Setup SSL (Let's Encrypt)

```bash
sudo certbot --nginx -d your-domain.com
```

## Service Management

```bash
# Check status
sudo systemctl status Tradeboard

# View logs
sudo journalctl -u Tradeboard -f

# Restart service
sudo systemctl restart Tradeboard

# Stop service
sudo systemctl stop Tradeboard
```

## Firewall Configuration

```bash
# Enable firewall
sudo ufw enable

# Allow required ports
sudo ufw allow 22/tcp     # SSH
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS

# Check status
sudo ufw status
```

## Update Procedure

```bash
# Stop service
sudo systemctl stop Tradeboard

# Pull updates
cd /opt/Tradeboard
git pull origin main

# Update dependencies
source .venv/bin/activate
uv sync

# Rebuild frontend
cd frontend
npm install
npm run build
cd ..

# Start service
sudo systemctl start Tradeboard
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| 502 Bad Gateway | Check if Tradeboard service is running: `systemctl status Tradeboard` |
| WebSocket fails | Check Nginx /ws proxy config and service logs |
| Permission denied | Verify www-data ownership: `chown -R www-data:www-data /opt/Tradeboard` |
| SSL error | Renew certificates: `sudo certbot renew` |

## Key Files Reference

| File | Purpose |
|------|---------|
| `/etc/systemd/system/Tradeboard.service` | Main service (includes WebSocket) |
| `/etc/nginx/sites-available/Tradeboard` | Nginx config |
| `/opt/Tradeboard/.env` | Application config |
| `/var/log/nginx/` | Nginx logs |

**Note:** There is no separate `Tradeboard-ws.service`. The WebSocket server runs as a thread inside the main Flask application on port 8765.
