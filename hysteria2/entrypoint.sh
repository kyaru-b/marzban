#!/bin/bash

# Wait for certificates to be available
while [ ! -f /etc/hysteria/config.yaml ]; do
    echo "Waiting for Hysteria config..."
    sleep 5
done

echo "Starting Hysteria 2..."
exec /usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
