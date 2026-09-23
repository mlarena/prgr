#!/bin/bash
set -euo pipefail

# Скрипт установки Docker
echo "========================================="
echo "Начало установки Docker"
echo "========================================="

# Обновление пакетов (если не обновляли ранее)
apt update

# Добавление GPG-ключа Docker
# Удаляем старый ключ перед импортом, чтобы повторный запуск не падал
rm -f /usr/share/keyrings/docker-archive-keyring.gpg
curl -fsSL --max-time 30 --retry 2 https://download.docker.com/linux/debian/gpg | gpg --dearmor --yes -o /usr/share/keyrings/docker-archive-keyring.gpg

# Добавление репозитория Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Включение автозапуска Docker
systemctl enable docker
systemctl start docker

# Добавление реального пользователя (не root) в группу docker
# При запуске через sudo берем имя исходного пользователя из SUDO_USER
TARGET_USER="${SUDO_USER:-$USER}"
if [ -n "${TARGET_USER}" ] && [ "${TARGET_USER}" != "root" ]; then
    usermod -aG docker "${TARGET_USER}"
    echo "Пользователь ${TARGET_USER} добавлен в группу docker"
    echo "(выйдите из сессии и войдите заново для применения прав)"
fi

echo "========================================="
echo "Установка Docker завершена"
echo "========================================="

# Проверка установки
docker --version
docker ps

echo "Docker успешно установлен!"