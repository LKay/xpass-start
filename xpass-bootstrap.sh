#!/bin/bash

# Bootstrap for persistent DS-Lite tunnel service on UDM

SERVICE_NAME="xpass-tunnel"
SERVICE_FILE="/mnt/data/xpass-tunnel/xpass-tunnel.service"
SCRIPT_FILE="/mnt/data/xpass-tunnel/xpass-tunnel.sh"

# Create symlinks if missing
[ ! -L /usr/local/bin/$SERVICE_NAME.sh ] && ln -s $SCRIPT_FILE /usr/local/bin/$SERVICE_NAME.sh
[ ! -L /etc/systemd/system/$SERVICE_NAME.service ] && ln -s $SERVICE_FILE /etc/systemd/system/$SERVICE_NAME.service

# Reload systemd daemon to recognize new service file
systemctl daemon-reexec
systemctl daemon-reload

# Enable the service to start on boot (idempotent)
systemctl enable $SERVICE_NAME.service
systemctl start $SERVICE_NAME.service
