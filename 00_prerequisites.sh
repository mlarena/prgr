#!/bin/bash

# Получение директории скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Подключение функций
if [ -f "${SCRIPT_DIR}/functions.sh" ]; then
    source "${SCRIPT_DIR}/functions.sh"
else
    # Если functions.sh нет, используем простой метод определения IP
    get_server_ip() {
        ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1
    }
fi

# Автоматическое определение IP адреса
SERVER_IP=$(get_server_ip)

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
    software-properties-common \
    wget \
    lsb-release \
    net-tools \
    jq \
    git \
    vim \
    iproute2

# Установка lsb-release если не установлен
if ! command -v lsb_release &> /dev/null; then
    apt install -y lsb-release
fi

echo "========================================="
echo "Предварительная установка завершена"
echo "========================================="