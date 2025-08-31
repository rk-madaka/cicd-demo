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

# Run with Gunicorn
venv/bin/gunicorn --bind 0.0.0.0:8000 wsgi:app

# Press Ctrl+C to stop
echo "Deployment completed successfully!"
echo "Application should be available at http://$(curl -s ifconfig.me):8000"