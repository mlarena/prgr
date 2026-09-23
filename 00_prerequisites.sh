#!/bin/bash
set -euo pipefail

# Подключаем общие функции
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Автоматическое определение IP адреса
SERVER_IP=$(detect_server_ip)
echo "========================================="
echo "Предварительная установка утилит"
echo "IP адрес сервера: ${SERVER_IP}"
echo "========================================="

# Обновление пакетов
apt update && apt upgrade -y

# Установка необходимых утилит
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    wget \
    lsb-release \
    net-tools \
    jq \
    git \
    vim \
    iproute2 \
    sudo \
    nload \
    iftop

echo "========================================="
echo "Предварительная установка завершена"
echo "========================================="