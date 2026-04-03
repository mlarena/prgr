#!/bin/bash

# Автоматическое определение IP адреса
SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
echo "========================================="
echo "Предварительная установка утилит"
echo "IP адрес сервера: ${SERVER_IP}"
echo "========================================="

# Сохраняем IP в файл для использования другими скриптами
echo "${SERVER_IP}" > /tmp/server_ip.txt

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
    sudo
# Установка lsb-release если не установлен
if ! command -v lsb_release &> /dev/null; then
    apt install -y lsb-release
fi

echo "========================================="
echo "Предварительная установка завершена"
echo "========================================="