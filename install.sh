#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     Hysteria 2 + Marzban + Nginx Installer                   ║"
echo "║     With SSL Certificate Support                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script as root (sudo)${NC}"
    exit 1
fi

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 24
}

# Install Docker if not installed
install_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Installing Docker...${NC}"
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
        echo -e "${GREEN}Docker installed successfully!${NC}"
    else
        echo -e "${GREEN}Docker is already installed.${NC}"
    fi
}

# Install Docker Compose if not installed
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${YELLOW}Installing Docker Compose...${NC}"
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        echo -e "${GREEN}Docker Compose installed successfully!${NC}"
    else
        echo -e "${GREEN}Docker Compose is already installed.${NC}"
    fi
}

# Get domain from user
get_domain() {
    echo -e "${YELLOW}"
    read -p "Enter your domain name (e.g., example.com): " DOMAIN
    echo -e "${NC}"
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}Domain cannot be empty!${NC}"
        exit 1
    fi
    
    # Validate domain format
    if ! echo "$DOMAIN" | grep -qP '(?=^.{1,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)'; then
        echo -e "${YELLOW}Warning: Domain format might be incorrect. Continuing anyway...${NC}"
    fi
    
    echo -e "${GREEN}Domain set to: $DOMAIN${NC}"
}

# Get email for SSL certificate
get_email() {
    echo -e "${YELLOW}"
    read -p "Enter your email for SSL certificate (Let's Encrypt): " EMAIL
    echo -e "${NC}"
    
    if [ -z "$EMAIL" ]; then
        echo -e "${RED}Email cannot be empty!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Email set to: $EMAIL${NC}"
}

# Get admin credentials
get_admin_credentials() {
    echo -e "${YELLOW}"
    read -p "Enter Marzban admin username [default: admin]: " ADMIN_USER
    ADMIN_USER=${ADMIN_USER:-admin}
    
    read -s -p "Enter Marzban admin password [press Enter for random]: " ADMIN_PASS
    echo
    echo -e "${NC}"
    
    if [ -z "$ADMIN_PASS" ]; then
        ADMIN_PASS=$(generate_password)
        echo -e "${GREEN}Generated admin password: $ADMIN_PASS${NC}"
    fi
}

# Get Hysteria 2 password
get_hysteria_password() {
    echo -e "${YELLOW}"
    read -s -p "Enter Hysteria 2 authentication password [press Enter for random]: " HYSTERIA_PASS
    echo
    echo -e "${NC}"
    
    if [ -z "$HYSTERIA_PASS" ]; then
        HYSTERIA_PASS=$(generate_password)
        echo -e "${GREEN}Generated Hysteria 2 password: $HYSTERIA_PASS${NC}"
    fi
}

# Create directories
create_directories() {
    echo -e "${YELLOW}Creating directories...${NC}"
    mkdir -p nginx/conf.d
    mkdir -p nginx/ssl
    mkdir -p certbot/www
    mkdir -p certbot/conf
    mkdir -p marzban-data
    mkdir -p xray-config
    mkdir -p hysteria2/config
    echo -e "${GREEN}Directories created!${NC}"
}

# Configure files with domain
configure_files() {
    echo -e "${YELLOW}Configuring files...${NC}"
    
    # Configure Nginx
    cp nginx/conf.d/default.conf.template nginx/conf.d/default.conf
    sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" nginx/conf.d/default.conf
    
    # Configure Hysteria 2
    cp hysteria2/config/config.yaml.template hysteria2/config/config.yaml
    sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" hysteria2/config/config.yaml
    sed -i "s/AUTH_PASSWORD_PLACEHOLDER/$HYSTERIA_PASS/g" hysteria2/config/config.yaml
    
    # Configure .env
    cp .env.template .env
    sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" .env
    sed -i "s/ADMIN_PASSWORD_PLACEHOLDER/$ADMIN_PASS/g" .env
    sed -i "s/admin/$ADMIN_USER/g" .env
    
    echo -e "${GREEN}Files configured!${NC}"
}

# Obtain SSL certificate
obtain_ssl_certificate() {
    echo -e "${YELLOW}Obtaining SSL certificate...${NC}"
    
    # Start nginx with initial config for ACME challenge
    docker-compose up -d nginx
    sleep 5
    
    # Get certificate
    docker-compose run --rm certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        -d "$DOMAIN"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SSL certificate obtained successfully!${NC}"
        
        # Replace initial nginx config with full config
        rm -f nginx/conf.d/initial.conf
        
        # Restart nginx with SSL config
        docker-compose restart nginx
    else
        echo -e "${RED}Failed to obtain SSL certificate!${NC}"
        echo -e "${YELLOW}Make sure your domain points to this server's IP address.${NC}"
        exit 1
    fi
}

# Start services
start_services() {
    echo -e "${YELLOW}Starting all services...${NC}"
    docker-compose up -d
    echo -e "${GREEN}All services started!${NC}"
}

# Show summary
show_summary() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    INSTALLATION COMPLETE                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${GREEN}Marzban Panel:${NC}"
    echo -e "  URL: https://$DOMAIN"
    echo -e "  Username: $ADMIN_USER"
    echo -e "  Password: $ADMIN_PASS"
    echo ""
    
    echo -e "${GREEN}Hysteria 2:${NC}"
    echo -e "  Server: $DOMAIN:443"
    echo -e "  Password: $HYSTERIA_PASS"
    echo ""
    
    echo -e "${GREEN}Hysteria 2 Client Config:${NC}"
    echo -e "${YELLOW}"
    cat << EOF
server: $DOMAIN:443
auth: $HYSTERIA_PASS
bandwidth:
  up: 100 mbps
  down: 100 mbps
tls:
  sni: $DOMAIN
  insecure: false
socks5:
  listen: 127.0.0.1:1080
http:
  listen: 127.0.0.1:8080
EOF
    echo -e "${NC}"
    
    echo -e "${BLUE}Useful commands:${NC}"
    echo "  docker-compose logs -f        # View logs"
    echo "  docker-compose restart        # Restart services"
    echo "  docker-compose down           # Stop services"
    echo "  docker-compose up -d          # Start services"
    echo ""
    
    # Save credentials to file
    cat > credentials.txt << EOF
=== Marzban + Hysteria 2 Credentials ===
Generated on: $(date)

Domain: $DOMAIN

Marzban Panel:
  URL: https://$DOMAIN
  Username: $ADMIN_USER
  Password: $ADMIN_PASS

Hysteria 2:
  Server: $DOMAIN:443
  Password: $HYSTERIA_PASS

Keep this file safe and delete after saving credentials!
EOF
    
    echo -e "${YELLOW}Credentials saved to: credentials.txt${NC}"
    echo -e "${RED}Please save these credentials and delete the file for security!${NC}"
}

# Main installation flow
main() {
    install_docker
    install_docker_compose
    get_domain
    get_email
    get_admin_credentials
    get_hysteria_password
    create_directories
    configure_files
    obtain_ssl_certificate
    start_services
    show_summary
}

# Run main function
main
