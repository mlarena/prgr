#!/bin/bash

# Скрипт установки Docker
# IP адрес сервера (замените на ваш IP)
SERVER_IP="192.168.192.141"

echo "========================================="
echo "Начало установки Docker"
echo "========================================="

# Обновление пакетов
apt update && apt upgrade -y

# Установка зависимостей
apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

# Добавление GPG-ключа Docker
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Добавление репозитория Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Включение автозапуска Docker
systemctl enable docker
systemctl start docker

# Добавление текущего пользователя в группу docker (опционально)
usermod -aG docker $USER

echo "========================================="
echo "Установка Docker завершена"
echo "========================================="

# Проверка установки
docker --version
docker ps

echo "Docker успешно установлен!"