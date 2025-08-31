#!/bin/bash

set -e

APP_DIR="/opt/flask-app"
VENV_DIR="$APP_DIR/venv"
LOG_DIR="/var/log/flask-app"
PID_FILE="$APP_DIR/gunicorn.pid"
PORT="8000"

mkdir -p $APP_DIR
mkdir -p $LOG_DIR
chown -R azureuser:azureuser $APP_DIR
chown -R azureuser:azureuser $LOG_DIR

cd $APP_DIR

if [ ! -f "requirements.txt" ]; then
    echo "Error: requirements.txt missing"
    ls -la
    exit 1
fi

if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv $VENV_DIR
fi

source $VENV_DIR/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat $PID_FILE)
    if kill -0 $OLD_PID 2>/dev/null; then
        kill $OLD_PID
        sleep 2
    fi
    rm -f $PID_FILE
fi

pkill -f gunicorn || true
sleep 2

nohup $VENV_DIR/bin/gunicorn \
    --bind 0.0.0.0:$PORT \
    --workers 2 \
    --timeout 60 \
    --access-logfile $LOG_DIR/access.log \
    --error-logfile $LOG_DIR/error.log \
    wsgi:app > $LOG_DIR/app.log 2>&1 &

GUNICORN_PID=$!
echo $GUNICORN_PID > $PID_FILE
echo "App started: $GUNICORN_PID"

sleep 3

if kill -0 $GUNICORN_PID 2>/dev/null; then
    echo "App running"
else
    echo "App failed to start"
    tail -10 $LOG_DIR/error.log 2>/dev/null || echo "No errors"
    exit 1
fi

if curl -s http://localhost:$PORT/api/status >/dev/null; then
    echo "App test passed"
else
    sleep 2
    if curl -s http://localhost:$PORT/api/status >/dev/null; then
        echo "App test passed after wait"
    else
        echo "App test failed"
        exit 1
    fi
fi

echo ""
echo "Deployment done"
echo "URL: http://$(curl -s ifconfig.me):$PORT"
echo "Logs: $LOG_DIR/"
echo "PID: $GUNICORN_PID"
echo ""

sleep 2
echo "Deployment complete"