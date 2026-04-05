#!/bin/bash

# Минималистичный скрипт настройки зеркал Docker

# Запись конфигурации
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://mirror.gcr.io",
    "https://dockerhub1.beget.com"
  ]
}
EOF

# Перезапуск Docker
systemctl restart docker

# Вывод подтверждения
echo "Docker mirrors configured successfully!"
echo "Current mirrors:"
docker info | grep -A 3 "Registry Mirrors"