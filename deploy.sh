#!/bin/bash

# Exit on error
set -e

echo "Starting deployment process..."

# Variables
APP_DIR="/opt/flask-app"
VENV_DIR="$APP_DIR/venv"

# Create directory if it doesn't exist
sudo mkdir -p $APP_DIR
sudo chown -R azureuser:azureuser $APP_DIR

# Check if we're in the right directory
cd $APP_DIR

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv $VENV_DIR
fi

# Activate virtual environment and install dependencies
echo "Installing dependencies..."
source $VENV_DIR/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Create systemd service file
echo "Configuring systemd service..."
sudo tee /etc/systemd/system/flask-app.service > /dev/null <<EOF
[Unit]
Description=Gunicorn instance to serve Flask app
After=network.target

[Service]
User=azureuser
Group=www-data
WorkingDirectory=$APP_DIR
Environment="PATH=$VENV_DIR/bin"
ExecStart=$VENV_DIR/bin/gunicorn --workers 3 --bind unix:$APP_DIR/flask-app.sock -m 007 wsgi:app

[Install]
WantedBy=multi-user.target
EOF

# Create nginx configuration
echo "Configuring nginx..."
sudo tee /etc/nginx/sites-available/flask-app > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        include proxy_params;
        proxy_pass http://unix:$APP_DIR/flask-app.sock;
    }
}
EOF

# Enable site if not already enabled
if [ ! -f "/etc/nginx/sites-enabled/flask-app" ]; then
    sudo ln -s /etc/nginx/sites-available/flask-app /etc/nginx/sites-enabled/
fi

# Test nginx configuration
sudo nginx -t

# Restart services
echo "Restarting services..."
sudo systemctl daemon-reload
sudo systemctl restart flask-app
sudo systemctl enable flask-app
sudo systemctl restart nginx

echo "Deployment completed successfully!"
echo "Application should be available at http://$(curl -s ifconfig.me)"