#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              H-UI (Hysteria 2) Installer                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Запустите скрипт от root: sudo ./install.sh${NC}"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

DOMAIN="hystori.neoproxy.online"
EMAIL="brav.bot@mail.ru"

# Установка Docker
install_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Установка Docker...${NC}"
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
        echo -e "${GREEN}Docker установлен!${NC}"
    else
        echo -e "${GREEN}Docker уже установлен${NC}"
    fi
}

# Создание директорий
create_directories() {
    echo -e "${YELLOW}Создание директорий...${NC}"
    mkdir -p certbot/www
    mkdir -p certbot/conf
    mkdir -p h-ui-data
    echo -e "${GREEN}Директории созданы!${NC}"
}

# Получение SSL
obtain_ssl() {
    if [ -d "certbot/conf/live/$DOMAIN" ]; then
        echo -e "${GREEN}SSL сертификат уже существует${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Получение SSL сертификата для $DOMAIN...${NC}"
    
    docker run --rm -p 80:80 \
        -v $(pwd)/certbot/conf:/etc/letsencrypt \
        -v $(pwd)/certbot/www:/var/www/certbot \
        certbot/certbot certonly \
        --standalone \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        -d $DOMAIN
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SSL сертификат получен!${NC}"
    else
        echo -e "${RED}Ошибка получения SSL!${NC}"
        echo -e "${YELLOW}Проверьте что домен $DOMAIN указывает на IP этого сервера${NC}"
        exit 1
    fi
}

# Запуск
start_services() {
    echo -e "${YELLOW}Запуск H-UI...${NC}"
    docker compose down 2>/dev/null
    docker compose up -d
    echo -e "${GREEN}H-UI запущен!${NC}"
}

# Информация
show_info() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                 УСТАНОВКА ЗАВЕРШЕНА!${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}H-UI Panel (Hysteria 2):${NC}"
    echo -e "  URL:    https://$DOMAIN:8081"
    echo -e "  Логин:  admin"
    echo -e "  Пароль: admin"
    echo ""
    echo -e "${YELLOW}ВАЖНО: Смените пароль после первого входа!${NC}"
    echo ""
    echo -e "${BLUE}Команды:${NC}"
    echo -e "  docker compose ps        # Статус"
    echo -e "  docker compose logs -f   # Логи"
    echo -e "  docker compose restart   # Перезапуск"
    echo ""
}

# Main
main() {
    install_docker
    create_directories
    obtain_ssl
    start_services
    
    echo -e "${YELLOW}Ожидание запуска H-UI (15 сек)...${NC}"
    sleep 15
    
    docker compose ps
    show_info
}

main
