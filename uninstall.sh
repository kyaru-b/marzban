#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     Hysteria 2 + Marzban + Nginx Uninstaller                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script as root (sudo)${NC}"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${YELLOW}This will stop and remove all containers and data.${NC}"
read -p "Are you sure you want to continue? (y/N): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${GREEN}Uninstallation cancelled.${NC}"
    exit 0
fi

echo -e "${YELLOW}Stopping containers...${NC}"
docker-compose down -v

echo -e "${YELLOW}Do you want to remove all data including certificates? (y/N): ${NC}"
read -p "" REMOVE_DATA

if [ "$REMOVE_DATA" == "y" ] || [ "$REMOVE_DATA" == "Y" ]; then
    echo -e "${YELLOW}Removing data...${NC}"
    rm -rf marzban-data
    rm -rf certbot
    rm -rf hysteria2/config/config.yaml
    rm -rf nginx/conf.d/default.conf
    rm -f .env
    rm -f credentials.txt
    echo -e "${GREEN}All data removed!${NC}"
fi

echo -e "${GREEN}Uninstallation complete!${NC}"
